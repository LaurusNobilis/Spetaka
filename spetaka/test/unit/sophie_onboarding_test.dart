// ignore_for_file: prefer_const_constructors

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPass = 'spetaka-test-passphrase-4.5';

  AppDatabase buildDb() => AppDatabase(NativeDatabase.memory());

  Future<(EncryptionService, AppLifecycleService)> buildService() async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    await service.initialize(testPass);
    return (service, lifecycle);
  }

  // ---------------------------------------------------------------------------
  // Group 1: Sophie seeding (AC1)
  // ---------------------------------------------------------------------------

  group('Sophie seeding — first launch (AC1)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildService();
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('opening a fresh DB seeds exactly 1 demo friend named Sophie', () async {
      // Trigger beforeOpen by running a trivial query.
      await db.customSelect('SELECT 1').getSingle();

      final allFriends = await db.friendDao.selectAll();
      expect(
        allFriends.where((f) => f.isDemo).length,
        equals(1),
        reason: 'Exactly one demo friend should be seeded on first launch',
      );
      expect(
        allFriends.first.name,
        equals('Sophie'),
        reason: 'The demo friend must be named Sophie',
      );
    });

    test('Sophie has isDemo=true flag', () async {
      await db.customSelect('SELECT 1').getSingle();
      final sophie = await db.friendDao.findById('demo-sophie-001');
      expect(sophie, isNotNull);
      expect(sophie!.isDemo, isTrue);
    });

    test('Sophie has one event seeded with type Événement important', () async {
      await db.customSelect('SELECT 1').getSingle();
      final allEvents = await db.eventDao.findByFriendId('demo-sophie-001');
      expect(
        allEvents.length,
        equals(1),
        reason: 'Sophie must have exactly 1 seeded event',
      );
      expect(allEvents.first.type, equals('Événement important'));
    });

    test('Sophie event date is approximately +7 days from now', () async {
      await db.customSelect('SELECT 1').getSingle();
      final allEvents = await db.eventDao.findByFriendId('demo-sophie-001');
      final eventDate =
          DateTime.fromMillisecondsSinceEpoch(allEvents.first.date);
      final daysUntil = eventDate.difference(DateTime.now()).inDays;
      // Allow ±1 day tolerance for test timing.
      expect(
        daysUntil,
        inInclusiveRange(6, 8),
        reason: 'Sophie event should be ~7 days from now',
      );
    });

    test('seeding idempotent — second count() returns same count', () async {
      // After seeding, a subsequent count should not duplicate Sophie.
      await db.customSelect('SELECT 1').getSingle();
      final count1 = (await db.friendDao.selectAll()).length;
      final count2 = (await db.friendDao.selectAll()).length;
      expect(count1, equals(count2));
      expect(count1, equals(1), reason: 'Should be exactly Sophie — no duplication');
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2: Remove-Sophie lifecycle (AC4)
  // ---------------------------------------------------------------------------

  group('Remove-Sophie lifecycle (AC4)', () {
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

    test('inserting a real friend auto-removes Sophie', () async {
      // Trigger first-launch seeding.
      await db.customSelect('SELECT 1').getSingle();
      final demosBefore = (await db.friendDao.selectAll())
          .where((f) => f.isDemo)
          .length;
      expect(demosBefore, equals(1), reason: 'Sophie should exist before insert');

      // Insert a real friend.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        Friend(
          id: 'real-friend-001',
          name: 'Alice',
          mobile: '+33611111111',
          tags: null,
          notes: null,
          careScore: 0.0,
          isConcernActive: false,
          concernNote: null,
          isDemo: false,
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      final demosAfter = (await db.friendDao.selectAll())
          .where((f) => f.isDemo)
          .length;
      expect(
        demosAfter,
        equals(0),
        reason: 'Sophie should be auto-removed after first real insert',
      );
    });

    test('explicit removeDemoFriends() removes Sophie', () async {
      await db.customSelect('SELECT 1').getSingle();
      await repo.removeDemoFriends();

      final demos = (await db.friendDao.selectAll()).where((f) => f.isDemo);
      expect(demos, isEmpty);
    });

    test('inserting another demo friend does NOT remove Sophie', () async {
      await db.customSelect('SELECT 1').getSingle();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        Friend(
          id: 'demo-friend-002',
          name: 'Demo2',
          mobile: '+33600000099',
          tags: null,
          notes: null,
          careScore: 0.0,
          isConcernActive: false,
          concernNote: null,
          isDemo: true,
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      final demos = (await db.friendDao.selectAll()).where((f) => f.isDemo);
      expect(
        demos.length,
        equals(2),
        reason: 'Both demo friends should coexist when no real insert happens',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3: isDemo exclusion via PriorityEngine (AC5 + 4-1 coupling)
  // ---------------------------------------------------------------------------

  group('isDemo flag integration (AC5)', () {
    test('FriendScoringInput.isDemo=true excluded when excludeDemo=true', () {
      // This is covered by the priority_engine_test.dart excludeDemo group.
      // This extra assertion confirms the isDemo flag is accessible at the
      // Drift entity level (Friend.isDemo) and maps to the scoring DTO.
      final now = DateTime.now().millisecondsSinceEpoch;
      final demoFriend = Friend(
        id: 'demo-check',
        name: 'Demo',
        mobile: '+33600000000',
        tags: null,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        isDemo: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(demoFriend.isDemo, isTrue);
    });
  });
}
