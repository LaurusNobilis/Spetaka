// test/repositories/field_encryption_test.dart
//
// Tests Story 1.7 — Sensitive Field Encryption at Repository Layer (NFR6)
//
// AC6 coverage:
//   (a) Friend roundtrip: write with notes/concernNote → read back → plaintext matches
//   (b) Ciphertext-at-rest: DAO-level read confirms stored value ≠ original plaintext
//   (c) Acquittement roundtrip: write with note → read back → plaintext matches
//   (d) Ciphertext-at-rest for acquittement note
//   (e) Missing key: EncryptionNotInitializedAppError on insert
//   (f) Missing key: EncryptionNotInitializedAppError on read (stored ciphertext)
//
// Additional AC coverage:
//   - AC3: non-sensitive fields (name, mobile, careScore) stored as plaintext
//   - AC4: DAOs are encryption-agnostic (raw stored values accessed directly)
//   - AC5: typed errors propagate correctly

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/acquittement/data/acquittement_repository.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:uuid/uuid.dart';

class _NoopAppLifecycleService extends AppLifecycleService {
  _NoopAppLifecycleService({required super.binding});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op: some widget-test environments emit lifecycle events that would
    // clear the in-memory key (intended production behavior). For format/wrong-
    // key tests we want a stable key to assert error types deterministically.
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  const testPass = 'spetaka-test-passphrase-1.7';
  final uuid = const Uuid();

  AppDatabase buildDb() => AppDatabase(NativeDatabase.memory());

  Future<(EncryptionService, AppLifecycleService)> buildInitializedService() async {
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    // Each test gets isolated SharedPrefs → unique salt per run.
    SharedPreferences.setMockInitialValues({});
    final service = EncryptionService(lifecycleService: lifecycle);
    await service.initialize(testPass);
    return (service, lifecycle);
  }

  Friend makeTestFriend({
    String? id,
    String? notes = 'Private note',
    String? concernNote = 'Concern detail',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Friend(
      id: id ?? uuid.v4(),
      name: 'Alice',
      mobile: '+33601020304',
      notes: notes,
      careScore: 0.5,
      isConcernActive: true,
      concernNote: concernNote,
      createdAt: now,
      updatedAt: now,
    );
  }

  Acquittement makeTestAcquittement({
    required String friendId,
    String? note = 'Felt great catching up',
  }) {
    return Acquittement(
      id: uuid.v4(),
      friendId: friendId,
      type: 'call',
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ---------------------------------------------------------------------------
  // Group 1: FriendRepository — write/read encryption roundtrip
  // ---------------------------------------------------------------------------

  group('FriendRepository — encryption roundtrip (AC1, AC2, AC6)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late FriendRepository repo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildInitializedService();
      repo = FriendRepository(db: db, encryptionService: enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('notes roundtrip: insert then findById returns original plaintext', () async {
      final friend = makeTestFriend(notes: 'She loves jazz');
      await repo.insert(friend);

      final retrieved = await repo.findById(friend.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.notes, equals('She loves jazz'),
          reason: 'repository must decrypt notes before returning');
    });

    test('concernNote roundtrip: insert then findById returns original plaintext', () async {
      final friend = makeTestFriend(concernNote: 'Going through hard times');
      await repo.insert(friend);

      final retrieved = await repo.findById(friend.id);

      expect(retrieved!.concernNote, equals('Going through hard times'),
          reason: 'repository must decrypt concernNote before returning');
    });

    test('findById returns null for non-existent id', () async {
      final result = await repo.findById(uuid.v4());
      expect(result, isNull);
    });

    test('findAll returns all decrypted friends', () async {
      await repo.insert(makeTestFriend(id: uuid.v4(), notes: 'Note A'));
      await repo.insert(makeTestFriend(id: uuid.v4(), notes: 'Note B'));

      final all = await repo.findAll();
      expect(all, hasLength(2));
      final noteValues = all.map((f) => f.notes).toList();
      expect(noteValues, containsAll(['Note A', 'Note B']));
    });

    test('watchAll stream emits decrypted friends', () async {
      final friend = makeTestFriend(notes: 'Stream note');
      await repo.insert(friend);

      final list = await repo.watchAll().first;
      final match = list.singleWhere((f) => f.id == friend.id);
      expect(match.notes, equals('Stream note'));
    });

    test('update re-encrypts sensitive fields', () async {
      final original = makeTestFriend(notes: 'Original note');
      await repo.insert(original);

      final updated = Friend(
        id: original.id,
        name: original.name,
        mobile: original.mobile,
        notes: 'Updated note',
        careScore: original.careScore,
        isConcernActive: original.isConcernActive,
        concernNote: original.concernNote,
        createdAt: original.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await repo.update(updated);

      final retrieved = await repo.findById(original.id);
      expect(retrieved!.notes, equals('Updated note'));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2: FriendRepository — ciphertext-at-rest (AC6b, AC4)
  // ---------------------------------------------------------------------------

  group('FriendRepository — ciphertext at rest (AC4, AC6)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late FriendRepository repo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildInitializedService();
      repo = FriendRepository(db: db, encryptionService: enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('DAO-stored notes is ciphertext (not original plaintext)', () async {
      const plainNotes = 'She loves hiking in the Alps';
      final friend = makeTestFriend(notes: plainNotes, concernNote: null);
      await repo.insert(friend);

      // Bypass repository — read raw DAO value (AC4: DAO is encryption-agnostic).
      final rawRow = await db.friendDao.findById(friend.id);

      expect(rawRow, isNotNull);
      expect(rawRow!.notes, isNotNull,
          reason: 'notes column must not be null after insert');
      expect(rawRow.notes, isNot(equals(plainNotes)),
          reason: 'DAO must store ciphertext, not plaintext');
    });

    test('DAO-stored concernNote is ciphertext (not original plaintext)', () async {
      const plainConcern = 'Recently lost a job';
      final friend = makeTestFriend(notes: null, concernNote: plainConcern);
      await repo.insert(friend);

      final rawRow = await db.friendDao.findById(friend.id);

      expect(rawRow!.concernNote, isNotNull);
      expect(rawRow.concernNote, isNot(equals(plainConcern)),
          reason: 'DAO must store ciphertext for concernNote');
    });

    test('non-sensitive fields (name, mobile, careScore) stored as plaintext (AC3)', () async {
      final friend = makeTestFriend();
      await repo.insert(friend);

      // DAO row must have plaintext non-sensitive fields.
      final rawRow = await db.friendDao.findById(friend.id);

      expect(rawRow!.name, equals('Alice'),
          reason: 'name must remain plaintext');
      expect(rawRow.mobile, equals('+33601020304'),
          reason: 'mobile must remain plaintext');
      expect(rawRow.careScore, equals(0.5),
          reason: 'careScore must remain plaintext');
    });

    test('null notes stored as null (no encryption of null)', () async {
      final friend = makeTestFriend(notes: null, concernNote: null);

      // Override makeTestFriend with explicit null values.
      final nullFriend = Friend(
        id: uuid.v4(),
        name: 'Bob',
        mobile: '+33612345678',
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await repo.insert(nullFriend);

      final rawRow = await db.friendDao.findById(nullFriend.id);
      expect(rawRow!.notes, isNull, reason: 'null notes must be stored as null');
      expect(rawRow.concernNote, isNull,
          reason: 'null concernNote must be stored as null');
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3: AcquittementRepository — encryption roundtrip (AC1, AC2, AC6c)
  // ---------------------------------------------------------------------------

  group('AcquittementRepository — encryption roundtrip (AC1, AC2, AC6)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late AcquittementRepository repo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildInitializedService();
      repo = AcquittementRepository(db: db, encryptionService: enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('note roundtrip: insert then findById returns original plaintext', () async {
      final entry = makeTestAcquittement(
        friendId: uuid.v4(),
        note: 'Caught up over coffee',
      );
      await repo.insert(entry);

      final retrieved = await repo.findById(entry.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.note, equals('Caught up over coffee'),
          reason: 'repository must decrypt note before returning');
    });

    test('null note stored and returned as null', () async {
      final entry = makeTestAcquittement(friendId: uuid.v4(), note: null);
      await repo.insert(entry);

      final retrieved = await repo.findById(entry.id);
      expect(retrieved!.note, isNull);
    });

    test('DAO-stored note is ciphertext (not original plaintext)', () async {
      const plainNote = 'Very personal conversation';
      final entry = makeTestAcquittement(friendId: uuid.v4(), note: plainNote);
      await repo.insert(entry);

      // Bypass repository — read raw DAO value.
      final rawRow = await db.acquittementDao.findById(entry.id);

      expect(rawRow!.note, isNotNull);
      expect(rawRow.note, isNot(equals(plainNote)),
          reason: 'DAO must store ciphertext for note');
    });

    test('findByFriendId returns all decrypted entries for a friend', () async {
      final friendId = uuid.v4();
      await repo.insert(makeTestAcquittement(friendId: friendId, note: 'First call'));
      await repo.insert(makeTestAcquittement(friendId: friendId, note: 'Second call'));

      final all = await repo.findByFriendId(friendId);
      expect(all, hasLength(2));
      final notes = all.map((e) => e.note).toList();
      expect(notes, containsAll(['First call', 'Second call']));
    });

    test('plaintext fields (type, friendId, createdAt) stored as plaintext (AC3)', () async {
      final friendId = uuid.v4();
      final entry = makeTestAcquittement(friendId: friendId, note: 'A note');
      await repo.insert(entry);

      final rawRow = await db.acquittementDao.findById(entry.id);
      expect(rawRow!.friendId, equals(friendId),
          reason: 'friendId must remain plaintext');
      expect(rawRow.type, equals('call'),
          reason: 'type must remain plaintext');
    });
  });

  // ---------------------------------------------------------------------------
  // Group 4: Typed error propagation (AC5)
  // ---------------------------------------------------------------------------

  group('Typed error propagation (AC5)', () {
    late AppDatabase db;
    late AppLifecycleService lifecycle;

    setUp(() {
      db = buildDb();
      lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    });

    tearDown(() async {
      await db.close();
      lifecycle.dispose();
    });

    test('FriendRepository.insert without initialized key throws EncryptionNotInitializedAppError',
        () async {
      SharedPreferences.setMockInitialValues({});
      final uninitService = EncryptionService(lifecycleService: lifecycle);
      // Deliberately NOT calling initialize()
      final repo = FriendRepository(db: db, encryptionService: uninitService);

      expect(
        () async => repo.insert(makeTestFriend()),
        throwsA(isA<EncryptionNotInitializedAppError>()),
      );

      uninitService.dispose();
    });

    test('FriendRepository.findById with stored ciphertext and no key throws error',
        () async {
      // 1. Insert with an initialized service.
      SharedPreferences.setMockInitialValues({});
      final lifecycle2 = AppLifecycleService(binding: WidgetsBinding.instance);
      final initService = EncryptionService(lifecycleService: lifecycle2);
      await initService.initialize(testPass);
      final writeRepo = FriendRepository(db: db, encryptionService: initService);
      final friend = makeTestFriend(notes: 'Secret');
      await writeRepo.insert(friend);
      initService.dispose();
      lifecycle2.dispose();

      // 2. Attempt to read without initialized service → key cleared.
      SharedPreferences.setMockInitialValues({});
      final uninitService = EncryptionService(lifecycleService: lifecycle);
      // NOT initialized — key is null.
      final readRepo = FriendRepository(db: db, encryptionService: uninitService);

      expect(
        () async => readRepo.findById(friend.id),
        throwsA(isA<EncryptionNotInitializedAppError>()),
      );

      uninitService.dispose();
    });

    test('AcquittementRepository.insert without initialized key throws EncryptionNotInitializedAppError',
        () async {
      SharedPreferences.setMockInitialValues({});
      final uninitService = EncryptionService(lifecycleService: lifecycle);
      final repo = AcquittementRepository(db: db, encryptionService: uninitService);

      expect(
        () async => repo.insert(makeTestAcquittement(friendId: uuid.v4())),
        throwsA(isA<EncryptionNotInitializedAppError>()),
      );

      uninitService.dispose();
    });

    test('FriendRepository.findById throws CiphertextFormatAppError for invalid stored ciphertext',
        () async {
      SharedPreferences.setMockInitialValues({});
      final noopLifecycle = _NoopAppLifecycleService(binding: WidgetsBinding.instance);
      final service = EncryptionService(lifecycleService: noopLifecycle);
      await service.initialize(testPass);
      final repo = FriendRepository(db: db, encryptionService: service);

      final now = DateTime.now().millisecondsSinceEpoch;
      final id = uuid.v4();
      await db.friendDao.insertFriend(
        FriendsCompanion(
          id: Value(id),
          name: const Value('Alice'),
          mobile: const Value('+33601020304'),
          notes: const Value('this-is-not-base64url'),
          careScore: const Value(0.5),
          isConcernActive: const Value(false),
          concernNote: const Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await expectLater(
        repo.findById(id),
        throwsA(isA<CiphertextFormatAppError>()),
      );

      service.dispose();
      noopLifecycle.dispose();
    });

    test('FriendRepository.findById throws DecryptionFailedAppError when key is wrong',
        () async {
      // Keep the same salt in prefs for both services.
      SharedPreferences.setMockInitialValues({});

      final lifecycleA = _NoopAppLifecycleService(binding: WidgetsBinding.instance);
      final serviceA = EncryptionService(lifecycleService: lifecycleA);
      await serviceA.initialize('pass-A');
      final ciphertext = serviceA.encrypt('Secret payload');

      final now = DateTime.now().millisecondsSinceEpoch;
      final id = uuid.v4();
      await db.friendDao.insertFriend(
        FriendsCompanion(
          id: Value(id),
          name: const Value('Alice'),
          mobile: const Value('+33601020304'),
          notes: Value(ciphertext),
          careScore: const Value(0.5),
          isConcernActive: const Value(false),
          concernNote: const Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final lifecycleB = _NoopAppLifecycleService(binding: WidgetsBinding.instance);
      final serviceB = EncryptionService(lifecycleService: lifecycleB);
      await serviceB.initialize('pass-B');
      final repo = FriendRepository(db: db, encryptionService: serviceB);

      await expectLater(
        repo.findById(id),
        throwsA(isA<DecryptionFailedAppError>()),
      );

      serviceA.dispose();
      lifecycleA.dispose();
      serviceB.dispose();
      lifecycleB.dispose();
    });

    test('AcquittementRepository.findById throws DecryptionFailedAppError when key is wrong',
        () async {
      SharedPreferences.setMockInitialValues({});

      final lifecycleA = _NoopAppLifecycleService(binding: WidgetsBinding.instance);
      final serviceA = EncryptionService(lifecycleService: lifecycleA);
      await serviceA.initialize('pass-A');
      final ciphertext = serviceA.encrypt('Sensitive note');

      final id = uuid.v4();
      final friendId = uuid.v4();
      await db.acquittementDao.insertAcquittement(
        AcquittementsCompanion(
          id: Value(id),
          friendId: Value(friendId),
          type: const Value('call'),
          note: Value(ciphertext),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      final lifecycleB = _NoopAppLifecycleService(binding: WidgetsBinding.instance);
      final serviceB = EncryptionService(lifecycleService: lifecycleB);
      await serviceB.initialize('pass-B');
      final repo = AcquittementRepository(db: db, encryptionService: serviceB);

      await expectLater(
        repo.findById(id),
        throwsA(isA<DecryptionFailedAppError>()),
      );

      serviceA.dispose();
      lifecycleA.dispose();
      serviceB.dispose();
      lifecycleB.dispose();
    });
  });
}
