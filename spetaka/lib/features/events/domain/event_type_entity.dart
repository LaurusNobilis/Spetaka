import 'package:drift/drift.dart';

/// Drift table definition for the `event_types` table.
///
/// Schema introduced in Story 3.4 — Personalize Event Types.
/// Replaces the hardcoded [EventType] enum as the source of truth for
/// event type names shown in pickers and the management screen.
///
/// Columns:
///   id         — UUID v4 primary key
///   name       — Human-readable event type label (e.g. "Birthday")
///   sort_order — Integer for user-defined ordering
///   created_at — Unix-epoch ms creation timestamp
@DataClassName('EventTypeEntry')
class EventTypes extends Table {
  /// UUID v4 primary key generated in Dart at creation time.
  TextColumn get id => text()();

  /// Human-readable event type name (e.g. "Birthday").
  TextColumn get name => text()();

  /// User-defined sort order for display in pickers and management screen.
  IntColumn get sortOrder => integer()();

  /// Creation timestamp (Unix-epoch ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
