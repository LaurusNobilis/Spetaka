// HeartBriefingWidget — Story 4.3
//
// Displayed at the top of DailyViewScreen; shows up to 2 urgent entries and
// up to 2 important entries from the daily view pipeline.
//
// Per AC3: if fewer than 2 entries exist in a tier, the widget renders only
// the available entries — no placeholders.

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';

import '../../../core/router/app_router.dart';
import '../data/daily_view_provider.dart';
import '../domain/priority_engine.dart';

/// Widget displayed at the top of [DailyViewScreen] showing at most 2 urgent
/// and 2 important friends.
///
/// [entries] is the full sorted list from [watchDailyViewProvider]; this
/// widget handles selection internally so it can be tested in isolation.
class HeartBriefingWidget extends StatelessWidget {
  const HeartBriefingWidget({super.key, required this.entries});

  /// Full sorted daily view list.  The widget picks the first ≤2 urgent
  /// and first ≤2 important entries automatically.
  final List<DailyViewEntry> entries;

  @override
  Widget build(BuildContext context) {
    final urgent = entries
        .where((e) => e.prioritized.tier == UrgencyTier.urgent)
        .take(2)
        .toList();
    final important = entries
        .where((e) => e.prioritized.tier == UrgencyTier.important)
        .take(2)
        .toList();

    // If neither tier has entries, render nothing.
    if (urgent.isEmpty && important.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Heart Briefing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (urgent.isNotEmpty) ...[
            _SectionLabel(
              label: context.l10n.urgentLabel,
              color: theme.colorScheme.error,
            ),
            for (final entry in urgent) _BriefingRow(entry: entry),
          ],
          if (important.isNotEmpty) ...[
            _SectionLabel(
              label: context.l10n.importantLabel,
              color: theme.colorScheme.secondary,
            ),
            for (final entry in important) _BriefingRow(entry: entry),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _BriefingRow extends StatelessWidget {
  const _BriefingRow({required this.entry});

  final DailyViewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friend = entry.friend;
    final hasConcern = friend.isConcernActive;

    return Semantics(
      label:
          '${friend.name}, ${entry.surfacingReason}${hasConcern ? ', concern active' : ''}',
      button: true,
      child: InkWell(
        onTap: () => FriendDetailRoute(friend.id).go(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Concern indicator
              if (hasConcern)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                    semanticLabel: 'Concern active',
                  ),
                ),
              // Friend name
              Expanded(
                child: Text(
                  friend.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Surfacing reason
              Text(
                entry.surfacingReason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
