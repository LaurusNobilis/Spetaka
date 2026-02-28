import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/acquittement/domain/acquittement.dart';
import '../../features/events/domain/event.dart';
import '../../features/friends/domain/friend.dart';
import 'daos/acquittement_dao.dart';
import 'daos/event_dao.dart';
import 'daos/friend_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

/// Central Drift database for Spetaka.
///
/// Tables are added story-by-story. Each epic introduces its table definitions
/// + the corresponding DAO methods.
///
/// Timestamps are stored as Unix-epoch milliseconds (INT) throughout the
/// schema to keep SQL comparisons simple and timezone-independent.
@DriftDatabase(
  tables: [
    Friends, // Story 1.7 — field encryption infrastructure
    Acquittements, // Story 1.7 — field encryption infrastructure
    Events, // Story 3.1 — dated events on friend cards
  ],
  daos: [FriendDao, EventDao, AcquittementDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Primary constructor.  If [executor] is omitted the production on-disk
  /// database is opened via [_openConnection].  Pass a [NativeDatabase.memory()]
  /// (or any other [QueryExecutor]) in tests to get an isolated in-memory DB.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  /// Returns the [MigrationStrategy] used by Drift on every open / upgrade.
  ///
  /// `onUpgrade` accumulates step-based migrations as new epics introduce tables.
  /// `beforeOpen` enables SQLite foreign-key enforcement on every connection.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // Story 1.7 — v1→v2: introduce friends and acquittements tables.
          if (from < 2) {
            await m.createTable(friends);
            await m.createTable(acquittements);
          }
          // Story 2.3 — v2→v3: add friends.tags column.
          // Guardrail: on a fresh install Drift may upgrade from 0→3 and the
          // createTable(friends) path above will already include the new column.
          // In that case, calling addColumn would be redundant and can fail.
          if (from == 2) {
            await m.addColumn(friends, friends.tags);
          }
          // Story 3.1 — v3→v4: create events table.
          if (from < 4) {
            await m.createTable(events);
          }
          // Story 3.2 — v4→v5: add events.cadence_days column.
          // On fresh install (from=0), createTable already includes the column.
          if (from == 4) {
            await m.addColumn(events, events.cadenceDays);
          }
          // Add future migrations here as new columns/tables are introduced.
        },
        beforeOpen: (details) async {
          // Enable foreign-key enforcement on every connection open.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Opens the production on-disk SQLite database stored in the app documents
/// directory.  Uses [NativeDatabase.createInBackground] for off-main-thread I/O.
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'spetaka.db'));
      return NativeDatabase.createInBackground(file);
    } catch (e, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'AppDatabase',
          context: ErrorDescription(
            'Failed to open the Spetaka database. '
            'Check that the app has storage permissions and the '
            'application documents directory is accessible.',
          ),
        ),
      );
      rethrow;
    }
  });
}

/// Riverpod provider that exposes [AppDatabase] to the widget tree.
///
/// The database is closed automatically when the provider is disposed
/// (e.g. when the [ProviderScope] containing it is removed).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
