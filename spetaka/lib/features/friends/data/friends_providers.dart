import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/friends/data/friend_repository_provider.dart';
import 'package:spetaka/features/friends/domain/friend_tags_codec.dart';

String _normalizedSearchQuery(String query) => query.trim().toLowerCase();

bool _friendNameMatchesQuery(String friendName, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  return friendName.toLowerCase().contains(normalizedQuery);
}

/// Minimal reactive provider that streams all friends for the list screen.
///
/// Why stream (not Future)? In GoRouter nested routes, `/friends` stays mounted
/// while `/friends/new` is on top. A Future-based provider would NOT refresh
/// automatically after an insert, breaking Story 2.2 AC5.
///
/// NOTE: Story 2.5 still owns the full list UX (tiles, search, sort).
final allFriendsProvider = StreamProvider.autoDispose<List<Friend>>((ref) {
  return ref.watch(friendRepositoryProvider).watchAll();
});

/// Loads a single friend record by id for detail pages.
///
/// Story 2.3 only needs tags display; Story 2.6 will expand the full detail UX.
final friendByIdProvider = FutureProvider.autoDispose.family<Friend?, String>((
  ref,
  id,
) {
  return ref.watch(friendRepositoryProvider).findById(id);
});

/// Watches a single friend by id — reactive stream for Story 2.6 AC5.
///
/// Emits null when the friend no longer exists (e.g. after deletion).
final watchFriendByIdProvider =
    StreamProvider.autoDispose.family<Friend?, String>((ref, id) {
  return ref.watch(friendRepositoryProvider).watchById(id);
});

// ---------------------------------------------------------------------------
// Story 8.4 — Last contact display
// ---------------------------------------------------------------------------

/// Data class pairing a friend with their most recent contact timestamp.
class FriendWithLastContact {
  const FriendWithLastContact({required this.friend, this.lastContactAt});
  final Friend friend;
  final DateTime? lastContactAt;
}

/// Streams the max `createdAt` per friend from acquittements.
///
/// Story 8.4 AC5 — reactive stream that re-emits on any acquittement change.
final lastContactByFriendProvider =
    StreamProvider.autoDispose<Map<String, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.acquittementDao.watchMaxCreatedAtByFriend();
});

/// Combines [allFriendsProvider] with [lastContactByFriendProvider] to produce
/// a list of [FriendWithLastContact] records.
///
/// Story 8.4 AC5 — single provider for the list screen to consume.
final friendsWithLastContactProvider =
    Provider.autoDispose<AsyncValue<List<FriendWithLastContact>>>((ref) {
  final asyncFriends = ref.watch(allFriendsProvider);
  final asyncLastContact = ref.watch(lastContactByFriendProvider);

  return asyncFriends.when(
    loading: AsyncValue.loading,
    error: AsyncValue.error,
    // Last-contact metadata is additive. If its stream fails or is still
    // loading, keep the friend list usable and omit the secondary line.
    data: (friends) {
      final lastContactMap = asyncLastContact.asData?.value ??
          const <String, int>{};

      return AsyncValue.data(
        friends.map((friend) {
          final ts = lastContactMap[friend.id];
          return FriendWithLastContact(
            friend: friend,
            lastContactAt:
                ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
          );
        }).toList(),
      );
    },
  );
});

/// Filtered friend list that preserves last-contact data.
final filteredFriendsWithLastContactProvider =
    Provider.autoDispose<AsyncValue<List<FriendWithLastContact>>>((ref) {
  final asyncFriends = ref.watch(friendsWithLastContactProvider);
  final activeTags = ref.watch(activeTagFiltersProvider);

  return asyncFriends.whenData((friends) {
    if (activeTags.isEmpty) return friends;
    return friends.where((entry) {
      final friendTags = decodeFriendTags(entry.friend.tags);
      return friendTags.any(activeTags.contains);
    }).toList();
  });
});

/// Search-filtered friend list that preserves last-contact data.
final searchFilteredFriendsWithLastContactProvider =
    Provider.autoDispose<AsyncValue<List<FriendWithLastContact>>>((ref) {
  final asyncFiltered = ref.watch(filteredFriendsWithLastContactProvider);
  final normalizedQuery = _normalizedSearchQuery(ref.watch(searchQueryProvider));

  if (normalizedQuery.isEmpty) return asyncFiltered;

  return asyncFiltered.whenData((friends) {
    return friends
        .where(
          (entry) =>
              _friendNameMatchesQuery(entry.friend.name, normalizedQuery),
        )
        .toList();
  });
});

// ---------------------------------------------------------------------------
// Story 8.1 — Tag filtering (session-only, in-memory)
// ---------------------------------------------------------------------------

/// Session-only set of active tag filters. Not persisted (AC5).
/// Resets on dispose (autoDispose) so next app launch shows full list.
final activeTagFiltersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => const <String>{});

/// Distinct category tags derived from live friend data (AC1, AC6).
///
/// Scans all friends' encoded tags and collects unique values.
/// Tags disappear automatically when no friend uses them (AC6).
/// Named distinctly from [categoryTagsProvider] in settings to avoid shadowing.
final distinctFriendCategoryTagsProvider =
    Provider.autoDispose<List<String>>((ref) {
  final asyncFriends = ref.watch(allFriendsProvider);
  final friends = asyncFriends.asData?.value ?? <Friend>[];
  final tagSet = <String>{};
  for (final friend in friends) {
    tagSet.addAll(decodeFriendTags(friend.tags));
  }
  final sorted = tagSet.toList()..sort();
  return sorted;
});

/// Filtered friend list using OR logic across selected tags (AC2, AC3).
///
/// When no tags are selected, returns the full list.
/// Filtering is computed in memory from [allFriendsProvider] output only —
/// no additional SQL query (story requirement).
final filteredFriendsProvider = Provider.autoDispose<AsyncValue<List<Friend>>>(
  (ref) {
  final asyncFriends = ref.watch(allFriendsProvider);
  final activeTags = ref.watch(activeTagFiltersProvider);

  return asyncFriends.whenData((friends) {
    if (activeTags.isEmpty) return friends;
    return friends.where((friend) {
      final friendTags = decodeFriendTags(friend.tags);
      return friendTags.any(activeTags.contains);
    }).toList();
  });
},
);

// ---------------------------------------------------------------------------
// Story 8.2 — Search friend list by name (session-only, in-memory)
// ---------------------------------------------------------------------------

/// Session-only search query string. Not persisted; cleared on navigation away.
///
/// Story 8.2 AC2, AC5 — real-time name filter driven by user typing.
final searchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Derived list filtered by both active tag filters (Story 8.1) AND name search
/// (Story 8.2).
///
/// Provider chain:
///   allFriendsProvider → filteredFriendsProvider (tags) → searchFilteredFriendsProvider (name)
///
/// When [searchQueryProvider] is empty this is a pass-through for
/// [filteredFriendsProvider]. Intersection semantics: a friend must match BOTH
/// the active tags and the search query (AC3).
///
/// Filtering is in-memory — no new Drift query (AC2).
final searchFilteredFriendsProvider =
    Provider.autoDispose<AsyncValue<List<Friend>>>((ref) {
  final asyncFiltered = ref.watch(filteredFriendsProvider);
  final normalizedQuery = _normalizedSearchQuery(ref.watch(searchQueryProvider));

  if (normalizedQuery.isEmpty) return asyncFiltered;

  return asyncFiltered.whenData((friends) {
    return friends
        .where((friend) => _friendNameMatchesQuery(friend.name, normalizedQuery))
        .toList();
  });
});

// ---------------------------------------------------------------------------
// Story 8.3 — Status filtering (session-only, in-memory)
// ---------------------------------------------------------------------------

/// Threshold in days for the "No recent contact" status filter.
///
/// Story 8.3 AC1, AC5 — configurable constant.
const int kNoRecentContactDays = 30;

/// Status-filter categories available in the [StatusFilterSheet].
///
/// Story 8.3 AC1.
enum StatusFilter {
  /// Friends where [Friend.isConcernActive] is true.
  activeConcern,

  /// Friends with at least one unacknowledged event whose due date has passed.
  overdueEvent,

  /// Friends whose most recent acquittement `created_at` is older than
  /// [kNoRecentContactDays] days, or who have never been contacted.
  noRecentContact,
}

/// Session-only set of active status filters. Not persisted (AC6).
/// Resets on dispose (autoDispose) so next app launch shows full list.
final activeStatusFiltersProvider =
    StateProvider.autoDispose<Set<StatusFilter>>((ref) => const <StatusFilter>{});

/// Streams all events relevant for overdue-status computation.
///
/// Uses [EventDao.watchPriorityInputEvents] which already excludes acknowledged
/// one-off events — only recurring events and unacknowledged one-offs are
/// returned, matching the overdue definition in Story 8.3 AC1.
///
/// No new SQL beyond what Story 4.1 established.
final allEventsForStatusProvider =
    StreamProvider.autoDispose<List<Event>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.eventDao.watchPriorityInputEvents();
});

/// Derives the set of friend IDs that have at least one overdue unacknowledged
/// event.
///
/// An event is overdue when its [Event.date] (Unix-epoch ms) is strictly before
/// the current time AND it is not acknowledged. Because [allEventsForStatusProvider]
/// already filters out acknowledged one-off events, a simple date check suffices.
///
/// Story 8.3 AC1 — in-memory computation, no new Drift query.
final overdueEventFriendIdsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final asyncEvents = ref.watch(allEventsForStatusProvider);
  final events = asyncEvents.asData?.value ?? <Event>[];
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final result = <String>{};
  for (final event in events) {
    if (!event.isAcknowledged && event.date < nowMs) {
      result.add(event.friendId);
    }
  }
  return result;
});

/// Status-filtered friend list — the final provider consumed by [FriendsListScreen].
///
/// Provider chain:
///   searchFilteredFriendsWithLastContactProvider
///     → statusFilteredFriendsWithLastContactProvider (this story)
///
/// When no status filters are active this is a pass-through.
/// All three filter dimensions (tags + search + status) compose as intersection.
///
/// Story 8.3 AC2.
final statusFilteredFriendsWithLastContactProvider =
    Provider.autoDispose<AsyncValue<List<FriendWithLastContact>>>((ref) {
  final asyncFriends = ref.watch(searchFilteredFriendsWithLastContactProvider);
  final activeFilters = ref.watch(activeStatusFiltersProvider);

  if (activeFilters.isEmpty) return asyncFriends;

  final overdueIds = ref.watch(overdueEventFriendIdsProvider);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  const thresholdMs = kNoRecentContactDays * Duration.millisecondsPerDay;

  return asyncFriends.whenData((friends) {
    return friends.where((entry) {
      return activeFilters.any((filter) {
        switch (filter) {
          case StatusFilter.activeConcern:
            return entry.friend.isConcernActive;
          case StatusFilter.overdueEvent:
            return overdueIds.contains(entry.friend.id);
          case StatusFilter.noRecentContact:
            final lastContactAt = entry.lastContactAt;
            return lastContactAt == null ||
                nowMs - lastContactAt.millisecondsSinceEpoch > thresholdMs;
        }
      });
    }).toList();
  });
});
