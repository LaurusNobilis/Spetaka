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
  /// Throws [ArgumentError] if [name] is empty after trimming, or if a
  /// type with the same name already exists (case-insensitive).
  /// Returns the generated UUID.
  Future<String> addEventType(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Event type name must not be empty');
    }
    final all = await db.eventTypeDao.getAll();
    final duplicate = all.any(
      (t) => t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw ArgumentError.value(
        name, 'name', 'An event type with this name already exists',
      );
    }
    final maxSort = all.isEmpty ? -1 : all.last.sortOrder;
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.eventTypeDao.insertEventType(
      EventTypesCompanion.insert(
        id: id,
        name: trimmed,
        sortOrder: maxSort + 1,
        createdAt: now,
      ),
    );
    return id;
  }

  /// Renames the event type with [id] to [newName].
  ///
  /// Throws [ArgumentError] if [newName] is empty after trimming, or if another
  /// type already has the same name (case-insensitive).
  Future<bool> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(newName, 'newName', 'Event type name must not be empty');
    }
    final all = await db.eventTypeDao.getAll();
    final current = all.where((t) => t.id == id).firstOrNull;
    final duplicate = all.any(
      (t) => t.id != id && t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw ArgumentError.value(
        newName, 'newName', 'An event type with this name already exists',
      );
    }
    final renamed = await db.eventTypeDao.updateName(id, trimmed);
    if (renamed && current != null) {
      await db.eventDao.renameTypeInEventsCaseInsensitive(
        oldTypeName: current.name,
        newTypeName: trimmed,
      );
    }
    return renamed;
  }

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
