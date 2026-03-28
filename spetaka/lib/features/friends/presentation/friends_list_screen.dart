import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/utils/relative_date.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

/// Friends list screen — Story 2.5.
///
/// AC1: scrollable `FriendCardTile` list backed by reactive friends providers.
/// AC2: tile shows name, category tags, concern indicator.
/// AC3: reactive [StreamProvider] backed by Drift `watchAll()`.
/// AC4: empty state prompts first-friend add.
/// AC5: data is stream-driven (no timer/polling), open time target respected.
/// AC6: `Semantics` labels for TalkBack navigation.
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() =>
      _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  bool _isSearchActive = false;
  bool _searchResetScheduled = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() => _isSearchActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _resetSearchState() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();
    if (_isSearchActive && mounted) {
      setState(() => _isSearchActive = false);
    }
  }

  void _clearSearch() {
    _resetSearchState();
  }

  void _scheduleSearchResetIfHidden(BuildContext context) {
    final isHostedInShell =
        context.findAncestorWidgetOfExactType<PageView>() != null;
    if (!isHostedInShell) return;

    final location = GoRouterState.of(context).uri.path;
    final isVisibleOnFriendsRoute = location == const FriendsRoute().location;
    final hasSearchState =
        _isSearchActive ||
        _searchController.text.isNotEmpty ||
        ref.read(searchQueryProvider).isNotEmpty;

    if (isVisibleOnFriendsRoute || !hasSearchState || _searchResetScheduled) {
      return;
    }

    _searchResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchResetScheduled = false;
      if (!mounted) return;
      _resetSearchState();
    });
  }

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
  Widget build(BuildContext context) {
    _scheduleSearchResetIfHidden(context);

    final asyncFriends = ref.watch(statusFilteredFriendsWithLastContactProvider);
    final distinctTags = ref.watch(distinctFriendCategoryTagsProvider);
    final activeTags = ref.watch(activeTagFiltersProvider);
    final activeStatusFilters = ref.watch(activeStatusFiltersProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final trimmedSearchQuery = searchQuery.trim();
    final hasSearchQuery = trimmedSearchQuery.isNotEmpty;
    final hasStatusFilters = activeStatusFilters.isNotEmpty;

    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchActive) {
          _clearSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearchActive
              ? Semantics(
                  label: context.l10n.searchFriendsByName,
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.l10n.searchFriendsByName,
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                )
              : Text(context.l10n.friendsTitle),
          actions: [
            if (_isSearchActive)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.actionClear,
                onPressed: _clearSearch,
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: context.l10n.searchFriendsByName,
                onPressed: _activateSearch,
              ),
            // Story 8.3 — status filter icon with active-count badge
            Semantics(
              label: hasStatusFilters
                  ? context.l10n.statusFilterActiveSemantics(activeStatusFilters.length)
                  : context.l10n.statusFilterTooltip,
              button: true,
              child: IconButton(
                icon: Badge(
                  isLabelVisible: hasStatusFilters,
                  label: Text('${activeStatusFilters.length}'),
                  child: Icon(
                    hasStatusFilters
                        ? Icons.filter_list
                        : Icons.filter_list_outlined,
                  ),
                ),
                tooltip: context.l10n.statusFilterTooltip,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const StatusFilterSheet(),
                ),
              ),
            ),
            _navAction(
              context: context,
              label: context.l10n.navDaily,
              icon: Icons.view_agenda_outlined,
              tooltip: context.l10n.navDaily,
              isCurrent: false,
              onPressed: () => const HomeRoute().go(context),
            ),
            _navAction(
              context: context,
              label: context.l10n.navFriends,
              icon: Icons.people_outline,
              tooltip: context.l10n.navFriends,
              isCurrent: true,
              onPressed: null,
            ),
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
        body: asyncFriends.when(
          loading: () => const Center(child: LoadingWidget()),
          error: (err, _) {
            final message = err is AppError
                ? errorMessageFor(err)
                : context.l10n.somethingWentWrong;
            return Center(child: AppErrorWidget(message: message));
          },
          data: (friends) {
            if (friends.isEmpty && activeTags.isEmpty && !hasSearchQuery && !hasStatusFilters) {
              return _EmptyFriendsState(
                onAddFriend: () => const NewFriendRoute().push(context),
              );
            }

            return Column(
              children: [
                if (distinctTags.isNotEmpty)
                  _TagFilterChipsBar(
                    tags: distinctTags,
                    activeTags: activeTags,
                    onTagToggled: (tag) {
                      final notifier =
                          ref.read(activeTagFiltersProvider.notifier);
                      final current = ref.read(activeTagFiltersProvider);
                      if (current.contains(tag)) {
                        notifier.state = <String>{...current}..remove(tag);
                      } else {
                        notifier.state = <String>{...current, tag};
                      }
                    },
                  ),
                Expanded(
                  child: friends.isEmpty
                    ? hasStatusFilters
                      ? const _StatusFilterEmptyState()
                      : hasSearchQuery
                        ? _SearchEmptyState(query: trimmedSearchQuery)
                        : const _FilteredEmptyState()
                      : ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friendEntry = friends[index];
                            final friend = friendEntry.friend;
                            return FriendCardTile(
                              friend: friend,
                              lastContactAt: friendEntry.lastContactAt,
                              onTap: () =>
                                  FriendDetailRoute(friend.id).push(context),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => const NewFriendRoute().push(context),
          tooltip: context.l10n.addFriendTooltip,
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FriendCardTile — AC2 tile
// ---------------------------------------------------------------------------

/// Tile representing one friend in the list. AC2: name + tags + concern.
class FriendCardTile extends StatelessWidget {
  const FriendCardTile({
    super.key,
    required this.friend,
    required this.lastContactAt,
    required this.onTap,
  });

  final Friend friend;
  final DateTime? lastContactAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tags = decodeFriendTags(friend.tags);
    final hasConcern = friend.isConcernActive;
    final scheme = Theme.of(context).colorScheme;
    final textSubColor = AppTokens.textSubFor(Theme.of(context).brightness);
    final languageCode = Localizations.localeOf(context).languageCode;
    final relativeLastContact = lastContactAt != null
        ? formatRelativeDate(
            lastContactAt!,
            languageCode: languageCode,
          )
        : null;

    // AC6: build a meaningful accessibility description.
    final semanticsBuffer = StringBuffer(friend.name);
    if (relativeLastContact != null) {
      semanticsBuffer.write(
        ', ${context.l10n.lastContactLabel(relativeLastContact)}',
      );
    }
    if (tags.isNotEmpty) {
      semanticsBuffer.write(', ${tags.join(', ')}');
    }
    if (hasConcern) {
      semanticsBuffer.write(', ${context.l10n.concernFlaggedSemanticsSuffix}');
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticsBuffer.toString(),
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasConcern)
                      Tooltip(
                        message: context.l10n.concernFlaggedTooltip,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: scheme.secondary,
                          semanticLabel: context.l10n.concernLabel,
                        ),
                      ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final tag in tags)
                        Chip(
                          label: Text(tag),
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
                if (relativeLastContact != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.lastContactLabel(relativeLastContact),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textSubColor,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — AC4
// ---------------------------------------------------------------------------

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({required this.onAddFriend});

  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            context.l10n.emptyFriendsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.emptyFriendsSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add),
            label: Text(context.l10n.addFirstFriend),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag filter chips bar — Story 8.1 AC1, AC2, AC3, AC7
// ---------------------------------------------------------------------------

class _TagFilterChipsBar extends StatelessWidget {
  const _TagFilterChipsBar({
    required this.tags,
    required this.activeTags,
    required this.onTagToggled,
  });

  final List<String> tags;
  final Set<String> activeTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBackground = isDark
        ? AppTokens.darkOutline.withValues(alpha: 0.22)
        : AppTokens.lightOutline.withValues(alpha: 0.32);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final tag in tags) ...[
            Semantics(
              label: l10n.filterByTagSemantics(
                tag,
                activeTags.contains(tag)
                    ? l10n.chipStateSelected
                    : l10n.chipStateNotSelected,
              ),
              child: FilterChip(
                label: Text(tag),
                selected: activeTags.contains(tag),
                onSelected: (_) => onTagToggled(tag),
                selectedColor: scheme.primary,
                checkmarkColor: scheme.onPrimary,
                backgroundColor: unselectedBackground,
                labelStyle: TextStyle(
                  color: activeTags.contains(tag)
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtered empty state — Story 8.1 AC4
// ---------------------------------------------------------------------------

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            context.l10n.noFriendsWithTagsYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            context.l10n.noFriendNamedSearch(query),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status filter bottom sheet — Story 8.3 AC1, AC4, AC6
// ---------------------------------------------------------------------------

/// Bottom sheet that lets the user toggle status-based filters on the friend list.
///
/// Opens via the funnel icon in [FriendsListScreen] AppBar.
/// Changes take effect immediately (reactive Riverpod state) and are visible
/// once the sheet is dismissed.
class StatusFilterSheet extends ConsumerWidget {
  const StatusFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef sheetRef) {
    final activeFilters = sheetRef.watch(activeStatusFiltersProvider);
    final l10n = context.l10n;

    void toggle(StatusFilter filter) {
      final notifier = sheetRef.read(activeStatusFiltersProvider.notifier);
      final current = sheetRef.read(activeStatusFiltersProvider);
      if (current.contains(filter)) {
        notifier.state = <StatusFilter>{...current}..remove(filter);
      } else {
        notifier.state = <StatusFilter>{...current, filter};
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.statusFilterSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(l10n.statusFilterActiveConcern),
              value: activeFilters.contains(StatusFilter.activeConcern),
              onChanged: (_) => toggle(StatusFilter.activeConcern),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            SwitchListTile(
              title: Text(l10n.statusFilterOverdueEvent),
              value: activeFilters.contains(StatusFilter.overdueEvent),
              onChanged: (_) => toggle(StatusFilter.overdueEvent),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            SwitchListTile(
              title: Text(l10n.statusFilterNoRecentContact),
              value: activeFilters.contains(StatusFilter.noRecentContact),
              onChanged: (_) => toggle(StatusFilter.noRecentContact),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            if (activeFilters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextButton(
                  onPressed: () {
                    sheetRef
                        .read(activeStatusFiltersProvider.notifier)
                        .state = const <StatusFilter>{};
                  },
                  child: Text(l10n.statusFilterClearAll),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status filter empty state — Story 8.3 AC2
// ---------------------------------------------------------------------------

class _StatusFilterEmptyState extends StatelessWidget {
  const _StatusFilterEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            context.l10n.noFriendsMatchingStatus,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
