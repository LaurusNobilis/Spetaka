// test/repositories/friend_repository_test.dart
//
// Tests Story 2.1 — Friend Card Creation via Phone Contact Import (AC7)
//
// Coverage:
//   (a) insert friend (notes/concernNote null) → findById returns expected plaintext values
//   (b) findById returns null for unknown id
//   (c) insert → findAll returns the inserted friend
//
// Setup follows the pattern established in test/repositories/field_encryption_test.dart:
//   - in-memory DB: AppDatabase(NativeDatabase.memory())
//   - mock SharedPreferences: SharedPreferences.setMockInitialValues({})
//   - EncryptionService initialized once per test group

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPass = 'spetaka-test-passphrase-2.1';
  const uuid = Uuid();

  AppDatabase buildDb() => AppDatabase(NativeDatabase.memory());

  Future<(EncryptionService, AppLifecycleService)> buildService() async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    await service.initialize(testPass);
    return (service, lifecycle);
  }

  /// Builds a minimal [Friend] with no notes/concernNote (Story 2.1 import case).
  Friend makeMinimalFriend({String? id}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Friend(
      id: id ?? uuid.v4(),
      name: 'Bob Contact',
      mobile: '+33612345678',
      notes: null,
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Story 2.1 — FriendRepository minimal CRUD (AC7)
  // ---------------------------------------------------------------------------

  group('FriendRepository — Story 2.1 (AC7)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late FriendRepository repo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildService();
      repo = FriendRepository(db: db, encryptionService: enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    // -------------------------------------------------------------------------
    // AC7 (a): insert (notes null, concernNote null) → findById returns correct
    //          plaintext values for name, mobile, and careScore
    // -------------------------------------------------------------------------

    test(
      'insert friend (notes/concernNote null) → findById returns correct plaintext fields',
      () async {
        final friend = makeMinimalFriend();

        await repo.insert(friend);

        final found = await repo.findById(friend.id);

        expect(found, isNotNull);
        expect(found!.id, friend.id);
        expect(found.name, 'Bob Contact');
        expect(found.mobile, '+33612345678');
        expect(found.careScore, 0.0);
        expect(found.isConcernActive, isFalse);
        expect(found.notes, isNull);
        expect(found.concernNote, isNull);
        expect(found.createdAt, friend.createdAt);
        expect(found.updatedAt, friend.updatedAt);
      },
    );

    // -------------------------------------------------------------------------
    // AC7 (b): findById returns null for an unknown id
    // -------------------------------------------------------------------------

    test('findById returns null for unknown id', () async {
      final result = await repo.findById('does-not-exist-${uuid.v4()}');
      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // AC7 (c): insert → findAll returns the inserted friend
    // -------------------------------------------------------------------------

    test('insert → findAll returns the inserted friend with correct id', () async {
      final friend = makeMinimalFriend();

      await repo.insert(friend);

      final all = await repo.findAll();
      expect(all, hasLength(1));
      expect(all.first.id, friend.id);
      expect(all.first.name, 'Bob Contact');
    });

    // -------------------------------------------------------------------------
    // Multiple inserts → correct count
    // -------------------------------------------------------------------------

    test('insert two friends → findAll returns both', () async {
      await repo.insert(makeMinimalFriend());
      await repo.insert(makeMinimalFriend());

      final all = await repo.findAll();
      expect(all, hasLength(2));
    });
  });
}
