import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../core/errors/app_error.dart';
import '../../friends/data/friend_repository.dart';
import '../domain/backup_payload.dart';

/// Repository responsible for encrypted local backup export and import.
///
/// ## File format (V1)
/// ```
/// Offset  Bytes   Content
///  0       4      Magic: 'SPBK' (0x53 0x50 0x42 0x4B)
///  4       1      Version: 0x01
///  5      16      PBKDF2 salt (random, per-backup — NOT the per-install prefs salt)
/// 21      var     UTF-8 bytes of the base64url ciphertext string produced by
///                 [EncryptionService.encryptWithKeyBytes]
/// ```
///
/// ## Security invariants
/// - Passphrase is **never** written to disk, `SharedPreferences`, or logs.
/// - The derived key is zeroed and discarded immediately after the file op.
/// - The per-backup salt guarantees restorability on any Android device (NFR14).
///
/// ## Transactional restore
/// The import restore is wrapped in a single Drift transaction: any failure
/// rolls back the entire operation and the existing local data is untouched.
class BackupRepository {
  BackupRepository({
    required AppDatabase db,
    required EncryptionService encryptionService,
    required FriendRepository friendRepository,
  })  : _db = db,
        _encryptionService = encryptionService,
        _friendRepository = friendRepository;

  final AppDatabase _db;
  final EncryptionService _encryptionService;
  final FriendRepository _friendRepository;

  // --------------------------------------------------------------------------
  // File-format constants
  // --------------------------------------------------------------------------

  static const List<int> _magic = [0x53, 0x50, 0x42, 0x4B]; // 'SPBK'
  static const int _version = 0x01;
  static const int _saltLengthBytes = 16;
  static const int _headerSize = 4 + 1 + _saltLengthBytes; // 21 bytes

  static const String _prefsDensityModeKey = 'density_mode';

  static bool _mediaStoreInitialized = false;

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Serialises all non-demo user data, encrypts it with a per-backup key
  /// derived from [passphrase], and writes the result to the device's external
  /// storage directory.
  ///
  /// Returns the absolute path of the saved `.enc` file.
  ///
  /// Throws [EncryptionNotInitializedAppError] if the per-install
  /// [EncryptionService] is not yet initialised (app lock screen not passed).
  Future<String> exportEncrypted(String passphrase) async {
    final bytes = await exportToBytes(passphrase);

    final fileName = 'spetaka_backup_${_dateTag()}.enc';

    // Android: save to Downloads via MediaStore (scoped storage compliant).
    if (Platform.isAndroid) {
      final saved = await _exportToAndroidDownloads(bytes: bytes, fileName: fileName);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    }

    // Fallback (non-Android / safety): write to app-accessible storage.
    final filePath = await _resolveFallbackExportPath(fileName);
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Produces the raw backup file bytes without performing any file I/O.
  ///
  /// This method is `@visibleForTesting` — production callers should use
  /// [exportEncrypted]. Tests can call this directly to avoid platform-channel
  /// dependencies of `path_provider`.
  // ignore: avoid_returning_from_callbacks
  Future<Uint8List> exportToBytes(String passphrase) async {
    // ── 1. Collect data ──────────────────────────────────────────────────────
    final friends = await _friendRepository.findAll(); // decrypted
    final realFriends = friends.where((f) => !f.isDemo).toList();
    final friendIds = realFriends.map((f) => f.id).toSet();

    final rawAcqs = await _db.acquittementDao.selectAllRaw();
    final decryptedAcqs = rawAcqs
        .where((a) => friendIds.contains(a.friendId))
        .map(_decryptAcquittement)
        .toList();

    final events = (await _db.eventDao.selectAll())
        .where((e) => friendIds.contains(e.friendId))
        .toList();
    final eventTypes = await _db.eventTypeDao.getAll();

    // Lightweight settings snapshot (SharedPreferences).
    final prefs = await SharedPreferences.getInstance();
    final settings = BackupSettings(
      densityMode: prefs.getString(_prefsDensityModeKey),
    );

    // ── 2. Serialize ─────────────────────────────────────────────────────────
    final payload = BackupPayload(
      version: BackupPayload.currentVersion,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      settings: settings,
      friends: realFriends,
      events: events,
      acquittements: decryptedAcqs,
      eventTypes: eventTypes,
    );
    final jsonString = jsonEncode(payload.toJson());

    // ── 3. Derive per-backup key ──────────────────────────────────────────────
    final salt = EncryptionService.generateRandomBytes(_saltLengthBytes);
    Uint8List? keyBytes;
    try {
      final passBytes = Uint8List.fromList(utf8.encode(passphrase));
      keyBytes = EncryptionService.deriveKeyForBackup(passBytes, salt);
      passBytes.fillRange(0, passBytes.length, 0);
    } catch (_) {
      rethrow;
    }

    // ── 4. Encrypt payload ───────────────────────────────────────────────────
    final String ciphertextB64;
    try {
      ciphertextB64 = EncryptionService.encryptWithKeyBytes(keyBytes, jsonString);
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }

    // ── 5. Build binary file: header + ciphertext UTF-8 bytes ────────────────
    final ciphertextBytes = utf8.encode(ciphertextB64);
    final fileBytes = Uint8List(_headerSize + ciphertextBytes.length);
    var offset = 0;
    for (final b in _magic) {
      fileBytes[offset++] = b;
    }
    fileBytes[offset++] = _version;
    for (var i = 0; i < _saltLengthBytes; i++) {
      fileBytes[offset++] = salt[i];
    }
    fileBytes.setRange(offset, offset + ciphertextBytes.length, ciphertextBytes);

    return fileBytes;
  }

  /// Reads [filePath], decrypts the payload with [passphrase], and performs a
  /// replace-all restore inside a single Drift transaction.
  ///
  /// After a successful restore the caller should navigate to the daily view so
  /// Riverpod stream providers re-emit with the new data (Story 6.5 AC3).
  ///
  /// Throws:
  /// - [BackupFileFormatAppError]  — invalid SPBK header or unsupported version.
  /// - [CiphertextFormatAppError]  — payload is not valid base64url / format.
  /// - [DecryptionFailedAppError]  — wrong passphrase (GCM auth-tag mismatch).
  /// - [FormatException]           — JSON structure is invalid.
  Future<void> importEncrypted(String filePath, String passphrase) async {
    // ── 1. Read file ──────────────────────────────────────────────────────────
    final fileBytes = await File(filePath).readAsBytes();
    if (fileBytes.length < _headerSize + 1) {
      throw const CiphertextFormatAppError();
    }

    // ── 2. Validate header ────────────────────────────────────────────────────
    for (var i = 0; i < _magic.length; i++) {
      if (fileBytes[i] != _magic[i]) throw const CiphertextFormatAppError();
    }
    final fileVersion = fileBytes[4];
    if (fileVersion != _version) throw const CiphertextFormatAppError();

    // ── 3. Extract salt ───────────────────────────────────────────────────────
    final salt = fileBytes.sublist(5, 5 + _saltLengthBytes);

    // ── 4. Ciphertext (UTF-8 base64url string) ────────────────────────────────
    final ciphertextB64 =
        utf8.decode(fileBytes.sublist(_headerSize));

    // ── 5. Derive key + decrypt ───────────────────────────────────────────────
    final passBytes = Uint8List.fromList(utf8.encode(passphrase));
    Uint8List? keyBytes;
    try {
      keyBytes = EncryptionService.deriveKeyForBackup(passBytes, salt);
    } finally {
      passBytes.fillRange(0, passBytes.length, 0);
    }

    final String jsonString;
    try {
      jsonString = EncryptionService.decryptWithKeyBytes(keyBytes, ciphertextB64);
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }

    // ── 6. Parse payload ──────────────────────────────────────────────────────
    final payload = BackupPayload.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );

    // ── 7. Replace-all restore inside a single Drift transaction ─────────────
    await _db.transaction(() async {
      // Clear all covered tables.
      await _db.acquittementDao.deleteAll();
      await _db.eventDao.deleteAll();
      await _db.eventTypeDao.deleteAll();
      await _db.friendDao.deleteAll();

      // Re-insert with per-install encryption for sensitive fields.
      for (final friend in payload.friends) {
        await _db.friendDao.insertFriend(_encryptFriend(friend));
      }
      for (final acq in payload.acquittements) {
        await _db.acquittementDao
            .insertAcquittement(_encryptAcquittement(acq));
      }
      for (final event in payload.events) {
        await _db.eventDao.insertEvent(event.toCompanion(true));
      }
      for (final et in payload.eventTypes) {
        await _db.eventTypeDao.insertEventType(et.toCompanion(true));
      }
    });

    // Restore lightweight settings (best-effort, must not break atomic DB restore).
    await _restoreSettingsBestEffort(payload.settings);
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Formats the current UTC time as `YYYYMMDD_HHmmss` for the file name.
  String _dateTag() {
    final now = DateTime.now().toUtc();
    String p(int n, [int width = 2]) => n.toString().padLeft(width, '0');
    return '${p(now.year, 4)}${p(now.month)}${p(now.day)}'
        '_${p(now.hour)}${p(now.minute)}${p(now.second)}';
  }

  /// Returns an absolute path to write the export file.
  ///
  /// Preference order:
  ///   1. External storage directory (app-specific, no permissions on Android 10+)
  ///   2. Application documents directory (internal storage fallback)
  Future<String> resolveExportPath(String fileName) =>
      _resolveFallbackExportPath(fileName);

  Future<String> _resolveFallbackExportPath(String fileName) async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return '${extDir.path}/$fileName';
      }
    } catch (_) {
      // getExternalStorageDirectory is Android-only; fall through on others.
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/$fileName';
  }

  Future<String?> _exportToAndroidDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      if (!_mediaStoreInitialized) {
        await MediaStore.ensureInitialized();
        // Save under: /storage/emulated/0/Download/Spetaka/
        MediaStore.appFolder = 'Spetaka';
        _mediaStoreInitialized = true;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      await File(tempPath).writeAsBytes(bytes, flush: true);

      final ms = MediaStore();
      final info = await ms.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      // The plugin returns a content:// URI. For user-facing messaging we
      // return a stable, human-readable location.
      if (info != null) {
        return 'Downloads/Spetaka/$fileName';
      }
    } catch (_) {
      // Fall back to app-accessible path.
    }
    return null;
  }

  Future<void> _restoreSettingsBestEffort(BackupSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final density = settings.densityMode;
      if (density != null && density.isNotEmpty) {
        await prefs.setString(_prefsDensityModeKey, density);
      }
    } catch (_) {
      // Best-effort only; must never compromise DB atomic restore.
    }
  }

  // --------------------------------------------------------------------------
  // Encryption helpers (mirror FriendRepository / AcquittementRepository)
  // --------------------------------------------------------------------------

  /// Returns [row] with sensitive fields decrypted using the per-install key.
  Acquittement _decryptAcquittement(Acquittement row) {
    final decNote =
        row.note != null ? _encryptionService.decrypt(row.note!) : null;
    return row.copyWith(note: Value<String?>(decNote));
  }

  /// Returns a [FriendsCompanion] with sensitive fields encrypted.
  FriendsCompanion _encryptFriend(Friend friend) {
    return FriendsCompanion(
      id: Value(friend.id),
      name: Value(_encryptionService.encrypt(friend.name)),
      mobile: Value(_encryptionService.encrypt(friend.mobile)),
      tags: Value(friend.tags),
      notes: Value(
          friend.notes != null
              ? _encryptionService.encrypt(friend.notes!)
              : null,
      ),
      careScore: Value(friend.careScore),
      isConcernActive: Value(friend.isConcernActive),
      concernNote: Value(
          friend.concernNote != null
              ? _encryptionService.encrypt(friend.concernNote!)
              : null,
      ),
      isDemo: Value(friend.isDemo),
      createdAt: Value(friend.createdAt),
      updatedAt: Value(friend.updatedAt),
    );
  }

  /// Returns an [AcquittementsCompanion] with note encrypted.
  AcquittementsCompanion _encryptAcquittement(Acquittement acq) {
    return AcquittementsCompanion(
      id: Value(acq.id),
      friendId: Value(acq.friendId),
      type: Value(acq.type),
      note: Value(acq.note != null ? _encryptionService.encrypt(acq.note!) : null),
      createdAt: Value(acq.createdAt),
    );
  }
}
