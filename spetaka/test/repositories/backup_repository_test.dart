// test/repositories/backup_repository_test.dart
//
// Tests Story 6.5 — Encrypted Local Backup Export & Import
//
// Coverage:
//   (a) Export → import roundtrip: all entities restored with same IDs + values
//   (b) Ciphertext-at-rest: exported bytes ≠ original plaintext JSON
//   (c) Wrong passphrase: DecryptionFailedAppError thrown, no partial write
//   (d) Corrupt file (bad magic): BackupFileFormatAppError thrown, no partial write
//   (e) Demo friends excluded from backup payload
//   (f) All-or-nothing restore: partial DB pre-existing data replaced completely
//   (g) All existing tests remain green (flutter test)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/backup/data/backup_repository.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _testPass = 'backup-test-passphrase-6.5';
const _wrongPass = 'wrong-passphrase-!@#';
const _uuid = Uuid();

const _densityPrefsKey = 'density_mode';

AppDatabase _buildDb() => AppDatabase(NativeDatabase.memory());

Future<EncryptionService> _buildService(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
  final service = EncryptionService(lifecycleService: lifecycle);
  await service.initialize(_testPass);
  return service;
}

/// Creates a fully-wired [BackupRepository] with a fresh in-memory DB +
/// EncryptionService initialised with [_testPass].
Future<
    ({
      BackupRepository repo,
      AppDatabase db,
      FriendRepository friendRepo,
      EncryptionService enc
    })> _buildFixture() async {
  final db = _buildDb();
  final enc = await _buildService(db);
  final friendRepo = FriendRepository(db: db, encryptionService: enc);
  final repo = BackupRepository(
    db: db,
    encryptionService: enc,
    friendRepository: friendRepo,
  );
  return (repo: repo, db: db, friendRepo: friendRepo, enc: enc);
}

Friend _makeFriend({
  String? id,
  String name = 'Alice',
  bool isDemo = false,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id ?? _uuid.v4(),
    name: name,
    mobile: '+33601020304',
    tags: '["Family"]',
    notes: 'A private note',
    careScore: 0.5,
    isConcernActive: false,
    concernNote: null,
    isDemo: isDemo,
    createdAt: now,
    updatedAt: now,
  );
}

Acquittement _makeAcq({required String friendId}) {
  return Acquittement(
    id: _uuid.v4(),
    friendId: friendId,
    type: 'call',
    note: 'Caught up briefly',
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── (a) Full roundtrip ────────────────────────────────────────────────────
  group('export → import roundtrip', () {
    test('all entities are restored with same IDs and plaintext values',
        () async {
      final (:repo, :db, :friendRepo, :enc) = await _buildFixture();

      // Seed a lightweight setting so we can verify it is exported/restored.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_densityPrefsKey, 'compact');

      // Insert test data through repositories (which encrypt sensitive fields).
      final friend = _makeFriend();
      await friendRepo.insert(friend);

      final acq = _makeAcq(friendId: friend.id);
      await db.acquittementDao.insertAcquittement(
        AcquittementsCompanion(
          id: Value(acq.id),
          friendId: Value(acq.friendId),
          type: Value(acq.type),
          note: Value(enc.encrypt(acq.note!)), // encrypt at repo layer
          createdAt: Value(acq.createdAt),
        ),
      );

      // Insert a custom event type (in addition to seeded defaults).
      final etId = _uuid.v4();
      await db.eventTypeDao.insertEventType(
        EventTypesCompanion(
          id: Value(etId),
          name: const Value('Reunion'),
          sortOrder: const Value(99),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      // Export to bytes (no file I/O needed).
      final bytes = await repo.exportToBytes(_testPass);
      expect(bytes.length, greaterThan(21), reason: 'file must be > header');

      // Decrypt to JSON and validate timestamp encoding (ISO 8601 strings).
      // Header is 21 bytes: magic(4)+version(1)+salt(16)
      final salt = bytes.sublist(5, 21);
      final key = EncryptionService.deriveKeyForBackup(
        Uint8List.fromList(utf8.encode(_testPass)),
        Uint8List.fromList(salt),
      );
      final ciphertextB64 = utf8.decode(bytes.sublist(21));
      final jsonString = EncryptionService.decryptWithKeyBytes(key, ciphertextB64);
      key.fillRange(0, key.length, 0);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['exportedAt'], isA<String>());
      final friendsJson = (decoded['friends'] as List<dynamic>);
      expect(friendsJson, isNotEmpty);
      final friendJson = friendsJson.first as Map<String, dynamic>;
      expect(friendJson['createdAt'], isA<String>());
      expect(friendJson['updatedAt'], isA<String>());
      // Settings snapshot present
      final settings = decoded['settings'] as Map<String, dynamic>?;
      expect(settings, isNotNull);
      expect(settings!['densityMode'], 'compact');

      // Write bytes to a temp file for importEncrypted.
      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/backup.enc');
      await tmpFile.writeAsBytes(bytes);

      try {
        // Clear the DB by re-inserting from a clean DB state for assertion.
        await db.friendDao.deleteAll();
        await db.acquittementDao.deleteAll();
        await db.eventTypeDao.deleteAll();

        // Also clear prefs to ensure restore writes them back.
        SharedPreferences.setMockInitialValues({});

        // Confirm clean state.
        final friends = await db.friendDao.selectAll();
        expect(friends, isEmpty, reason: 'DB should be empty before import');

        // Import.
        await repo.importEncrypted(tmpFile.path, _testPass);

        // Verify settings restored.
        final prefs2 = await SharedPreferences.getInstance();
        expect(prefs2.getString(_densityPrefsKey), 'compact');

        // Verify friend restored with correct plaintext values.
        final restoredFriends = await friendRepo.findAll();
        expect(restoredFriends.length, 1);
        final rf = restoredFriends.first;
        expect(rf.id, friend.id);
        expect(rf.name, friend.name);
        expect(rf.mobile, friend.mobile);
        expect(rf.notes, friend.notes);
        expect(rf.tags, friend.tags);

        // Verify acquittement restored.
        final rawAcqs = await db.acquittementDao.selectAllRaw();
        expect(rawAcqs.length, 1);
        expect(rawAcqs.first.id, acq.id);
        // Decrypt restored note to confirm the value
        final restoredNote = enc.decrypt(rawAcqs.first.note!);
        expect(restoredNote, acq.note);

        // Verify custom event type restored.
        final allTypes = await db.eventTypeDao.getAll();
        final customType =
            allTypes.where((t) => t.id == etId).firstOrNull;
        expect(customType, isNotNull);
        expect(customType!.name, 'Reunion');
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
      }
    });
  });

  // ── (b) Ciphertext-at-rest ────────────────────────────────────────────────
  group('ciphertext-at-rest', () {
    test('exported bytes do not contain plaintext JSON', () async {
      final (:repo, :db, :friendRepo, enc: _) = await _buildFixture();

      final friend = _makeFriend(name: 'CipherCheckFriend');
      await friendRepo.insert(friend);

      final bytes = await repo.exportToBytes(_testPass);

      // The raw bytes must not contain the plaintext friend name as UTF-8.
      final raw = utf8.decode(bytes, allowMalformed: true);
      expect(
        raw.contains('CipherCheckFriend'),
        isFalse,
        reason: 'Plaintext friend name must not appear in exported bytes',
      );
      // Also verify plaintext note is absent.
      expect(
        raw.contains('A private note'),
        isFalse,
        reason: 'Plaintext notes must not appear in exported bytes',
      );

      await db.close();
    });
  });

  // ── (c) Wrong passphrase ──────────────────────────────────────────────────
  group('wrong passphrase', () {
    test('throws DecryptionFailedAppError and leaves DB unchanged', () async {
      final (:repo, :db, :friendRepo, enc: _) = await _buildFixture();

      final friend = _makeFriend(name: 'WillNotBeErased');
      await friendRepo.insert(friend);

      final bytes = await repo.exportToBytes(_testPass);

      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/backup.enc');
      await tmpFile.writeAsBytes(bytes);

      try {
        // Attempt import with wrong passphrase.
        await expectLater(
          repo.importEncrypted(tmpFile.path, _wrongPass),
          throwsA(isA<DecryptionFailedAppError>()),
        );

        // DB must be unmodified.
        final friends = await friendRepo.findAll();
        expect(friends.length, 1);
        expect(friends.first.name, 'WillNotBeErased');
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
      }
    });
  });

  // ── (d) Corrupt file ─────────────────────────────────────────────────────
  group('corrupt / invalid file', () {
    test('throws CiphertextFormatAppError for bad magic bytes', () async {
      final (:repo, :db, :friendRepo, enc: _) = await _buildFixture();

      final friend = _makeFriend(name: 'OriginalData');
      await friendRepo.insert(friend);

      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/bad.enc');
      // Write garbage bytes (not a valid SPBK file).
      await tmpFile.writeAsBytes(List.generate(64, (i) => i));

      try {
        await expectLater(
          repo.importEncrypted(tmpFile.path, _testPass),
          throwsA(isA<CiphertextFormatAppError>()),
        );

        // DB must be unmodified.
        final friends = await friendRepo.findAll();
        expect(friends.length, 1);
        expect(friends.first.name, 'OriginalData');
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
      }
    });

    test('throws CiphertextFormatAppError for truncated header', () async {
      final (:repo, :db, :friendRepo, enc: _) = await _buildFixture();

      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/short.enc');
      // Only 4 bytes — too short even for the magic.
      await tmpFile.writeAsBytes([0x53, 0x50, 0x42, 0x4B]);

      try {
        await expectLater(
          repo.importEncrypted(tmpFile.path, _testPass),
          throwsA(isA<CiphertextFormatAppError>()),
        );
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
      }
    });
  });

  // ── (e) Demo friends excluded ─────────────────────────────────────────────
  group('demo friends excluded', () {
    test('demo friend is not included in the exported payload', () async {
      final (:repo, :db, :friendRepo, :enc) = await _buildFixture();

      // The in-memory DB seeds Sophie (isDemo=true) from beforeOpen.
      // We only insert a real friend on top of that.
      final realFriend = _makeFriend(name: 'RealPerson', isDemo: false);
      await friendRepo.insert(realFriend);
      // After insert, Sophie is automatically removed; only realFriend remains.

      final bytes = await repo.exportToBytes(_testPass);

      // Verify by importing into a fresh separate DB.
      final db2 = _buildDb();
      final enc2 = await _buildService(db2);
      final friendRepo2 = FriendRepository(db: db2, encryptionService: enc2);
      final repo2 = BackupRepository(
        db: db2,
        encryptionService: enc2,
        friendRepository: friendRepo2,
      );

      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/backup.enc');
      await tmpFile.writeAsBytes(bytes);

      try {
        await repo2.importEncrypted(tmpFile.path, _testPass);
        final restored = await friendRepo2.findAll();
        expect(restored.length, 1, reason: 'demo friend must not be restored');
        expect(restored.first.name, 'RealPerson');
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
        await db2.close();
      }
    });
  });

  // ── (f) All-or-nothing replace-all ───────────────────────────────────────
  group('all-or-nothing restore', () {
    test('existing friend is replaced after successful import', () async {
      final (:repo, :db, :friendRepo, enc: _) = await _buildFixture();

      // Pre-existing friend in the DB.
      final oldFriend = _makeFriend(name: 'OldData');
      await friendRepo.insert(oldFriend);

      // Source DB has a different friend.
      final db2 = _buildDb();
      final enc2 = await _buildService(db2);
      final friendRepo2 = FriendRepository(db: db2, encryptionService: enc2);
      final repo2 = BackupRepository(
        db: db2,
        encryptionService: enc2,
        friendRepository: friendRepo2,
      );
      final newFriend = _makeFriend(name: 'NewData');
      await friendRepo2.insert(newFriend);

      final bytes = await repo2.exportToBytes(_testPass);

      final dir = Directory.systemTemp.createTempSync('spetaka_test_');
      final tmpFile = File('${dir.path}/backup.enc');
      await tmpFile.writeAsBytes(bytes);

      try {
        // Import into repo (which has 'OldData').
        await repo.importEncrypted(tmpFile.path, _testPass);

        final friends = await friendRepo.findAll();
        // OldData should be gone; NewData should be present.
        expect(friends.any((f) => f.name == 'OldData'), isFalse);
        expect(friends.any((f) => f.name == 'NewData'), isTrue);
      } finally {
        dir.deleteSync(recursive: true);
        await db.close();
        await db2.close();
      }
    });
  });
}
