import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

/// Repository for Event CRUD operations.
///
/// Events are not encrypted (no sensitive narrative data).
/// The repository is the single place to create/read/update/delete events
/// and handles UUID generation and timestamp management.
class EventRepository {
  EventRepository({required this.db});

  final AppDatabase db;

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Creates and persists a one-off dated event.
  ///
  /// [friendId] — owning friend card UUID
  /// [type]     — event type name string (dynamic from event_types table)
  /// [date]     — Unix epoch ms for the event date
  /// [comment]  — optional free-text note
  ///
  /// Returns the generated UUID for the new event.
  Future<String> addDatedEvent({
    required String friendId,
    required String type,
    required int date,
    String? comment,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.eventDao.insertEvent(
      EventsCompanion.insert(
        id: id,
        friendId: friendId,
        type: type,
        date: date,
        isRecurring: const Value(false),
        comment: Value(comment?.trim().isEmpty == true ? null : comment?.trim()),
        isAcknowledged: const Value(false),
        createdAt: now,
      ),
    );
    return id;
  }

  /// Creates and persists a recurring check-in event.
  ///
  /// [friendId]    — owning friend card UUID
  /// [type]        — event type name string
  /// [date]        — Unix epoch ms for the first occurrence
  /// [cadenceDays] — repeat interval in days (7/14/21/30/60/90)
  /// [comment]     — optional free-text note
  ///
  /// Returns the generated UUID for the new event.
  Future<String> addRecurringEvent({
    required String friendId,
    required String type,
    required int date,
    required int cadenceDays,
    String? comment,
  }) async {
    assert(
      [7, 14, 21, 30, 60, 90].contains(cadenceDays),
      'cadenceDays must be one of 7/14/21/30/60/90',
    );
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.eventDao.insertEvent(
      EventsCompanion.insert(
        id: id,
        friendId: friendId,
        type: type,
        date: date,
        isRecurring: const Value(true),
        comment: Value(comment?.trim().isEmpty == true ? null : comment?.trim()),
        isAcknowledged: const Value(false),
        createdAt: now,
        cadenceDays: Value(cadenceDays),
      ),
    );
    return id;
  }

  /// Returns all events for [friendId], ordered by date ascending.
  Future<List<Event>> findByFriendId(String friendId) =>
      db.eventDao.findByFriendId(friendId);

  /// Watches all events for [friendId]; reactive stream.
  Stream<List<Event>> watchByFriendId(String friendId) =>
      db.eventDao.watchByFriendId(friendId);

  /// Watches all recurring events across all friends (priority engine input).
  Stream<List<Event>> watchAllRecurring() => db.eventDao.watchAllRecurring();

  /// Watches events eligible for priority computation.
  ///
  /// Story 3.5 AC4: includes recurring events and non-acknowledged one-time
  /// events; acknowledged one-time events are excluded.
  Stream<List<Event>> watchPriorityInputEvents() =>
      db.eventDao.watchPriorityInputEvents();

  /// Deletes the event with [id].
  Future<int> deleteEvent(String id) => db.eventDao.deleteEvent(id);

  /// Deletes all events for a [friendId] (called on friend deletion).
  Future<int> deleteByFriendId(String friendId) =>
      db.eventDao.deleteByFriendId(friendId);

  /// Returns a single event by [id], or null when not found.
  Future<Event?> findById(String id) => db.eventDao.findById(id);

  /// Updates an existing event's mutable fields.
  ///
  /// Story 3.3 AC2: timestamps (updated_at) managed at repo layer.
  /// [type], [date], [cadenceDays], [comment], [isRecurring] may be changed.
  Future<bool> updateEvent({
    required String id,
    required String friendId,
    required String type,
    required int date,
    required bool isRecurring,
    int? cadenceDays,
    String? comment,
    required bool isAcknowledged,
    int? acknowledgedAt,
    required int createdAt,
  }) {
    return db.eventDao.updateEvent(
      EventsCompanion(
        id: Value(id),
        friendId: Value(friendId),
        type: Value(type),
        date: Value(date),
        isRecurring: Value(isRecurring),
        cadenceDays: Value(cadenceDays),
        comment: Value(comment?.trim().isEmpty == true ? null : comment?.trim()),
        isAcknowledged: Value(isAcknowledged),
        acknowledgedAt: Value(acknowledgedAt),
        createdAt: Value(createdAt),
      ),
    );
  }

  /// Acknowledges the event with [id].
  ///
  /// Story 3.5 AC1: sets is_acknowledged=true and acknowledged_at=now.
  /// Story 3.5 AC3: for recurring events, advances `date` by cadence_days so
  /// the next occurrence becomes the new due date, and resets acknowledged.
  Future<void> acknowledgeEvent(String id) async {
    final event = await db.eventDao.findById(id);
    if (event == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (event.isRecurring && event.cadenceDays != null) {
      // Advance due date to next occurrence; reset acknowledged state.
      final nextDate =
          event.date + event.cadenceDays! * Duration.millisecondsPerDay;
      await db.eventDao.updateEvent(
        EventsCompanion(
          id: Value(id),
          friendId: Value(event.friendId),
          type: Value(event.type),
          date: Value(nextDate),
          isRecurring: const Value(true),
          cadenceDays: Value(event.cadenceDays),
          comment: Value(event.comment),
          isAcknowledged: const Value(false),
          acknowledgedAt: const Value(null),
          createdAt: Value(event.createdAt),
        ),
      );
    } else {
      // One-time event: mark as done.
      await db.eventDao.updateEvent(
        EventsCompanion(
          id: Value(id),
          friendId: Value(event.friendId),
          type: Value(event.type),
          date: Value(event.date),
          isRecurring: const Value(false),
          cadenceDays: const Value(null),
          comment: Value(event.comment),
          isAcknowledged: const Value(true),
          acknowledgedAt: Value(now),
          createdAt: Value(event.createdAt),
        ),
      );
    }
  }
}
