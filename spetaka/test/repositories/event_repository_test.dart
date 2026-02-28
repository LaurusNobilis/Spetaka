// test/repositories/event_repository_test.dart
//
// Tests Story 3.1 — Add a Dated Event to a Friend Card
//         Story 3.2 — Add a Recurring Check-in Cadence
//
// Coverage:
//   3.1 — addDatedEvent persists with UUID v4 and is_recurring=false
//   3.1 — findByFriendId returns correct event with type/date/comment
//   3.1 — watchByFriendId stream emits on insert
//   3.2 — addRecurringEvent persists with is_recurring=true and cadence_days
//   3.2 — watchAllRecurring returns only recurring events

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/events/data/event_repository.dart';
import 'package:spetaka/features/events/domain/event_type.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uuid = Uuid();

  AppDatabase buildDb() => AppDatabase(NativeDatabase.memory());

  Future<(EncryptionService, AppLifecycleService)> buildEncService() async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    await service.initialize('test-passphrase-3.1');
    return (service, lifecycle);
  }

  /// Inserts a minimal friend into [db] via FriendRepository and returns its id.
  Future<String> seedFriend(AppDatabase db, EncryptionService enc) async {
    final repo = FriendRepository(db: db, encryptionService: enc);
    final now = DateTime.now().millisecondsSinceEpoch;
    final friend = Friend(
      id: uuid.v4(),
      name: 'Alice Test',
      mobile: '+33611111111',
      tags: null,
      notes: null,
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      createdAt: now,
      updatedAt: now,
    );
    await repo.insert(friend);
    return friend.id;
  }

  // ---------------------------------------------------------------------------
  // Story 3.1 — Dated event CRUD
  // ---------------------------------------------------------------------------
  group('EventRepository — Story 3.1 (dated events)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventRepository repo;
    late String friendId;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      repo = EventRepository(db: db);
      friendId = await seedFriend(db, enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('addDatedEvent persists with is_recurring=false and UUID v4', () async {
      final date = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.birthday,
        date: date,
        comment: 'Big day!',
      );

      // UUID v4 format: 8-4-4-4-12 hex groups
      expect(
        id,
        matches(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      );

      final events = await repo.findByFriendId(friendId);
      expect(events.length, 1);

      final e = events.first;
      expect(e.id, id);
      expect(e.friendId, friendId);
      expect(e.type, EventType.birthday.storedName);
      expect(e.date, date);
      expect(e.isRecurring, isFalse);
      expect(e.comment, 'Big day!');
      expect(e.isAcknowledged, isFalse);
      expect(e.acknowledgedAt, isNull);
    });

    test('findByFriendId returns events ordered by date ascending', () async {
      final date1 = DateTime(2026, 12, 25).millisecondsSinceEpoch;
      final date2 = DateTime(2026, 3, 1).millisecondsSinceEpoch;
      await repo.addDatedEvent(
          friendId: friendId, type: EventType.birthday, date: date1,);
      await repo.addDatedEvent(
          friendId: friendId, type: EventType.regularCheckin, date: date2,);

      final events = await repo.findByFriendId(friendId);
      expect(events.length, 2);
      // Earlier date first
      expect(events[0].date, date2);
      expect(events[1].date, date1);
    });

    test('findByFriendId returns empty list for unknown friendId', () async {
      final events = await repo.findByFriendId('nonexistent-id');
      expect(events, isEmpty);
    });

    test('comment is trimmed and null-coerced when blank', () async {
      await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.importantAppointment,
        date: DateTime.now().millisecondsSinceEpoch,
        comment: '   ',
      );
      final events = await repo.findByFriendId(friendId);
      expect(events.first.comment, isNull);
    });

    test('watchByFriendId emits updated list after insert', () async {
      final stream = repo.watchByFriendId(friendId);
      // First emission is empty
      expect(await stream.first, isEmpty);

      await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.weddingAnniversary,
        date: DateTime(2026, 9, 1).millisecondsSinceEpoch,
      );

      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.type, EventType.weddingAnniversary.storedName);
    });
  });

  // ---------------------------------------------------------------------------
  // Story 3.2 — Recurring cadence
  // ---------------------------------------------------------------------------
  group('EventRepository — Story 3.2 (recurring cadence)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventRepository repo;
    late String friendId;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      repo = EventRepository(db: db);
      friendId = await seedFriend(db, enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('addRecurringEvent persists is_recurring=true and cadence_days', () async {
      final date = DateTime(2026, 3, 1).millisecondsSinceEpoch;
      final id = await repo.addRecurringEvent(
        friendId: friendId,
        type: EventType.regularCheckin,
        date: date,
        cadenceDays: 30,
      );

      final events = await repo.findByFriendId(friendId);
      expect(events.length, 1);

      final e = events.first;
      expect(e.id, id);
      expect(e.isRecurring, isTrue);
      expect(e.cadenceDays, 30);
      expect(e.type, EventType.regularCheckin.storedName);
    });

    test('watchAllRecurring returns only recurring events', () async {
      // Insert one one-off and one recurring
      await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.birthday,
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );
      await repo.addRecurringEvent(
        friendId: friendId,
        type: EventType.regularCheckin,
        date: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        cadenceDays: 14,
      );

      final recurring = await repo.watchAllRecurring().first;
      expect(recurring.length, 1);
      expect(recurring.first.isRecurring, isTrue);
      expect(recurring.first.cadenceDays, 14);
    });

    test('all 6 cadence options are accepted', () async {
      for (final days in [7, 14, 21, 30, 60, 90]) {
        final id = await repo.addRecurringEvent(
          friendId: friendId,
          type: EventType.regularCheckin,
          date: DateTime.now().millisecondsSinceEpoch,
          cadenceDays: days,
        );
        final e = (await repo.findByFriendId(friendId))
            .firstWhere((ev) => ev.id == id);
        expect(e.cadenceDays, days);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Story 3.3 — Edit or Delete an Event
  // ---------------------------------------------------------------------------
  group('EventRepository — Story 3.3 (edit / delete)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventRepository repo;
    late String friendId;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      repo = EventRepository(db: db);
      friendId = await seedFriend(db, enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('updateEvent persists new type, date, and comment — AC2', () async {
      final originalDate = DateTime(2026, 5, 1).millisecondsSinceEpoch;
      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.birthday,
        date: originalDate,
        comment: 'old note',
      );

      final newDate = DateTime(2026, 8, 20).millisecondsSinceEpoch;
      await repo.updateEvent(
        id: id,
        friendId: friendId,
        type: EventType.importantAppointment,
        date: newDate,
        isRecurring: false,
        comment: 'updated note',
        isAcknowledged: false,
        createdAt: originalDate, // reuse for this test
      );

      final events = await repo.findByFriendId(friendId);
      expect(events.length, 1);
      final e = events.first;
      expect(e.type, EventType.importantAppointment.storedName);
      expect(e.date, newDate);
      expect(e.comment, 'updated note');
    });

    test('deleteEvent removes the row — AC3/AC4', () async {
      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.regularCheckin,
        date: DateTime.now().millisecondsSinceEpoch,
      );

      final before = await repo.findByFriendId(friendId);
      expect(before.length, 1);

      await repo.deleteEvent(id);

      final after = await repo.findByFriendId(friendId);
      expect(after, isEmpty);
    });

    test('watchByFriendId stream updates reactively after delete — AC4',
        () async {
      final stream = repo.watchByFriendId(friendId);
      // Initial empty
      expect(await stream.first, isEmpty);

      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.birthday,
        date: DateTime(2026, 12, 25).millisecondsSinceEpoch,
      );
      expect((await stream.first).length, 1);

      await repo.deleteEvent(id);
      expect(await stream.first, isEmpty);
    });

    test('updateEvent can convert one-off to recurring', () async {
      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.regularCheckin,
        date: DateTime(2026, 4, 1).millisecondsSinceEpoch,
      );

      await repo.updateEvent(
        id: id,
        friendId: friendId,
        type: EventType.regularCheckin,
        date: DateTime(2026, 4, 1).millisecondsSinceEpoch,
        isRecurring: true,
        cadenceDays: 14,
        isAcknowledged: false,
        createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
      );

      final events = await repo.findByFriendId(friendId);
      expect(events.first.isRecurring, isTrue);
      expect(events.first.cadenceDays, 14);
    });
  });

  // ---------------------------------------------------------------------------
  // Story 3.5 — Manual Event Acknowledgement
  // ---------------------------------------------------------------------------
  group('EventRepository — Story 3.5 (acknowledgement)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventRepository repo;
    late String friendId;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      repo = EventRepository(db: db);
      friendId = await seedFriend(db, enc);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test(
        'acknowledgeEvent sets is_acknowledged=true and acknowledged_at for '
        'one-time event — AC1', () async {
      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.birthday,
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );

      final before = (await repo.findByFriendId(friendId)).first;
      expect(before.isAcknowledged, isFalse);
      expect(before.acknowledgedAt, isNull);

      final tsBefore = DateTime.now().millisecondsSinceEpoch;
      await repo.acknowledgeEvent(id);
      final tsAfter = DateTime.now().millisecondsSinceEpoch + 1;

      final after = (await repo.findByFriendId(friendId)).first;
      expect(after.isAcknowledged, isTrue);
      expect(after.acknowledgedAt, isNotNull);
      expect(after.acknowledgedAt, greaterThanOrEqualTo(tsBefore));
      expect(after.acknowledgedAt, lessThanOrEqualTo(tsAfter));
    });

    test(
        'acknowledgeEvent on recurring event advances date by cadence and '
        'resets acknowledged — AC3', () async {
      final originalDate = DateTime(2026, 3, 1).millisecondsSinceEpoch;
      const cadence = 30; // 30 days
      final id = await repo.addRecurringEvent(
        friendId: friendId,
        type: EventType.regularCheckin,
        date: originalDate,
        cadenceDays: cadence,
      );

      await repo.acknowledgeEvent(id);

      final after = (await repo.findByFriendId(friendId)).first;
      final expectedNextDate =
          originalDate + cadence * Duration.millisecondsPerDay;
      expect(after.date, expectedNextDate);
      expect(after.isAcknowledged, isFalse); // reset
      expect(after.acknowledgedAt, isNull); // reset
    });

    test(
        'acknowledgeEvent on unknown id is a no-op', () async {
      // Should not throw
      await repo.acknowledgeEvent('nonexistent-uuid');
    });

    test(
        'watchByFriendId stream emits acknowledged state reactively — AC2',
        () async {
      final stream = repo.watchByFriendId(friendId);
      expect(await stream.first, isEmpty);

      final id = await repo.addDatedEvent(
        friendId: friendId,
        type: EventType.importantAppointment,
        date: DateTime(2026, 9, 15).millisecondsSinceEpoch,
      );
      final first = await stream.first;
      expect(first.first.isAcknowledged, isFalse);

      await repo.acknowledgeEvent(id);
      final second = await stream.first;
      expect(second.first.isAcknowledged, isTrue);
    });
  });
}

