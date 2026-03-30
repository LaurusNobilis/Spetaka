import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/acquittement/domain/acquittement.dart';
import '../../features/events/domain/event.dart';
import '../../features/events/domain/event_type_entity.dart';
import '../../features/friends/domain/friend.dart';
import '../../features/voice_profile/domain/user_voice_profile.dart';
import 'daos/acquittement_dao.dart';
import 'daos/event_dao.dart';
import 'daos/event_type_dao.dart';
import 'daos/friend_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/user_voice_profile_dao.dart';

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
    EventTypes, // Story 3.4 — personalized event types
    UserVoiceProfiles, // Story 10.6 — on-device learning style vectors
  ],
  daos: [FriendDao, EventDao, EventTypeDao, AcquittementDao, SettingsDao, UserVoiceProfileDao],
)
class AppDatabase extends _$AppDatabase {
  /// Primary constructor.  If [executor] is omitted the production on-disk
  /// database is opened via [_openConnection].  Pass a [NativeDatabase.memory()]
  /// (or any other [QueryExecutor]) in tests to get an isolated in-memory DB.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

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
          // Story 3.4 — v5→v6: create event_types table.
          if (from < 6) {
            await m.createTable(eventTypes);
          }
          // Story 4.5 — v6→v7: add friends.is_demo column.
          // On fresh install (from=0), createTable(friends) already includes it.
          if (from == 6) {
            await m.addColumn(friends, friends.isDemo);
          }
          // i18n — v7→v8: rename English event-type entries to French in both
          // the event_types table and the events.type column.
          // Also inserts 'Anniversaire' (Birthday) which was accidentally omitted
          // from the v7 French-only seed.
          if (from < 8) {
            const renames = {
              'Birthday': 'Anniversaire',
              'Wedding Anniversary': 'Anniversaire de mariage',
              'Important Life Event': 'Événement important',
              'Regular Check-in': 'Appel de suivi',
              'Important Appointment': 'Rendez-vous important',
            };
            for (final entry in renames.entries) {
              await customStatement(
                'UPDATE event_types SET name = ? WHERE name = ?',
                [entry.value, entry.key],
              );
              await customStatement(
                'UPDATE events SET type = ? WHERE type = ?',
                [entry.value, entry.key],
              );
            }
            // Add 'Anniversaire' if not already present (covers both the
            // fresh-v7 install that had a 4-item French seed and upgrades
            // from English that had 'Birthday' just renamed above).
            final rows = await customSelect(
              "SELECT 1 FROM event_types WHERE name = 'Anniversaire' LIMIT 1",
            ).get();
            if (rows.isEmpty) {
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              await customStatement(
                'INSERT OR IGNORE INTO event_types (id, name, sort_order, created_at) VALUES (?, ?, ?, ?)',
                ['default-anniversaire', 'Anniversaire', -1, nowMs],
              );
            }
          }

          // Naming update — v8→v9: change 2 default event-type labels.
          // - 'Anniversaire' → 'Autre'
          // - 'Appel de suivi' → 'Prendre des nouvelles'
          // Applies to both `event_types.name` and `events.type`.
          if (from < 9) {
            const renames = {
              'Anniversaire': 'Autre',
              'Appel de suivi': 'Prendre des nouvelles',
            };
            for (final entry in renames.entries) {
              await customStatement(
                'UPDATE event_types SET name = ? WHERE name = ?',
                [entry.value, entry.key],
              );
              await customStatement(
                'UPDATE events SET type = ? WHERE type = ?',
                [entry.value, entry.key],
              );
            }

            // Ensure 'Autre' exists as a selectable type (in case the user
            // deleted it, or the install pre-dated the default seed fix).
            final rows = await customSelect(
              "SELECT 1 FROM event_types WHERE name = 'Autre' LIMIT 1",
            ).get();
            if (rows.isEmpty) {
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              await customStatement(
                'INSERT OR IGNORE INTO event_types (id, name, sort_order, created_at) VALUES (?, ?, ?, ?)',
                ['default-autre', 'Autre', -1, nowMs],
              );
            }
          }

          // Story 10.6 — v9→v10: create user_voice_profiles table (singleton).
          if (from < 10) {
            await m.createTable(userVoiceProfiles);
          }
        },
        beforeOpen: (details) async {
          // Enable foreign-key enforcement on every connection open.
          await customStatement('PRAGMA foreign_keys = ON');

          // Story 3.4 AC1: Seed default event types when table is empty.
          final count = await eventTypes.count().getSingle();
          if (count == 0) {
            final now = DateTime.now().millisecondsSinceEpoch;
            const defaults = [
              'Autre',
              'Anniversaire de mariage',
              'Événement important',
              'Prendre des nouvelles',
              'Rendez-vous important',
            ];
            for (var i = 0; i < defaults.length; i++) {
              await into(eventTypes).insert(
                EventTypesCompanion.insert(
                  id: 'default-${defaults[i].toLowerCase().replaceAll(' ', '-')}',
                  name: defaults[i],
                  sortOrder: i,
                  createdAt: now,
                ),
              );
            }
          }
          // Story 4.5 AC1: Seed demo friend "Sophie" when friends table is empty.
          // This covers first-launch only — once any friend (real or demo) exists,
          // Sophie is not re-seeded.
          final friendCount = await friends.count().getSingle();
          if (friendCount == 0) {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            const sophieId = 'demo-sophie-001';
            const sophieEventId = 'demo-sophie-event-001';
            await into(friends).insert(
              FriendsCompanion.insert(
                id: sophieId,
                name: 'Sophie',
                mobile: '+33600000000',
                isDemo: const Value(true),
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );
            final eventDateMs = DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch;
            await into(events).insert(
              EventsCompanion.insert(
                id: sophieEventId,
                friendId: sophieId,
                type: 'Événement important',
                date: eventDateMs,
                createdAt: nowMs,
              ),
            );
          }
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
