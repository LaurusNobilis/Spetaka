import 'package:drift/drift.dart';

import '../../../features/events/domain/event_type_entity.dart';
import '../app_database.dart';

part 'event_type_dao.g.dart';

/// DAO for EventType entity persistence.
///
/// Table: [EventTypes] — schema introduced in Story 3.4.
/// Provides CRUD + reorder + usage-count operations for event types.
@DriftAccessor(tables: [EventTypes])
class EventTypeDao extends DatabaseAccessor<AppDatabase>
    with _$EventTypeDaoMixin {
  EventTypeDao(super.db);

  /// Inserts a new event type row. Returns the SQLite rowid.
  Future<int> insertEventType(Insertable<EventTypeEntry> entry) =>
      into(eventTypes).insert(entry);

  /// Watches all event types ordered by [sortOrder] ascending.
  Stream<List<EventTypeEntry>> watchAll() =>
      (select(eventTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  /// Returns all event types ordered by [sortOrder] ascending.
  Future<List<EventTypeEntry>> getAll() =>
      (select(eventTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Updates the name of an event type by [id].
  Future<bool> updateName(String id, String newName) =>
      (update(eventTypes)..where((t) => t.id.equals(id)))
          .write(EventTypesCompanion(name: Value(newName)))
          .then((rows) => rows > 0);

  /// Deletes the event type with [id]. Returns the number of rows deleted.
  Future<int> deleteById(String id) =>
      (delete(eventTypes)..where((t) => t.id.equals(id))).go();

  /// Batch-updates sort orders for an ordered list of event type IDs.
  ///
  /// [orderedIds] — list of event type IDs in the desired display order.
  /// Each ID gets `sort_order = index` in the list.
  Future<void> updateSortOrders(List<String> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(eventTypes)..where((t) => t.id.equals(orderedIds[i])))
            .write(EventTypesCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// Counts events in the `events` table that reference [typeName].
  ///
  /// Used for the delete-warning dialog (AC4): "X events use this type".
  Future<int> countEventsByType(String typeName) async {
    final query = attachedDatabase.selectOnly(attachedDatabase.events)
      ..addColumns([attachedDatabase.events.id.count()])
      ..where(attachedDatabase.events.type.equals(typeName));
    final result = await query.getSingle();
    return result.read(attachedDatabase.events.id.count()) ?? 0;
  }
}
