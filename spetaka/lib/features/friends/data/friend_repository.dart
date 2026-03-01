import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service.dart';

/// Repository for Friend CRUD operations.
///
/// **Encryption boundary:** This class is the ONLY place where sensitive
/// fields are encrypted on write and decrypted on read.
///
/// Sensitive fields (encrypted at repository layer, per Story 1.7–1.8 / NFR6):
///   - [Friend.name]        → `friends.name` column   (Story 1.8)
///   - [Friend.mobile]      → `friends.mobile` column (Story 1.8)
///   - [Friend.notes]       → `friends.notes` column  (Story 1.7)
///   - [Friend.concernNote] → `friends.concern_note` column (Story 1.7)
///
/// Plaintext fields (never encrypted; required for query/feature logic):
///   id, tags, careScore, isConcernActive, createdAt, updatedAt, isDemo
///
/// Drift DAOs are encryption-agnostic; they receive and return raw stored
/// string values (ciphertext for sensitive fields, plaintext for others).
///
/// **Error propagation:** `EncryptionService` may throw:
///   - [EncryptionNotInitializedAppError] — no active key (not initialised)
///   - [DecryptionFailedAppError]         — GCM auth tag mismatch
///   - [CiphertextFormatAppError]         — ciphertext format is corrupted
/// Repositories do NOT swallow these; callers handle them for UI messaging.
class FriendRepository {
  FriendRepository({required this.db, required this.encryptionService});

  final AppDatabase db;
  final EncryptionService encryptionService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Encrypts sensitive fields and inserts a new [friend] record into SQLite.
  ///
  /// Story 4.5: if the new friend is not a demo entity, all demo-seeded friends
  /// (i.e. Sophie) are automatically removed after the insert so the user sees
  /// only their real contacts going forward.
  Future<void> insert(Friend friend) async {
    await db.friendDao.insertFriend(_toEncryptedCompanion(friend));
    if (!friend.isDemo) {
      await db.friendDao.deleteDemoFriends();
    }
  }

  /// Reads a friend by [id]; decrypts sensitive fields before returning.
  ///
  /// Returns null if no friend with [id] exists.
  Future<Friend?> findById(String id) async {
    final row = await db.friendDao.findById(id);
    return row != null ? _decryptRow(row) : null;
  }

  /// Returns all friends, with sensitive fields decrypted and sorted
  /// case-insensitively by name (AC-3: post-decryption sort).
  Future<List<Friend>> findAll() async {
    final rows = await db.friendDao.selectAll();
    return _sortByNameCaseInsensitiveStable(rows.map(_decryptRow).toList());
  }

  /// Watches all friends via a reactive stream; each emission is decrypted
  /// and sorted case-insensitively by name (AC-3: post-decryption sort).
  Stream<List<Friend>> watchAll() => db.friendDao.watchAll().map(
        (rows) => _sortByNameCaseInsensitiveStable(
          rows.map(_decryptRow).toList(),
        ),
      );

  /// Watches a single friend by [id] via a reactive stream; decrypts on each emission.
  ///
  /// Emits `null` when no friend with [id] exists.
  Stream<Friend?> watchById(String id) =>
      db.friendDao.watchById(id).map((row) => row != null ? _decryptRow(row) : null);

  /// Encrypts sensitive fields and replaces the existing [friend] record.
  Future<void> update(Friend friend) async {
    await db.friendDao.updateFriend(_toEncryptedCompanion(friend));
  }

  /// Deletes the friend record identified by [id] and cascades the deletion
  /// to all related acquittements (Story 2.8 AC2).
  ///
  /// Returns the number of friend rows deleted (0 or 1).
  Future<int> delete(String id) async {
    // Cascade: remove contact history first (FK not enforced at schema level).
    await db.acquittementDao.deleteByFriendId(id);
    return db.friendDao.deleteFriend(id);
  }

  /// Removes all demo-seeded friends (Story 4.5 — explicit removal action).
  ///
  /// Called automatically by [insert] when a real friend is added.
  /// May also be called explicitly from the UI or onboarding flow.
  Future<void> removeDemoFriends() => db.friendDao.deleteDemoFriends();

  /// Sets the concern flag for [id] with an optional [note] (Story 2.9 AC1).
  ///
  /// Trims the note; stores null if the trimmed value is empty.
  /// No-op if the friend does not exist.
  Future<void> setConcern(String id, {String? note}) async {
    final friend = await findById(id);
    if (friend == null) return;
    final trimmed = note?.trim();
    await update(
      friend.copyWith(
        isConcernActive: true,
        concernNote: Value(trimmed?.isEmpty == true ? null : trimmed),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Clears the concern flag for [id] and removes the concern note (Story 2.9 AC3).
  ///
  /// No-op if the friend does not exist.
  Future<void> clearConcern(String id) async {
    final friend = await findById(id);
    if (friend == null) return;
    await update(
      friend.copyWith(
        isConcernActive: false,
        concernNote: const Value(null),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers — encryption boundary
  // ---------------------------------------------------------------------------

  /// Returns a new list sorted by decrypted name, case-insensitively.
  ///
  /// The ordering is stable: ties (same lowercased name) preserve the original
  /// input order.
  List<Friend> _sortByNameCaseInsensitiveStable(List<Friend> friends) {
    final indexed = <(int, Friend)>[];
    for (var i = 0; i < friends.length; i++) {
      indexed.add((i, friends[i]));
    }

    indexed.sort((a, b) {
      final aKey = a.$2.name.toLowerCase();
      final bKey = b.$2.name.toLowerCase();
      final cmp = aKey.compareTo(bKey);
      if (cmp != 0) return cmp;
      return a.$1.compareTo(b.$1);
    });

    return [for (final entry in indexed) entry.$2];
  }

  // ---------------------------------------------------------------------------
  // Legacy-plaintext detection constants (AC-9)
  // ---------------------------------------------------------------------------

  /// Minimum raw bytes for a valid AES-GCM ciphertext payload:
  /// iv (12) + tag (16) + at least 1 byte of ciphertext = 29 bytes.
  static const int _minCiphertextRawBytes = 29;

  /// Minimum base64url-encoded length for a 29-byte payload (with padding).
  static const int _minCiphertextBase64Len = 40;

  /// Returns `true` when [value] looks like a ciphertext envelope produced
  /// by [EncryptionService]: a base64url string whose decoded length ≥ 29.
  ///
  /// Used for legacy-plaintext compatibility (AC-9): rows written before
  /// Story 1.8 have plaintext `name`/`mobile`; calling `decrypt()` on them
  /// would throw [CiphertextFormatAppError], bricking the Friends list.
  bool _looksLikeCiphertext(String value) {
    if (value.length < _minCiphertextBase64Len) return false;
    try {
      final decoded = base64Url.decode(value);
      return decoded.length >= _minCiphertextRawBytes;
    } on FormatException {
      return false;
    }
  }

  /// Decrypts [value] if it looks like a ciphertext payload; otherwise
  /// returns [value] unchanged (legacy-plaintext passthrough, AC-9).
  String _decryptOrPlaintext(String value) {
    if (!_looksLikeCiphertext(value)) return value;
    return encryptionService.decrypt(value);
  }

  /// Converts a plaintext [friend] to a [FriendsCompanion] with ALL sensitive
  /// fields encrypted via [encryptionService].
  ///
  /// Non-sensitive fields (careScore, isConcernActive, tags, id, createdAt,
  /// updatedAt, isDemo) are passed through unchanged — they must remain
  /// queryable at the DB level.
  FriendsCompanion _toEncryptedCompanion(Friend friend) {
    final encName = encryptionService.encrypt(friend.name);
    final encMobile = encryptionService.encrypt(friend.mobile);
    final encNotes =
        friend.notes != null ? encryptionService.encrypt(friend.notes!) : null;
    final encConcernNote = friend.concernNote != null
        ? encryptionService.encrypt(friend.concernNote!)
        : null;

    return FriendsCompanion(
      id: Value(friend.id),
      name: Value(encName),
      mobile: Value(encMobile),
      tags: Value(friend.tags),
      notes: Value(encNotes),
      careScore: Value(friend.careScore),
      isConcernActive: Value(friend.isConcernActive),
      concernNote: Value(encConcernNote),
      isDemo: Value(friend.isDemo),
      createdAt: Value(friend.createdAt),
      updatedAt: Value(friend.updatedAt),
    );
  }

  /// Returns a copy of [row] with ALL sensitive fields replaced by their
  /// decrypted plaintext counterparts.
  ///
  /// `name` and `mobile` use [_decryptOrPlaintext] for backward compatibility
  /// with legacy rows that still contain plaintext values (AC-9).
  Friend _decryptRow(Friend row) {
    final decName = _decryptOrPlaintext(row.name);
    final decMobile = _decryptOrPlaintext(row.mobile);
    final decNotes =
        row.notes != null ? encryptionService.decrypt(row.notes!) : null;
    final decConcernNote = row.concernNote != null
        ? encryptionService.decrypt(row.concernNote!)
        : null;

    return row.copyWith(
      name: decName,
      mobile: decMobile,
      notes: Value<String?>(decNotes),
      concernNote: Value<String?>(decConcernNote),
    );
  }
}
