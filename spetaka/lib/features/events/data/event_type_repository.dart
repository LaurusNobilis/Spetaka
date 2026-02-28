import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

/// Repository for EventType CRUD operations.
///
/// Story 3.4 — Personalize Event Types.
/// The repository is the single place to create/read/update/delete/reorder
/// event types and wraps the underlying [EventTypeDao].
class EventTypeRepository {
  EventTypeRepository({required this.db});

  final AppDatabase db;

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Watches all event types ordered by `sort_order` ascending.
  ///
  /// Used by pickers (Add/Edit Event) and the management screen.
  Stream<List<EventTypeEntry>> watchAll() => db.eventTypeDao.watchAll();

  /// Returns all event types ordered by `sort_order` ascending.
  Future<List<EventTypeEntry>> getAll() => db.eventTypeDao.getAll();

  /// Adds a new event type with [name].
  ///
  /// `sort_order` is set to max+1 so the new type appears at the end.
  /// Returns the generated UUID.
  Future<String> addEventType(String name) async {
    final all = await db.eventTypeDao.getAll();
    final maxSort = all.isEmpty ? -1 : all.last.sortOrder;
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.eventTypeDao.insertEventType(
      EventTypesCompanion.insert(
        id: id,
        name: name.trim(),
        sortOrder: maxSort + 1,
        createdAt: now,
      ),
    );
    return id;
  }

  /// Renames the event type with [id] to [newName].
  Future<bool> rename(String id, String newName) =>
      db.eventTypeDao.updateName(id, newName.trim());

  /// Deletes the event type with [id].
  ///
  /// Caller should check [countEventsByType] first to warn the user (AC4).
  Future<int> deleteById(String id) => db.eventTypeDao.deleteById(id);

  /// Persists a custom sort order.
  ///
  /// [orderedIds] — list of event type IDs in the desired display order.
  Future<void> reorder(List<String> orderedIds) =>
      db.eventTypeDao.updateSortOrders(orderedIds);

  /// Counts how many events reference [typeName] (for delete-warning).
  Future<int> countEventsByType(String typeName) =>
      db.eventTypeDao.countEventsByType(typeName);
}
