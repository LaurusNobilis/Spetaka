// Daily View Provider — Story 4.2
//
// Combines allFriendsProvider + watchPriorityInputEventsProvider into a
// priority-sorted list of friends whose events fall within the surface window:
//   • overdue unacknowledged events (date < today)
//   • today's events
//   • events within the next 3 days
//
// Demo friends (isDemo = true / Sophie) are excluded via
// PriorityEngine.sort(excludeDemo: true).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../events/data/events_providers.dart';
import '../../friends/data/friends_providers.dart';
import '../../friends/domain/friend_tags_codec.dart';
import '../../settings/data/category_tags_provider.dart';
import '../domain/priority_engine.dart';

// ---------------------------------------------------------------------------
// DailyViewEntry — combines DB record + computed priority
// ---------------------------------------------------------------------------

/// Pairs a [Friend] database record with the [PrioritizedFriend] result
/// from the Priority Engine, carrying everything the UI layer needs.
class DailyViewEntry {
  const DailyViewEntry({
    required this.friend,
    required this.prioritized,
  });

  final Friend friend;
  final PrioritizedFriend prioritized;

  /// Human-readable surfacing reason derived from [prioritized.daysUntilNextEvent].
  String get surfacingReason {
    final days = prioritized.daysUntilNextEvent;
    if (days == null) return 'No upcoming event';
    if (days < -1) return 'Overdue by ${-days} days';
    if (days == -1) return 'Overdue by 1 day';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Reactive view of the daily surface window, updated whenever friends or
/// events change in the database.
///
/// Returns an [AsyncValue] that is:
///   • [AsyncLoading] while either upstream stream is loading
///   • [AsyncError]   if either upstream stream errors
///   • [AsyncData]    with a sorted, filtered [List<DailyViewEntry>]
final watchDailyViewProvider =
    Provider.autoDispose<AsyncValue<List<DailyViewEntry>>>((ref) {
  final friendsAsync = ref.watch(allFriendsProvider);
  final eventsAsync = ref.watch(watchPriorityInputEventsProvider);
  final categoryWeights = ref.watch(categoryWeightsMapProvider);

  return friendsAsync.when(
    data: (friends) => eventsAsync.when(
      data: (events) =>
          AsyncData(buildDailyView(friends, events, categoryWeights: categoryWeights)),
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});

// ---------------------------------------------------------------------------
// Core logic (also exposed for unit tests)
// ---------------------------------------------------------------------------

/// Builds the sorted daily-view list from raw DB rows.
///
/// Exposed as a top-level function so unit tests can exercise the filtering
/// and sorting logic without a Riverpod container.
List<DailyViewEntry> buildDailyView(
  List<Friend> friends,
  List<Event> events, {
  Map<String, double>? categoryWeights,
}) {
  // Surface window: any event before midnight of (today + 4 days) qualifies,
  // which covers overdue + today + +3 days of future events.
  final now = DateTime.now();
  final windowEndExclusive =
      DateTime(now.year, now.month, now.day).add(const Duration(days: 4));
  final windowEndMs = windowEndExclusive.millisecondsSinceEpoch;

  // Group in-window events by friendId.
  // watchPriorityInputEventsProvider already excludes acknowledged one-time
  // events; we additionally restrict to the +3d surface window here.
  final eventsByFriend = <String, List<Event>>{};
  for (final e in events) {
    if (e.date < windowEndMs) {
      eventsByFriend.putIfAbsent(e.friendId, () => []).add(e);
    }
  }

  // Build FriendScoringInputs only for friends that have in-window events.
  final inputs = <FriendScoringInput>[];
  for (final friend in friends) {
    final friendEvents = eventsByFriend[friend.id];
    if (friendEvents == null || friendEvents.isEmpty) continue;

    final scoringEvents = friendEvents
        .map(
          (e) => EventScoringInput(
            date: DateTime.fromMillisecondsSinceEpoch(e.date),
            isAcknowledged: e.isAcknowledged,
            isRecurring: e.isRecurring,
          ),
        )
        .toList();

    inputs.add(
      FriendScoringInput(
        id: friend.id,
        events: scoringEvents,
        careScore: friend.careScore,
        hasConcern: friend.isConcernActive,
        tags: decodeFriendTags(friend.tags),
        isDemo: friend.isDemo,
      ),
    );
  }

  // Sort via PriorityEngine (excludeDemo removes Sophie).
  const engine = PriorityEngine();
  final sorted = engine.sort(
    inputs,
    excludeDemo: true,
    categoryWeights: categoryWeights,
  );

  // Map back to DailyViewEntry, joining with the Friend record.
  final friendById = {for (final f in friends) f.id: f};
  return sorted
      .map((p) {
        final f = friendById[p.friendId];
        if (f == null) return null;
        return DailyViewEntry(friend: f, prioritized: p);
      })
      .whereType<DailyViewEntry>()
      .toList();
}
