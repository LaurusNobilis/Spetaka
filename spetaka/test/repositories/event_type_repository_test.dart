// test/repositories/event_type_repository_test.dart
//
// Tests Story 3.4 — Personalize Event Types
//
// Coverage:
//   3.4 AC1 — Default types are seeded when table is empty
//   3.4 AC2 — Add a new event type with sort_order = max+1
//   3.4 AC3 — Rename an existing event type
//   3.4 AC4 — Delete with usage-count warning
//   3.4 AC5 — Reorder persists sort_order
//   3.4 AC1 — Verify 5 defaults in dedicated event_types table

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/events/data/event_repository.dart';
import 'package:spetaka/features/events/data/event_type_repository.dart';
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
    await service.initialize('test-passphrase-3.4');
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
  // AC1 — Default types seeded in SQLite
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — AC1 (default seeding)', () {
    late AppDatabase db;
    late EventTypeRepository repo;

    setUp(() async {
      db = buildDb();
      repo = EventTypeRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('5 default event types are seeded on first open', () async {
      final types = await repo.getAll();
      expect(types.length, 5);

      final names = types.map((t) => t.name).toList();
      expect(names, [
        'Birthday',
        'Wedding Anniversary',
        'Important Life Event',
        'Regular Check-in',
        'Important Appointment',
      ]);
    });

    test('default types have sort_order 0-4', () async {
      final types = await repo.getAll();
      for (var i = 0; i < types.length; i++) {
        expect(types[i].sortOrder, i);
      }
    });

    test('default types have deterministic IDs', () async {
      final types = await repo.getAll();
      expect(types[0].id, 'default-birthday');
      expect(types[1].id, 'default-wedding-anniversary');
      expect(types[4].id, 'default-important-appointment');
    });

    test('watchAll emits the seeded list', () async {
      final types = await repo.watchAll().first;
      expect(types.length, 5);
      expect(types.first.name, 'Birthday');
    });
  });

  // ---------------------------------------------------------------------------
  // AC2 — Add a new event type
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — AC2 (add)', () {
    late AppDatabase db;
    late EventTypeRepository repo;

    setUp(() async {
      db = buildDb();
      repo = EventTypeRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('addEventType inserts with sort_order = max+1', () async {
      final id = await repo.addEventType('Graduation');
      expect(id, isNotEmpty);

      final types = await repo.getAll();
      expect(types.length, 6); // 5 defaults + 1
      expect(types.last.name, 'Graduation');
      expect(types.last.sortOrder, 5); // 0-4 defaults, then 5
    });

    test('name is trimmed on add', () async {
      await repo.addEventType('  Vacation  ');
      final types = await repo.getAll();
      expect(types.last.name, 'Vacation');
    });

    test('watchAll stream updates reactively after add', () async {
      final stream = repo.watchAll();
      // Initial: 5 defaults
      expect((await stream.first).length, 5);

      await repo.addEventType('Custom Type');
      final updated = await stream.first;
      expect(updated.length, 6);
      expect(updated.last.name, 'Custom Type');
    });
  });

  // ---------------------------------------------------------------------------
  // AC3 — Rename an existing event type
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — AC3 (rename)', () {
    late AppDatabase db;
    late EventTypeRepository repo;

    setUp(() async {
      db = buildDb();
      repo = EventTypeRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('rename updates the name column', () async {
      final types = await repo.getAll();
      final birthday = types.first;
      expect(birthday.name, 'Birthday');

      final result = await repo.rename(birthday.id, 'Anniversaire');
      expect(result, isTrue);

      final updated = await repo.getAll();
      expect(updated.first.name, 'Anniversaire');
    });

    test('rename trims whitespace', () async {
      final types = await repo.getAll();
      await repo.rename(types.first.id, '  New Name  ');
      final updated = await repo.getAll();
      expect(updated.first.name, 'New Name');
    });
  });

  // ---------------------------------------------------------------------------
  // Rename propagation — keep historical events consistent
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — rename propagation', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventTypeRepository typeRepo;
    late EventRepository eventRepo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      typeRepo = EventTypeRepository(db: db);
      eventRepo = EventRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('rename updates existing events type string (case-insensitive)',
        () async {
      final friendId = await seedFriend(db, enc);

      // Legacy type stored in lowercase.
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'birthday',
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );

      final types = await typeRepo.getAll();
      final birthday = types.firstWhere((t) => t.name == 'Birthday');

      final renamed = await typeRepo.rename(birthday.id, 'Bday');
      expect(renamed, isTrue);

      final events = await eventRepo.findByFriendId(friendId);
      expect(events.length, 1);
      expect(events.first.type, 'Bday');

      // Usage count should now reflect the new name.
      final count = await typeRepo.countEventsByType('Bday');
      expect(count, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // AC4 — Delete with usage count warning
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — AC4 (delete)', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventTypeRepository typeRepo;
    late EventRepository eventRepo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      typeRepo = EventTypeRepository(db: db);
      eventRepo = EventRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('deleteById removes the event type', () async {
      final types = await typeRepo.getAll();
      expect(types.length, 5);

      await typeRepo.deleteById(types.last.id);

      final updated = await typeRepo.getAll();
      expect(updated.length, 4);
    });

    test('countEventsByType returns 0 when no events reference it', () async {
      final count = await typeRepo.countEventsByType('Birthday');
      expect(count, 0);
    });

    test('countEventsByType returns correct count for referenced type',
        () async {
      final friendId = await seedFriend(db, enc);

      // Insert 2 events with type "Birthday"
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'Birthday',
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'Birthday',
        date: DateTime(2027, 6, 1).millisecondsSinceEpoch,
      );
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'Wedding Anniversary',
        date: DateTime(2026, 9, 1).millisecondsSinceEpoch,
      );

      final birthdayCount = await typeRepo.countEventsByType('Birthday');
      expect(birthdayCount, 2);

      final weddingCount =
          await typeRepo.countEventsByType('Wedding Anniversary');
      expect(weddingCount, 1);
    });

    test('delete does not cascade to events (orphan handling)', () async {
      final friendId = await seedFriend(db, enc);
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'Birthday',
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );

      final types = await typeRepo.getAll();
      final birthday = types.firstWhere((t) => t.name == 'Birthday');
      await typeRepo.deleteById(birthday.id);

      // Event still exists with its type string intact (orphan)
      final events = await eventRepo.findByFriendId(friendId);
      expect(events.length, 1);
      expect(events.first.type, 'Birthday');
    });
  });

  // ---------------------------------------------------------------------------
  // AC5 — Reorder via drag-and-drop
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — AC5 (reorder)', () {
    late AppDatabase db;
    late EventTypeRepository repo;

    setUp(() async {
      db = buildDb();
      repo = EventTypeRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('reorder persists new sort_order values', () async {
      final types = await repo.getAll();
      // Reverse the order
      final reversed = types.reversed.map((t) => t.id).toList();
      await repo.reorder(reversed);

      final updated = await repo.getAll();
      // First should now be the former last
      expect(updated.first.name, 'Important Appointment');
      expect(updated.last.name, 'Birthday');
    });

    test('reorder maintains sort_order after getAll', () async {
      final types = await repo.getAll();
      // Move "Regular Check-in" (index 3) to first position
      final ids = types.map((t) => t.id).toList();
      final moved = ids.removeAt(3);
      ids.insert(0, moved);
      await repo.reorder(ids);

      final updated = await repo.getAll();
      expect(updated[0].name, 'Regular Check-in');
      expect(updated[0].sortOrder, 0);
      expect(updated[1].name, 'Birthday');
      expect(updated[1].sortOrder, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Validation guards (review fix [LOW] #6)
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — validation guards', () {
    late AppDatabase db;
    late EventTypeRepository repo;

    setUp(() async {
      db = buildDb();
      repo = EventTypeRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('addEventType rejects empty name', () async {
      expect(
        () => repo.addEventType(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.addEventType('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addEventType rejects case-insensitive duplicate', () async {
      // "Birthday" already seeded
      expect(
        () => repo.addEventType('birthday'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.addEventType('BIRTHDAY'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rename rejects empty name', () async {
      final types = await repo.getAll();
      expect(
        () => repo.rename(types.first.id, ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rename rejects case-insensitive duplicate of another type', () async {
      final types = await repo.getAll();
      // Try renaming first type to match second type
      expect(
        () => repo.rename(types.first.id, 'wedding anniversary'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rename allows same name with different case (self)', () async {
      final types = await repo.getAll();
      // Renaming "Birthday" to "birthday" for the same entry should succeed
      final result = await repo.rename(types.first.id, 'BIRTHDAY');
      expect(result, isTrue);
      final updated = await repo.getAll();
      expect(updated.first.name, 'BIRTHDAY');
    });
  });

  // ---------------------------------------------------------------------------
  // Case-insensitive countEventsByType (review fix [HIGH] #2)
  // ---------------------------------------------------------------------------
  group('EventTypeRepository — case-insensitive count', () {
    late AppDatabase db;
    late EncryptionService enc;
    late AppLifecycleService lifecycle;
    late EventTypeRepository typeRepo;
    late EventRepository eventRepo;

    setUp(() async {
      db = buildDb();
      (enc, lifecycle) = await buildEncService();
      typeRepo = EventTypeRepository(db: db);
      eventRepo = EventRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    test('countEventsByType matches case-insensitively', () async {
      final friendId = await seedFriend(db, enc);

      // Insert events with legacy lowercase type names
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'birthday',
        date: DateTime(2026, 6, 1).millisecondsSinceEpoch,
      );
      await eventRepo.addDatedEvent(
        friendId: friendId,
        type: 'Birthday',
        date: DateTime(2027, 6, 1).millisecondsSinceEpoch,
      );

      // Query with Title Case — should find both
      final count = await typeRepo.countEventsByType('Birthday');
      expect(count, 2);

      // Query with lowercase — should also find both
      final countLower = await typeRepo.countEventsByType('birthday');
      expect(countLower, 2);
    });
  });
}
