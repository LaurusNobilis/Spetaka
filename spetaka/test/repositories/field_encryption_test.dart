// test/repositories/field_encryption_test.dart
//
// Tests Story 1.7 — Sensitive Field Encryption at Repository Layer (NFR6)
// Tests Story 1.8 — Extend Field Encryption to `name` and `mobile` (NFR6 Complete)
//
// AC6 coverage (Story 1.7):
//   (a) Friend roundtrip: write with notes/concernNote → read back → plaintext matches
//   (b) Ciphertext-at-rest: DAO-level read confirms stored value ≠ original plaintext
//   (c) Acquittement roundtrip: write with note → read back → plaintext matches
//   (d) Ciphertext-at-rest for acquittement note
//   (e) Missing key: EncryptionNotInitializedAppError on insert
//   (f) Missing key: EncryptionNotInitializedAppError on read (stored ciphertext)
//
// Story 1.8 new coverage:
//   (g) name & mobile roundtrip: write → read back → plaintext matches
//   (h) Ciphertext-at-rest for name & mobile: DAO-level value ≠ original plaintext
//   (i) watchAll() and findAll() return friends sorted case-insensitively by name
//   (j) Legacy plaintext compatibility: pre-1.8 rows with plaintext name/mobile survive
//
// Additional AC coverage:
//   - AC3: non-sensitive fields (careScore, tags) stored as plaintext
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
import 'package:spetaka/features/friends/domain/friend_tags_codec.dart';
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
  const uuid = Uuid();

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
    String? tags,
    String? notes = 'Private note',
    String? concernNote = 'Concern detail',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Friend(
      id: id ?? uuid.v4(),
      name: 'Alice',
      mobile: '+33601020304',
      tags: tags,
      notes: notes,
      careScore: 0.5,
      isConcernActive: true,
      concernNote: concernNote,
      isDemo: false,
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
      expect(
        retrieved!.notes,
        equals('She loves jazz'),
        reason: 'repository must decrypt notes before returning',
      );
    });

    test('concernNote roundtrip: insert then findById returns original plaintext', () async {
      final friend = makeTestFriend(concernNote: 'Going through hard times');
      await repo.insert(friend);

      final retrieved = await repo.findById(friend.id);

      expect(
        retrieved!.concernNote,
        equals('Going through hard times'),
        reason: 'repository must decrypt concernNote before returning',
      );
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
        tags: original.tags,
        notes: 'Updated note',
        careScore: original.careScore,
        isConcernActive: original.isConcernActive,
        concernNote: original.concernNote,
        isDemo: false,
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
      expect(
        rawRow!.notes,
        isNotNull,
        reason: 'notes column must not be null after insert',
      );
      expect(
        rawRow.notes,
        isNot(equals(plainNotes)),
        reason: 'DAO must store ciphertext, not plaintext',
      );
    });

    test('DAO-stored concernNote is ciphertext (not original plaintext)', () async {
      const plainConcern = 'Recently lost a job';
      final friend = makeTestFriend(notes: null, concernNote: plainConcern);
      await repo.insert(friend);

      final rawRow = await db.friendDao.findById(friend.id);

      expect(rawRow!.concernNote, isNotNull);
      expect(
        rawRow.concernNote,
        isNot(equals(plainConcern)),
        reason: 'DAO must store ciphertext for concernNote',
      );
    });

    test(
        'sensitive fields (name, mobile) are ciphertext; non-sensitive fields (tags, careScore) remain plaintext (AC-3, Story 1.8)',
        () async {
      final tags = encodeFriendTags({'Work', 'Family'});
      final friend = makeTestFriend(tags: tags);
      await repo.insert(friend);

      // Bypass repository — read raw DAO value (AC4: DAO is encryption-agnostic).
      final rawRow = await db.friendDao.findById(friend.id);

      // name is now encrypted (Story 1.8)
      expect(
        rawRow!.name,
        isNot(equals('Alice')),
        reason: 'name must be stored as ciphertext after Story 1.8',
      );
      // mobile is now encrypted (Story 1.8)
      expect(
        rawRow.mobile,
        isNot(equals('+33601020304')),
        reason: 'mobile must be stored as ciphertext after Story 1.8',
      );
      // careScore remains plaintext
      expect(
        rawRow.careScore,
        equals(0.5),
        reason: 'careScore must remain plaintext',
      );
      // tags remains plaintext
      expect(
        rawRow.tags,
        equals(tags),
        reason: 'tags must remain plaintext (not encrypted)',
      );
    });

    test('null notes stored as null (no encryption of null)', () async {
      // Override makeTestFriend with explicit null values.
      final nullFriend = Friend(
        id: uuid.v4(),
        name: 'Bob',
        mobile: '+33612345678',
        tags: null,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        isDemo: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await repo.insert(nullFriend);

      final rawRow = await db.friendDao.findById(nullFriend.id);
      expect(
        rawRow!.notes,
        isNull,
        reason: 'null notes must be stored as null',
      );
      expect(
        rawRow.concernNote,
        isNull,
        reason: 'null concernNote must be stored as null',
      );
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
      expect(
        retrieved!.note,
        equals('Caught up over coffee'),
        reason: 'repository must decrypt note before returning',
      );
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
      expect(
        rawRow.note,
        isNot(equals(plainNote)),
        reason: 'DAO must store ciphertext for note',
      );
    });

    test('findByFriendId returns all decrypted entries for a friend', () async {
      final friendId = uuid.v4();
      await repo.insert(
        makeTestAcquittement(friendId: friendId, note: 'First call'),
      );
      await repo.insert(
        makeTestAcquittement(friendId: friendId, note: 'Second call'),
      );

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
      expect(
        rawRow!.friendId,
        equals(friendId),
        reason: 'friendId must remain plaintext',
      );
      expect(
        rawRow.type,
        equals('call'),
        reason: 'type must remain plaintext',
      );
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

  // ---------------------------------------------------------------------------
  // Group 5: Story 1.8 — name & mobile encryption (AC-1, AC-2, AC-3, AC-8, AC-9)
  // ---------------------------------------------------------------------------

  group('Story 1.8 — name & mobile encryption roundtrip (AC-1, AC-2)', () {
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

    test('name roundtrip: insert then findById returns original plaintext name',
        () async {
      final friend = makeTestFriend(notes: null, concernNote: null);
      await repo.insert(friend);

      final retrieved = await repo.findById(friend.id);

      expect(retrieved, isNotNull);
      expect(
        retrieved!.name,
        equals('Alice'),
        reason: 'repository must decrypt name before returning',
      );
    });

    test('mobile roundtrip: insert then findById returns original plaintext mobile',
        () async {
      final friend = makeTestFriend(notes: null, concernNote: null);
      await repo.insert(friend);

      final retrieved = await repo.findById(friend.id);

      expect(
        retrieved!.mobile,
        equals('+33601020304'),
        reason: 'repository must decrypt mobile before returning',
      );
    });

    test('update re-encrypts name and mobile correctly', () async {
      final original = makeTestFriend(notes: null, concernNote: null);
      await repo.insert(original);

      final updated = original.copyWith(
        name: 'Alice Updated',
        mobile: '+33699887766',
        updatedAt: original.updatedAt + 1000,
      );
      await repo.update(updated);

      final retrieved = await repo.findById(original.id);
      expect(retrieved!.name, equals('Alice Updated'));
      expect(retrieved.mobile, equals('+33699887766'));
    });
  });

  group('Story 1.8 — name & mobile ciphertext at rest (AC-3, AC-8)', () {
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

    test('DAO-stored name is ciphertext (not original plaintext)', () async {
      final friend = makeTestFriend(notes: null, concernNote: null);
      await repo.insert(friend);

      final rawRow = await db.friendDao.findById(friend.id);

      expect(
        rawRow!.name,
        isNot(equals('Alice')),
        reason: 'DAO must store ciphertext for name, not plaintext',
      );
    });

    test('DAO-stored mobile is ciphertext (not original plaintext)', () async {
      final friend = makeTestFriend(notes: null, concernNote: null);
      await repo.insert(friend);

      final rawRow = await db.friendDao.findById(friend.id);

      expect(
        rawRow!.mobile,
        isNot(equals('+33601020304')),
        reason: 'DAO must store ciphertext for mobile, not plaintext',
      );
    });
  });

  group('Story 1.8 — watchAll / findAll alphabetical sort (AC-3)', () {
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

    Future<Friend> insertNamed(String name) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final f = Friend(
        id: uuid.v4(),
        name: name,
        mobile: '+33600000000',
        tags: null,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        isDemo: false,
        createdAt: now,
        updatedAt: now,
      );
      await repo.insert(f);
      return f;
    }

    test('findAll returns friends sorted case-insensitively by name', () async {
      await insertNamed('Zara');
      await insertNamed('alice');
      await insertNamed('Bob');

      final all = await repo.findAll();

      expect(all.map((f) => f.name).toList(), equals(['alice', 'Bob', 'Zara']));
    });

    test('watchAll stream emits friends sorted case-insensitively by name',
        () async {
      await insertNamed('Zara');
      await insertNamed('alice');
      await insertNamed('Bob');

      final list = await repo.watchAll().first;

      expect(list.map((f) => f.name).toList(), equals(['alice', 'Bob', 'Zara']));
    });
  });

  group('Story 1.8 — legacy plaintext compatibility (AC-9)', () {
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

    test(
        'findById handles legacy row with plaintext name and mobile without error',
        () async {
      // Simulate a pre-Story-1.8 row: insert directly via DAO with plaintext values.
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = uuid.v4();
      await db.friendDao.insertFriend(
        FriendsCompanion(
          id: Value(id),
          name: const Value('Legacy Alice'),   // plaintext — legacy row
          mobile: const Value('+33611223344'), // plaintext — legacy row
          notes: const Value(null),
          careScore: const Value(0.0),
          isConcernActive: const Value(false),
          concernNote: const Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Reading via repository must NOT throw; legacy plaintext passes through.
      final retrieved = await repo.findById(id);

      expect(retrieved, isNotNull);
      expect(
        retrieved!.name,
        equals('Legacy Alice'),
        reason: 'legacy plaintext name must be returned as-is',
      );
      expect(
        retrieved.mobile,
        equals('+33611223344'),
        reason: 'legacy plaintext mobile must be returned as-is',
      );
    });

    test('findAll includes legacy plaintext rows without bricking the list',
        () async {
      // One legacy row with plaintext name/mobile.
      final now = DateTime.now().millisecondsSinceEpoch;
      final legacyId = uuid.v4();
      await db.friendDao.insertFriend(
        FriendsCompanion(
          id: Value(legacyId),
          name: const Value('Legacy Bob'),
          mobile: const Value('+33622334455'),
          notes: const Value(null),
          careScore: const Value(0.0),
          isConcernActive: const Value(false),
          concernNote: const Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // One new row with encrypted name/mobile.
      final nowFriend = Friend(
        id: uuid.v4(),
        name: 'New Carol',
        mobile: '+33633445566',
        tags: null,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        isDemo: false,
        createdAt: now,
        updatedAt: now,
      );
      await repo.insert(nowFriend);

      final all = await repo.findAll();

      expect(all, hasLength(2));
      final names = all.map((f) => f.name).toSet();
      expect(names, containsAll(['Legacy Bob', 'New Carol']));
    });
  });
}
