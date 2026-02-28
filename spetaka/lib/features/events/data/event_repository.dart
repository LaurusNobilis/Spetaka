import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/event_type.dart';

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

  /// Creates and persists a new one-off dated event.
  ///
  /// [friendId] — owning friend card UUID
  /// [type]     — event type (one of the default 5, or custom later)
  /// [date]     — Unix epoch ms for the event date
  /// [comment]  — optional free-text note
  ///
  /// Returns the generated UUID for the new event.
  Future<String> addDatedEvent({
    required String friendId,
    required EventType type,
    required int date,
    String? comment,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.eventDao.insertEvent(
      EventsCompanion.insert(
        id: id,
        friendId: friendId,
        type: type.storedName,
        date: date,
        isRecurring: const Value(false),
        comment: Value(comment?.trim().isEmpty == true ? null : comment?.trim()),
        isAcknowledged: const Value(false),
        createdAt: now,
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

  /// Deletes the event with [id].
  Future<int> deleteEvent(String id) => db.eventDao.deleteEvent(id);

  /// Deletes all events for a [friendId] (called on friend deletion).
  Future<int> deleteByFriendId(String friendId) =>
      db.eventDao.deleteByFriendId(friendId);
}
