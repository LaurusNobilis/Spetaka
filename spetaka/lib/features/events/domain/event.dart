import 'package:drift/drift.dart';

/// Drift table definition for the `events` table.
///
/// Schema introduced in Story 3.1.
/// Timestamps are stored as Unix-epoch milliseconds (INT) throughout.
///
/// Columns follow the data model defined in the PRD / Epic 3:
///   id              — UUID v4 primary key
///   friend_id       — FK to friends.id (cascade handled at repo layer)
///   type            — event type name (see [EventType.storedName])
///   date            — Unix-epoch ms representing the event date
///   is_recurring    — false for one-off dated events (3.1), true for cadence (3.2)
///   comment         — optional free-text note
///   is_acknowledged — whether the user has acknowledged / acquitted this event
///   acknowledged_at — Unix-epoch ms when acknowledged (null if not yet)
///   created_at      — creation timestamp
class Events extends Table {
  /// UUID v4 primary key generated in Dart at creation time.
  TextColumn get id => text()();

  /// References the owning friend card (friends.id).
  TextColumn get friendId => text()();

  /// Event type persisted as a compact name string (see EventType.storedName).
  TextColumn get type => text()();

  /// Event date as Unix-epoch milliseconds.
  IntColumn get date => integer()();

  /// Whether this is a recurring event (cadence set in Story 3.2).
  BoolColumn get isRecurring =>
      boolean().withDefault(const Constant(false))();

  /// Optional free-text comment / note for the event.
  TextColumn get comment => text().nullable()();

  /// Whether the user has manually acknowledged this event.
  BoolColumn get isAcknowledged =>
      boolean().withDefault(const Constant(false))();

  /// Unix-epoch ms timestamp when the event was acknowledged; null if not yet.
  IntColumn get acknowledgedAt => integer().nullable()();

  /// Creation timestamp (Unix-epoch ms).
  IntColumn get createdAt => integer()();

  /// Recurring interval in days (null for one-off events).
  ///
  /// Story 3.2 — added via v4→v5 migration.
  /// Valid values: 7, 14, 21, 30, 60, 90.
  IntColumn get cadenceDays => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
