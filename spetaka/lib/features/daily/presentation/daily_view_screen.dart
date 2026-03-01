// DailyViewScreen — Story 4.2
//
// Root screen (path '/') that surfaces friends whose events fall within the
// daily surface window: overdue + today + next 3 days.
//
// Pipeline: watchPriorityInputEventsProvider + allFriendsProvider
//           → buildDailyView() → PriorityEngine.sort(excludeDemo: true)
//
// AC4: friends outside the window do not appear.
// AC5: render target ≤1s on primary device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/daily_view_provider.dart';
import '../domain/priority_engine.dart';
import 'heart_briefing_widget.dart';

/// Home screen — daily view of prioritised friend cards.
class DailyViewScreen extends ConsumerWidget {
  const DailyViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(watchDailyViewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Friends',
            onPressed: () => const FriendsRoute().go(context),
          ),
        ],
      ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load daily view.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (entries) => _DailyList(entries: entries),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inner widget — separated so tests can pump it independently
// ---------------------------------------------------------------------------

class _DailyList extends StatelessWidget {
  const _DailyList({required this.entries});

  final List<DailyViewEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing to do today 🎉\nAll caught up!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // HeartBriefing 2+2 widget at the top (Story 4.3)
        SliverToBoxAdapter(
          child: HeartBriefingWidget(entries: entries),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _FriendTile(entry: entries[index]),
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.entry});

  final DailyViewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friend = entry.friend;
    final tier = entry.prioritized.tier;
    final hasConcern = friend.isConcernActive;

    final tierColor = switch (tier) {
      UrgencyTier.urgent => theme.colorScheme.error,
      UrgencyTier.important => theme.colorScheme.secondary,
      UrgencyTier.normal => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };

    final tierLabel = switch (tier) {
      UrgencyTier.urgent => 'Urgent',
      UrgencyTier.important => 'Important',
      UrgencyTier.normal => 'Normal',
    };

    return Semantics(
      label:
          '${friend.name}, $tierLabel, ${entry.surfacingReason}${hasConcern ? ', concern active' : ''}',
      button: true,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: tierColor.withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          onTap: () => FriendDetailRoute(friend.id).go(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Tier indicator strip
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + reason
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              friend.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasConcern) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: theme.colorScheme.error,
                              semanticLabel: 'Concern active',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.surfacingReason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tier badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tierLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
