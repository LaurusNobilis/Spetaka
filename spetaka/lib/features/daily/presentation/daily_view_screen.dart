// DailyViewScreen — Stories 4.2 / 4.3 / 4.4 / 4.6 / 5.2 / 10.5
//
// Story 4.4: Greeting banner + density toggle (compact/expanded, shared_prefs).
// Story 4.6: Inline card expansion, AnimatedSize+AnimatedCrossFade 300ms,
//            action row (call/SMS/WA), last note, Full-details push nav,
//            back-gesture collapse, semantics, 48dp touch targets.
// Story 5.2: Listen to pendingActionStream; expand card + open acquittement
//            sheet when origin is `dailyView`.
// Story 10.5: 4th action button "✶ Message IA" in expanded card, gated by
//             aiCapabilityCheckerProvider + modelManagerProvider.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/actions/contact_action_service.dart';
import '../../../core/ai/ai_capability_checker.dart';
import '../../../core/ai/model_manager.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/lifecycle/app_lifecycle_service.dart';
import '../../../core/router/app_router.dart';
import '../../../features/acquittement/domain/pending_action_state.dart';
import '../../../features/acquittement/presentation/acquittement_sheet.dart';
import '../../../features/drafts/presentation/draft_message_sheet.dart';
import '../data/daily_view_provider.dart';
import '../data/density_provider.dart';
import '../data/greeting_line_provider.dart';
import '../domain/priority_engine.dart';
import 'daily_text_helpers.dart';
import 'greeting_line_widget.dart';
import 'heart_briefing_widget.dart';

const _kExpandDuration = Duration(milliseconds: 300);
const _kExpandCurve = Curves.easeInOutCubic;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DailyViewScreen extends ConsumerStatefulWidget {
  const DailyViewScreen({super.key});

  @override
  ConsumerState<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends ConsumerState<DailyViewScreen> {
  String? _expandedFriendId;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<PendingActionState>? _pendingSub;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;

  Widget _navAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String tooltip,
    required bool isCurrent,
    required VoidCallback? onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final iconWidget = Icon(
      icon,
      color: isCurrent ? scheme.onPrimaryContainer : null,
    );

    final button = IconButton(
      icon: iconWidget,
      tooltip: tooltip,
      onPressed: isCurrent ? null : onPressed,
    );

    return Semantics(
      label: label,
      button: true,
      selected: isCurrent,
      child: isCurrent
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: button,
            )
          : button,
    );
  }

  @override
  void initState() {
    super.initState();
    // Story 5-2: subscribe to return-detection stream after first frame so
    // that `ref` is fully available and the widget tree is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pendingSub = ref
          .read(appLifecycleServiceProvider)
          .pendingActionStream
          .listen(_onPendingAction);
      _lifecycleSub = ref
          .read(appLifecycleServiceProvider)
          .lifecycleStates
          .listen(_onLifecycleChanged);
    });
  }

  /// Handles a pending action emitted on app resume (Story 5-2).
  ///
  /// Only reacts to [AcquittementOrigin.dailyView] events — friend-card
  /// origin is handled by [FriendCardScreen].
  void _onPendingAction(PendingActionState state) {
    if (!mounted) return;
    if (state.origin != AcquittementOrigin.dailyView) return;

    // AC2: maintain expanded card + open sheet over daily view.
    setState(() => _expandedFriendId = state.friendId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAcquittementSheet(
        context: context,
        ref: ref,
        pendingState: state,
      );
    });
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    if (!mounted || state != AppLifecycleState.resumed) {
      return;
    }

    ref.invalidate(greetingLineProvider);
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _lifecycleSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpand(String friendId) {
    setState(() {
      _expandedFriendId = _expandedFriendId == friendId ? null : friendId;
    });
  }

  void _collapseAll() {
    setState(() => _expandedFriendId = null);
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(watchDailyViewProvider);
    final densityMode = ref.watch(densityModeProvider);

    return PopScope(
      canPop: _expandedFriendId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _expandedFriendId != null) _collapseAll();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.dailyTitle),
          actions: [
            _navAction(
              context: context,
              label: context.l10n.navSettings,
              icon: Icons.settings_outlined,
              tooltip: context.l10n.navSettings,
              isCurrent: false,
              onPressed: () => const SettingsRoute().push(context),
            ),
          ],
        ),
        body: dailyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.couldNotLoadDailyView,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (entries) => _DailyList(
            entries: entries,
            densityMode: densityMode,
            expandedFriendId: _expandedFriendId,
            onToggleExpand: _toggleExpand,
            scrollController: _scrollController,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DailyList
// ---------------------------------------------------------------------------

class _DailyList extends StatelessWidget {
  const _DailyList({
    required this.entries,
    required this.densityMode,
    required this.expandedFriendId,
    required this.onToggleExpand,
    required this.scrollController,
  });

  final List<DailyViewEntry> entries;
  final DensityMode densityMode;
  final String? expandedFriendId;
  final ValueChanged<String> onToggleExpand;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.nothingToday,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        const SliverToBoxAdapter(child: GreetingLineWidget()),
        SliverToBoxAdapter(child: HeartBriefingWidget(entries: entries)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _ExpandableFriendCard(
                entry: entry,
                densityMode: densityMode,
                isExpanded: expandedFriendId == entry.friend.id,
                onToggleExpand: () => onToggleExpand(entry.friend.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4.6 Expandable card
// ---------------------------------------------------------------------------

class _ExpandableFriendCard extends ConsumerWidget {
  const _ExpandableFriendCard({
    required this.entry,
    required this.densityMode,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final DailyViewEntry entry;
  final DensityMode densityMode;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final friend = entry.friend;
    final tier = entry.prioritized.tier;
    final hasConcern = friend.isConcernActive;

    final tierColor = switch (tier) {
      UrgencyTier.urgent => theme.colorScheme.error,
      UrgencyTier.important => theme.colorScheme.secondary,
      UrgencyTier.normal =>
        theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };

    final tierLabel = switch (tier) {
      UrgencyTier.urgent => context.l10n.urgentLabel,
      UrgencyTier.important => context.l10n.importantLabel,
      UrgencyTier.normal => context.l10n.tierNormal,
    };

    final verticalPadding = densityMode == DensityMode.compact ? 8.0 : 14.0;

    return Semantics(
      label: '${friend.name}, $tierLabel, ${localizedSurfacingReason(context, entry.prioritized.daysUntilNextEvent)}'
          '${hasConcern ? ', ${context.l10n.concernActiveSemantics}' : ''}',
      button: true,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: tierColor.withValues(alpha: isExpanded ? 0.6 : 0.35),
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: AnimatedSize(
          duration: _kExpandDuration,
          curve: _kExpandCurve,
          alignment: Alignment.topCenter,
          child: AnimatedCrossFade(
            duration: _kExpandDuration,
            firstCurve: _kExpandCurve,
            secondCurve: _kExpandCurve,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _CollapsedContent(
              cardKey: isExpanded ? null : Key('card_${friend.id}'),
              onTap: onToggleExpand,
              entry: entry,
              tierColor: tierColor,
              tierLabel: tierLabel,
              hasConcern: hasConcern,
              verticalPadding: verticalPadding,
            ),
            secondChild: _ExpandedContent(
              cardKey: isExpanded ? Key('card_${friend.id}') : null,
              entry: entry,
              tierColor: tierColor,
              tierLabel: tierLabel,
              hasConcern: hasConcern,
              onToggleExpand: onToggleExpand,
              actionService: ref.read(contactActionServiceProvider),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CollapsedContent
// ---------------------------------------------------------------------------

class _CollapsedContent extends StatelessWidget {
  const _CollapsedContent({
    required this.cardKey,
    required this.onTap,
    required this.entry,
    required this.tierColor,
    required this.tierLabel,
    required this.hasConcern,
    required this.verticalPadding,
  });

  final Key? cardKey;
  final VoidCallback onTap;
  final DailyViewEntry entry;
  final Color tierColor;
  final String tierLabel;
  final bool hasConcern;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friend = entry.friend;

    return InkWell(
      key: cardKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
                          semanticLabel: context.l10n.concernActiveSemantics,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildEventSubtitle(context, entry),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.nextEventLabel ?? tierLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper — event subtitle for collapsed card
// ---------------------------------------------------------------------------

/// Builds the subtitle line shown in the collapsed daily-view card.
///
/// Shows the event date (e.g. "15 mars") followed by the event comment
/// truncated by [TextOverflow.ellipsis] at the widget level. Falls back
/// to an empty string when no nearest event is available.
String _buildEventSubtitle(BuildContext context, DailyViewEntry entry) {
  final event = entry.nearestEvent;
  if (event == null) return '';
  final locale = Localizations.localeOf(context).toString();
  final dateStr = DateFormat('d MMM', locale)
      .format(DateTime.fromMillisecondsSinceEpoch(event.date));
  final comment = event.comment;
  if (comment != null && comment.isNotEmpty) {
    return '$dateStr · $comment';
  }
  return dateStr;
}

// ---------------------------------------------------------------------------
// _ExpandedContent
// ---------------------------------------------------------------------------

class _ExpandedContent extends ConsumerStatefulWidget {
  const _ExpandedContent({
    required this.cardKey,
    required this.entry,
    required this.tierColor,
    required this.tierLabel,
    required this.hasConcern,
    required this.onToggleExpand,
    required this.actionService,
  });

  final Key? cardKey;
  final DailyViewEntry entry;
  final Color tierColor;
  final String tierLabel;
  final bool hasConcern;
  final VoidCallback onToggleExpand;
  final ContactActionService actionService;

  @override
  ConsumerState<_ExpandedContent> createState() => _ExpandedContentState();
}

class _ExpandedContentState extends ConsumerState<_ExpandedContent> {
  String? _actionError;

  Future<void> _handleCall() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.call(
        widget.entry.friend.mobile,
        friendId: widget.entry.friend.id,
        origin: AcquittementOrigin.dailyView,
      );
    } on AppError catch (e) {
      if (mounted) {
        setState(() => _actionError = errorMessageFor(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = context.l10n.somethingWentWrong);
      }
    }
  }

  Future<void> _handleSms() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.sms(
        widget.entry.friend.mobile,
        friendId: widget.entry.friend.id,
        origin: AcquittementOrigin.dailyView,
      );
    } on AppError catch (e) {
      if (mounted) setState(() => _actionError = errorMessageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = context.l10n.somethingWentWrong);
      }
    }
  }

  Future<void> _handleWhatsApp() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.whatsapp(
        widget.entry.friend.mobile,
        friendId: widget.entry.friend.id,
        origin: AcquittementOrigin.dailyView,
      );
    } on AppError catch (e) {
      if (mounted) setState(() => _actionError = errorMessageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = context.l10n.somethingWentWrong);
      }
    }
  }

  /// Story 10.5: Opens DraftMessageSheet with the nearest unacknowledged event.
  Future<void> _handleSuggestMessage(BuildContext context) async {
    final event = widget.entry.nearestEvent;
    if (event == null) return;
    setState(() => _actionError = null);
    await showDraftMessageSheet(
      context: context,
      ref: ref,
      friendId: widget.entry.friend.id,
      event: event,
      origin: AcquittementOrigin.dailyView,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Story 10.5: inline LLM gate — same logic as LlmFeatureGuard but as a bool
    // so we can conditionally include the button in a Row without widget-wrapping.
    final isLlmSupported = ref.watch(aiCapabilityCheckerProvider);
    final modelState = ref.watch(modelManagerProvider);
    final isModelReady = modelState is ModelReady;
    final showMessageButton =
        isLlmSupported && isModelReady && widget.entry.nearestEvent != null;

    final theme = Theme.of(context);
    final friend = widget.entry.friend;
    final actionButtons = <Widget>[
      Expanded(
        child: _ActionButton(
          key: Key('action_call_${friend.id}'),
          icon: Icons.phone_outlined,
          label: context.l10n.callAction,
          onPressed: _handleCall,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: _ActionButton(
          key: Key('action_sms_${friend.id}'),
          icon: Icons.sms_outlined,
          label: context.l10n.smsAction,
          onPressed: _handleSms,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: _ActionButton(
          key: Key('action_wa_${friend.id}'),
          icon: Icons.chat_outlined,
          label: context.l10n.whatsappAction,
          onPressed: _handleWhatsApp,
        ),
      ),
    ];
    if (showMessageButton) {
      actionButtons.addAll([
        const SizedBox(width: 4),
        Expanded(
          child: _ActionButton(
            key: Key('action_llm_${friend.id}'),
            icon: Icons.auto_awesome_outlined,
            label: context.l10n.suggestMessageDailyAction,
            semanticsLabel: context.l10n.suggestMessageDailySemantics(friend.name),
            onPressed: () => _handleSuggestMessage(context),
          ),
        ),
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: widget.cardKey,
          onTap: widget.onToggleExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.tierColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            if (widget.hasConcern) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: theme.colorScheme.error,
                                semanticLabel: context.l10n.concernActiveSemantics,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizedSurfacingReason(context, widget.entry.prioritized.daysUntilNextEvent),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.tierColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.entry.nextEventLabel ?? widget.tierLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.tierColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_less,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: actionButtons,
          ),
        ),
        if (_actionError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              _actionError!,
              key: const Key('action_error_text'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (friend.notes != null && friend.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.lastNoteLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.notes!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Semantics(
            label: context.l10n.fullDetailsSemantics(friend.name),
            button: true,
            child: TextButton.icon(
              key: Key('full_details_${friend.id}'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(context.l10n.fullDetails),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => FriendDetailRoute(friend.id).push(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionButton
// ---------------------------------------------------------------------------

/// Action button that accepts an async callback and properly awaits it,
/// preventing unhandled async exceptions on launch failures.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String? semanticsLabel;

  /// Async callback — awaited internally so futures are never dropped.
  final Future<void> Function() onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _busy = false;

  Future<void> _handlePress() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: TextButton(
          onPressed: _busy ? null : _handlePress,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            maximumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20),
              const SizedBox(height: 2),
              Text(widget.label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
