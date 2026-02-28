import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase foundation', () {
    test('in-memory database opens successfully', () async {
      // Force the database to open by running a trivial query.
      final result = await db.customSelect('SELECT 1 AS v').getSingle();
      expect(result.data['v'], equals(1));
    });

    test('schemaVersion is 4 (bumped by Story 3.1 — events table)', () {
      expect(db.schemaVersion, equals(4));
    });

    test('MigrationStrategy declares an onUpgrade hook', () {
      final strategy = db.migration;
      expect(
        strategy.onUpgrade,
        isNotNull,
        reason: 'onUpgrade must be defined for future schema migrations',
      );
    });

    test('MigrationStrategy declares a beforeOpen hook', () {
      final strategy = db.migration;
      expect(
        strategy.beforeOpen,
        isNotNull,
        reason: 'beforeOpen must be defined (enforces FK pragma)',
      );
    });

    test('PRAGMA foreign_keys is ON after open', () async {
      // Force open first
      await db.customSelect('SELECT 1').getSingle();
      final rows =
          await db.customSelect('PRAGMA foreign_keys').get();
      expect(rows.first.data['foreign_keys'], equals(1));
    });
  });
}
