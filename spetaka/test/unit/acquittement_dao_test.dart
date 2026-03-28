import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';

void main() {
  group('AcquittementDao.maxCreatedAtByFriendId', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns the latest timestamp for each friend', () async {
      await db.into(db.friends).insert(
        FriendsCompanion.insert(
          id: 'f1',
          name: 'Alice',
          mobile: '+33600000001',
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      await db.into(db.friends).insert(
        FriendsCompanion.insert(
          id: 'f2',
          name: 'Bob',
          mobile: '+33600000002',
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      await db.into(db.acquittements).insert(
        AcquittementsCompanion.insert(
          id: 'a1',
          friendId: 'f1',
          type: 'call',
          createdAt: 100,
        ),
      );
      await db.into(db.acquittements).insert(
        AcquittementsCompanion.insert(
          id: 'a2',
          friendId: 'f1',
          type: 'sms',
          createdAt: 300,
        ),
      );
      await db.into(db.acquittements).insert(
        AcquittementsCompanion.insert(
          id: 'a3',
          friendId: 'f2',
          type: 'sms',
          createdAt: 200,
        ),
      );

      final result = await db.acquittementDao.maxCreatedAtByFriendId();

      expect(result, equals({'f1': 300, 'f2': 200}));
    });

    test('watchMaxCreatedAtByFriend re-emits when acquittements change',
        () async {
      final emissionsFuture = db.acquittementDao
          .watchMaxCreatedAtByFriend()
          .take(3)
          .toList();

      await Future<void>.delayed(Duration.zero);

      await db.into(db.acquittements).insert(
        AcquittementsCompanion.insert(
          id: 'a1',
          friendId: 'f1',
          type: 'call',
          createdAt: 100,
        ),
      );

      await db.into(db.acquittements).insert(
        AcquittementsCompanion.insert(
          id: 'a2',
          friendId: 'f1',
          type: 'sms',
          createdAt: 300,
        ),
      );

      final emissions = await emissionsFuture;

      expect(emissions[0], isEmpty);
      expect(emissions[1], equals({'f1': 100}));
      expect(emissions[2], equals({'f1': 300}));
    });
  });
}