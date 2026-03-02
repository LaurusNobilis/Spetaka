// test/repositories/acquittement_repository_test.dart
//
// Tests Story 5.5 — Care Score Update After Acquittement.
//
// Coverage:
//   (a) computeCareScore unit tests:
//       – score decreases as daysSinceLastContact increases (formula monotonicity)
//       – score resets after acquittement (daysSince = 0)
//       – weighted comparison: Family subtag scores higher than Acquaintance
//       – clamped to [0.0, 1.0] (no negative, no > 1)
//       – default interval used when expectedIntervalDays is null or zero
//   (b) insertAndUpdateCareScore integration tests (in-memory DB):
//       – careScore on friend row is > 0 after acquittement
//       – acquittement row is persisted in single transaction
//       – when friend has a recurring event the cadence is used
//       – no crash when friend is missing (guard path)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/acquittement/data/acquittement_repository.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPass = 'spetaka-test-passphrase-5-5';
  const uuid = Uuid();

  AppDatabase buildDb() => AppDatabase(NativeDatabase.memory());

  Future<(EncryptionService, AppLifecycleService)> buildService() async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize(testPass);
    return (enc, lifecycle);
  }

  Friend makeFriend({
    String? id,
    String? tags,
    double careScore = 0.0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Friend(
      id: id ?? uuid.v4(),
      name: 'Test Friend',
      mobile: '+33600000001',
      tags: tags,
      notes: null,
      careScore: careScore,
      isConcernActive: false,
      concernNote: null,
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Acquittement makeAcquittement({required String friendId}) {
    return Acquittement(
      id: uuid.v4(),
      friendId: friendId,
      type: 'call',
      note: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ===========================================================================
  // Part A — computeCareScore unit tests (pure function)
  // ===========================================================================

  group('computeCareScore — pure function', () {
    test('score is > 0 immediately after acquittement (daysSince = 0)', () {
      final score = computeCareScore(daysSinceLastContact: 0);
      expect(score, greaterThan(0.0));
    });

    test('score decreases as daysSinceLastContact increases', () {
      final score0 = computeCareScore(
        daysSinceLastContact: 0,
        expectedIntervalDays: 30,
      );
      final score15 = computeCareScore(
        daysSinceLastContact: 15,
        expectedIntervalDays: 30,
      );
      final score30 = computeCareScore(
        daysSinceLastContact: 30,
        expectedIntervalDays: 30,
      );

      expect(score0, greaterThan(score15),
          reason: 'fresh contact should score higher than stale',);
      expect(score15, greaterThan(score30),
          reason: 'half-elapsed should score higher than fully elapsed',);
    });

    test('score clamps to 0.0 when daysSince >= expectedIntervalDays', () {
      final score = computeCareScore(
        daysSinceLastContact: 60,
        expectedIntervalDays: 30,
      );
      expect(score, equals(0.0),
          reason: 'overdue contact must not produce negative score',);
    });

    test('score never exceeds 1.0', () {
      // daysSince = -1 (hypothetical future overlap) must still be ≤ 1.
      final score = computeCareScore(
        daysSinceLastContact: -10,
        expectedIntervalDays: 30,
      );
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('Family tag produces higher score than Acquaintance (weighted)', () {
      const days = 5;
      final familyScore = computeCareScore(
        daysSinceLastContact: days,
        expectedIntervalDays: 30,
        tags: ['Family'], // weight 3.0 / kMaxCareWeight 3.0 = 1.0
      );
      final acquaintanceScore = computeCareScore(
        daysSinceLastContact: days,
        expectedIntervalDays: 30,
        tags: ['Acquaintance'], // weight 1.0 / 3.0 ≈ 0.33
      );
      expect(familyScore, greaterThan(acquaintanceScore),
          reason: 'Family should score higher than Acquaintance',);
    });

    test('uses kDefaultExpectedIntervalDays when expectedIntervalDays is null',
        () {
      final scoreWithDefault = computeCareScore(
        daysSinceLastContact: 0,
        expectedIntervalDays: null,
      );
      final scoreWithExplicit = computeCareScore(
        daysSinceLastContact: 0,
        expectedIntervalDays: kDefaultExpectedIntervalDays,
      );
      expect(scoreWithDefault, equals(scoreWithExplicit));
    });

    test('uses kDefaultExpectedIntervalDays when expectedIntervalDays is zero',
        () {
      final score = computeCareScore(
        daysSinceLastContact: 0,
        expectedIntervalDays: 0,
      );
      // Must not throw — should use default interval.
      expect(score, greaterThan(0.0));
    });
  });

  // ===========================================================================
  // Part B — insertAndUpdateCareScore integration tests
  // ===========================================================================

  group('AcquittementRepository.insertAndUpdateCareScore', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AcquittementRepository acquittementRepo;
    late FriendRepository friendRepo;

    setUp(() async {
      db = buildDb();
      final (service, _) = await buildService();
      enc = service;
      acquittementRepo =
          AcquittementRepository(db: db, encryptionService: enc);
      friendRepo = FriendRepository(db: db, encryptionService: enc);
    });

    tearDown(() async => db.close());

    test('careScore > 0 on friend row after acquittement', () async {
      final friend = makeFriend();
      await friendRepo.insert(friend);

      await acquittementRepo.insertAndUpdateCareScore(
        makeAcquittement(friendId: friend.id),
      );

      final updated = await friendRepo.findById(friend.id);
      expect(updated, isNotNull);
      expect(updated!.careScore, greaterThan(0.0),
          reason: 'care score must be positive after logging a contact',);
    });

    test('acquittement row is persisted and retrievable', () async {
      final friend = makeFriend();
      await friendRepo.insert(friend);

      final entry = makeAcquittement(friendId: friend.id);
      await acquittementRepo.insertAndUpdateCareScore(entry);

      final found = await acquittementRepo.findById(entry.id);
      expect(found, isNotNull);
      expect(found!.friendId, equals(friend.id));
      expect(found.type, equals('call'));
    });

    test('careScore resets high after acquittement (daysSince = 0)', () async {
      // Insert friend with zero care score.
      final friend = makeFriend(careScore: 0.0);
      await friendRepo.insert(friend);

      // Simulate first acquittement.
      await acquittementRepo.insertAndUpdateCareScore(
        makeAcquittement(friendId: friend.id),
      );

      final after = await friendRepo.findById(friend.id);
      expect(after!.careScore, greaterThan(0.0));

      // Score should reflect daysSince = 0 formula result.
      final expected = computeCareScore(daysSinceLastContact: 0);
      expect(after.careScore, closeTo(expected, 1e-9));
    });

    test('recurring-event cadence is used when present', () async {
      final friend = makeFriend();
      await friendRepo.insert(friend);

      // Insert a recurring event with cadence 14 days.
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.eventDao.insertEvent(
        EventsCompanion.insert(
          id: uuid.v4(),
          friendId: friend.id,
          type: 'Regular Check-in',
          date: now,
          createdAt: now,
          isRecurring: const Value(true),
          cadenceDays: const Value(14),
        ),
      );

      await acquittementRepo.insertAndUpdateCareScore(
        makeAcquittement(friendId: friend.id),
      );

      final updated = await friendRepo.findById(friend.id);
      final expectedScore =
          computeCareScore(daysSinceLastContact: 0, expectedIntervalDays: 14);
      expect(updated!.careScore, closeTo(expectedScore, 1e-9));
    });

    test('no crash when friend does not exist (guard path)', () async {
      // Should complete without throwing — acquittement still inserted.
      final orphanEntry = makeAcquittement(friendId: 'nonexistent-id');
      await acquittementRepo.insertAndUpdateCareScore(orphanEntry);
      // If we reach here without an exception, the guard path works.
    });
  });
}
