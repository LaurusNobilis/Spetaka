import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'event_repository_provider.dart';

/// Watches all events for [friendId]; reactive stream for Story 3.1 AC3.
///
/// Used by [FriendCardScreen] to render the event list section.
final watchEventsByFriendProvider =
    StreamProvider.autoDispose.family<List<Event>, String>((ref, friendId) {
  return ref.watch(eventRepositoryProvider).watchByFriendId(friendId);
});

/// Watches all recurring events across all friends.
///
/// Exposed as priority engine input stream — Story 3.2 AC5.
final watchAllRecurringEventsProvider =
    StreamProvider.autoDispose<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllRecurring();
});

/// Watches events eligible for priority computation:
/// recurring events + non-acknowledged one-time events.
///
/// Story 3.5 AC4: acknowledged one-time events are excluded from this stream.
final watchPriorityInputEventsProvider =
    StreamProvider.autoDispose<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchPriorityInputEvents();
});
