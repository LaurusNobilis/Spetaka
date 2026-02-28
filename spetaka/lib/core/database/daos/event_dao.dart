import 'package:drift/drift.dart';

import '../../../features/events/domain/event.dart';
import '../app_database.dart';

part 'event_dao.g.dart';

/// DAO for Event entity persistence.
///
/// Table: [Events] — schema introduced in Story 3.1.
/// Encryption is NOT applied to event fields (no sensitive data per spec).
@DriftAccessor(tables: [Events])
class EventDao extends DatabaseAccessor<AppDatabase> with _$EventDaoMixin {
  EventDao(super.db);

  /// Inserts a new event row. Returns the SQLite rowid.
  Future<int> insertEvent(Insertable<Event> entry) =>
      into(events).insert(entry);

  /// Returns all events for a given [friendId], ordered by date ascending.
  Future<List<Event>> findByFriendId(String friendId) =>
      (select(events)
            ..where((e) => e.friendId.equals(friendId))
            ..orderBy([(e) => OrderingTerm.asc(e.date)]))
          .get();

  /// Watches all events for a given [friendId]; emits on every database change.
  Stream<List<Event>> watchByFriendId(String friendId) =>
      (select(events)
            ..where((e) => e.friendId.equals(friendId))
            ..orderBy([(e) => OrderingTerm.asc(e.date)]))
          .watch();

  /// Returns a single event by [id], or null if absent.
  Future<Event?> findById(String id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Replaces the existing event row identified by the companion's primary key.
  Future<bool> updateEvent(Insertable<Event> entry) =>
      update(events).replace(entry);

  /// Deletes the event row with [id]. Returns the number of rows deleted.
  Future<int> deleteEvent(String id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  /// Deletes all events for a given [friendId] (used on friend cascade delete).
  Future<int> deleteByFriendId(String friendId) =>
      (delete(events)..where((e) => e.friendId.equals(friendId))).go();

  /// Returns all recurring events (is_recurring=true) across all friends.
  ///
  /// Exposed for the priority engine stream (Story 3.2 AC5).
  Stream<List<Event>> watchAllRecurring() =>
      (select(events)..where((e) => e.isRecurring.equals(true))).watch();

  /// Watches all events relevant to priority computation:
  ///   - recurring events (always in scope)
  ///   - one-time events that are NOT yet acknowledged
  ///
  /// Story 3.5 AC4: priority engine excludes acknowledged one-time events.
  Stream<List<Event>> watchPriorityInputEvents() {
    return (select(events)
          ..where(
            (e) => e.isRecurring.equals(true) |
                (e.isRecurring.equals(false) &
                    e.isAcknowledged.equals(false)),
          ))
        .watch();
  }

    /// Renames the persisted event type string in existing events.
    ///
    /// Used by Story 3.4 rename flow so historical events keep a consistent label
    /// after the event type is renamed. Matching is case-insensitive to support
    /// legacy lowercase enum names.
    Future<int> renameTypeInEventsCaseInsensitive({
        required String oldTypeName,
        required String newTypeName,
    }) async {
        if (oldTypeName.trim().isEmpty || newTypeName.trim().isEmpty) return 0;
        if (oldTypeName.toLowerCase() == newTypeName.toLowerCase()) return 0;
        return attachedDatabase.customUpdate(
            'UPDATE events '
            'SET type = ? '
            'WHERE lower(type) = lower(?)',
            variables: [
                Variable.withString(newTypeName),
                Variable.withString(oldTypeName),
            ],
            updates: {events},
        );
    }
}
