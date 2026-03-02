import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/actions/contact_action_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/lifecycle/app_lifecycle_service.dart';
import '../../../core/router/app_router.dart';
import '../../../features/acquittement/data/acquittement_providers.dart';
import '../../../features/acquittement/domain/pending_action_state.dart';
import '../../../features/acquittement/presentation/acquittement_sheet.dart';
import '../../../features/acquittement/presentation/manual_acquittement_button.dart';
import '../../../features/events/data/event_repository_provider.dart';
import '../../../features/events/data/event_type_providers.dart';
import '../../../features/events/data/events_providers.dart';
import '../../../features/events/domain/event_type.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friend_repository_provider.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

// ---------------------------------------------------------------------------
// Contact-history display constants (Story 5-4)
// ---------------------------------------------------------------------------

const _kHistoryTypeIcons = <String, IconData>{
  'call': Icons.phone_outlined,
  'sms': Icons.sms_outlined,
  'whatsapp': Icons.chat_outlined,
  'vocal': Icons.mic_none_outlined,
  'in_person': Icons.people_outline,
};

const _kHistoryTypeLabels = <String, String>{
  'call': 'Appel',
  'sms': 'SMS',
  'whatsapp': 'WhatsApp',
  'vocal': 'Vocal',
  'in_person': 'En personne',
};

/// Friend card detail screen — Stories 2.6, 2.8 & 2.9.
///
/// AC implementation map:
///   AC1 (2.6): name, formatted mobile, tags, notes, concern note, events placeholder,
///        contact history placeholder.
///   AC2 (2.6): Call / SMS / WhatsApp action buttons (placeholder — wired in Epic 5).
///   AC3 (2.6): reactive stream (watchFriendByIdProvider) ensures < 300ms from DB.
///   AC4 (2.6): Edit icon-button in AppBar → EditFriendRoute(id).
///   AC5 (2.6): StreamProvider auto-refreshes on SQLite updates without manual reload.
///   AC1 (2.8): Delete icon-button in AppBar opens DeleteConfirmDialog.
///   AC2 (2.8): Confirmed deletion calls FriendRepository.delete (cascade acquittements).
///   AC3 (2.8): Dialog states friend name + irreversible history-loss warning.
///   AC4 (2.8): Confirm → FriendsRoute; cancel leaves detail view unchanged.
///   AC5 (2.8): Deletion persistent after app restart (SQLite persisted).
///   AC1 (2.9): "Flag concern" button opens dialog; submits setConcern(id, note).
///   AC2 (2.9): Concern indicator + note rendered when isConcernActive; icon on list tile.
///   AC3 (2.9): "Clear concern" TextButton opens confirmation; calls clearConcern(id).
///   AC4 (2.9): watchAll/watchById streams expose isConcernActive for Epic 4 engine.
///   AC5 (5.2): Subscribe to pendingActionStream; open sheet on friend-card origin.
///   AC6 (5.2): ManualAcquittementButton always visible as OEM fallback.
class FriendCardScreen extends ConsumerWidget {
  const FriendCardScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFriend = ref.watch(watchFriendByIdProvider(id));

    return asyncFriend.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingWidget()),
      ),
      error: (err, _) {
        final message = err is AppError
            ? errorMessageFor(err)
            : 'Something went wrong. Please try again.';
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.friendTitle)),
          body: Center(child: AppErrorWidget(message: message)),
        );
      },
      data: (friend) {
        if (friend == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.friendTitle)),
            body: const Center(
              child: AppErrorWidget(message: 'Friend not found.'),
            ),
          );
        }
        return _FriendDetailBody(friend: friend);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body — shown when friend is loaded
// ---------------------------------------------------------------------------

class _FriendDetailBody extends ConsumerStatefulWidget {
  const _FriendDetailBody({required this.friend});

  final Friend friend;

  @override
  ConsumerState<_FriendDetailBody> createState() => _FriendDetailBodyState();
}

class _FriendDetailBodyState extends ConsumerState<_FriendDetailBody> {
  StreamSubscription<PendingActionState>? _pendingSub;

  Friend get friend => widget.friend;

  @override
  void initState() {
    super.initState();
    // Story 5-2 AC5: subscribe to return-detection stream.
    // Handles only friend-card origin events for this friend.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pendingSub = ref
          .read(appLifecycleServiceProvider)
          .pendingActionStream
          .listen(_onPendingAction);
    });
  }

  void _onPendingAction(PendingActionState state) {
    if (!mounted) return;
    // Only handle events for THIS friend card from friend-card origin.
    if (state.origin != AcquittementOrigin.friendCard) return;
    if (state.friendId != friend.id) return;

    showAcquittementSheet(
      context: context,
      ref: ref,
      pendingState: state,
    );
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    super.dispose();
  }

  // 2.8/AC1,AC3: show confirmation dialog before deleting.
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.deleteFriendTitle),
            content: Text(
              'Delete "${friend.name}"? '  
              'All contact history will be permanently removed and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.actionDelete),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 2.8/AC2,AC4: delete friend + cascade, then navigate to list.
  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    await ref.read(friendRepositoryProvider).delete(friend.id);
    if (context.mounted) const FriendsRoute().go(context);
  }

  // 2.9/AC1: set concern flag with optional note.
  Future<void> _handleSetConcern(BuildContext context) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.flagConcernTitle),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: context.l10n.optionalNoteHint,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.actionFlag),
              ),
            ],
          ),
        ) ??
        false;
    final note = noteController.text;
    noteController.dispose();
    if (!confirmed || !context.mounted) return;
    await ref
        .read(friendRepositoryProvider)
        .setConcern(friend.id, note: note);
  }

  // 2.9/AC3: clear concern with confirmation.
  Future<void> _handleClearConcern(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.clearConcernTitle),
            content: const Text(
                'Remove the concern flag and its note for this friend?',),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.clearConcernAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await ref.read(friendRepositoryProvider).clearConcern(friend.id);
  }

  @override
  Widget build(BuildContext context) {
    final tags = decodeFriendTags(friend.tags);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(friend.name),
            // 4.5: Demo badge visible in AppBar when isDemo = true.
            if (friend.isDemo) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(context.l10n.demoLabel),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.amber.shade100,
                side: const BorderSide(color: Colors.amber),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
        actions: [
          // 2.6/AC4: Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: context.l10n.actionEdit,
            onPressed: () => EditFriendRoute(friend.id).push(context),
          ),
          // 2.8/AC1: Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: context.l10n.actionDelete,
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4.5: Demo info banner shown only for Sophie (isDemo = true).
            if (friend.isDemo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.l10n.demoFriendDescription,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Contact action row — Story 5.1 ────────────────────────────
            _ActionButtonRow(
              friendId: friend.id,
              mobile: friend.mobile,
              actionService: ref.read(contactActionServiceProvider),
            ),
            const SizedBox(height: 8),

            // ── Story 5.2: OEM fallback manual acquittement button ────────
            ManualAcquittementButton(friendId: friend.id),
            const SizedBox(height: 24),

            // ── Mobile — AC1 ─────────────────────────────────────────────────
            _DetailSection(
              title: context.l10n.mobileSection,
              child: SelectableText(
                friend.mobile,
                style: textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),

            // ── Tags — AC1 ───────────────────────────────────────────────────
            _DetailSection(
              title: context.l10n.tagsSection,
              child: tags.isEmpty
                  ? Text(
                      context.l10n.noTags,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags) Chip(label: Text(tag)),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // ── Notes — AC1 ──────────────────────────────────────────────────
            if (friend.notes != null && friend.notes!.isNotEmpty) ...[
              _DetailSection(
                title: context.l10n.notesLabel,
                child: Text(friend.notes!, style: textTheme.bodyMedium),
              ),
              const SizedBox(height: 20),
            ],

            // ── Concern — 2.9 (set when inactive / display+clear when active) ──
            if (!friend.isConcernActive) ...[
              // 2.9/AC1: button to activate concern flag.
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _handleSetConcern(context),
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  label: Text(context.l10n.flagConcernTitle),
                ),
              ),
            ] else ...[
              // 2.9/AC2: concern section with clear action (AC3).
              _DetailSection(
                title: context.l10n.concernLabel,
                titleColor: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.concernFlagActive,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (friend.concernNote != null &&
                        friend.concernNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        friend.concernNote!,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 10),
                    // 2.9/AC3: clear concern with confirmation.
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _handleClearConcern(context),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(context.l10n.clearConcernAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Events — Story 3.1 ────────────────────────────────────────
            _EventsSection(friendId: friend.id),
            const SizedBox(height: 20),

            // ── Contact history — Story 5.4 ───────────────────────────────
            _ContactHistorySection(friendId: friend.id),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact history section — Story 5.4
// ---------------------------------------------------------------------------

/// Reactive section that displays all acquittements for [friendId] in reverse
/// chronological order.
///
/// AC coverage (Story 5-4):
///   AC1: reverse chronological order via [watchAcquittementsProvider].
///   AC2: each row shows action icon, readable date, and note preview.
///   AC3: reactive — Drift watch query re-emits on every insert.
///   AC4: TalkBack Semantics label per row.
///   AC5: empty state handled gracefully.
class _ContactHistorySection extends ConsumerWidget {
  const _ContactHistorySection({required this.friendId});

  final String friendId;

  static final _dateFormat = DateFormat('d MMM yyyy\u202f•\u202fHH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(watchAcquittementsProvider(friendId));
    final theme = Theme.of(context);

    return _DetailSection(
      title: context.l10n.contactHistorySection,
      child: asyncHistory.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text(
          context.l10n.couldNotLoadHistory,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Semantics(
              label: context.l10n.noContactHistory,
              child: Text(
                context.l10n.noContactHistory,
                key: const Key('contact_history_empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          return Column(
            children: [
              for (final entry in entries)
                _HistoryRow(entry: entry, dateFormat: _dateFormat),
            ],
          );
        },
      ),
    );
  }
}

/// One row in the contact history section.
///
/// Renders action icon + readable date + optional note preview.
/// Wrapped in [Semantics] with a composed label for TalkBack (AC4).
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.dateFormat,
  });

  final Acquittement entry;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon =
        _kHistoryTypeIcons[entry.type] ?? Icons.contact_phone_outlined;
    final typeLabel = _kHistoryTypeLabels[entry.type] ?? entry.type;
    final dateStr = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
    );
    final rawNote = entry.note;
    final notePreview = rawNote != null && rawNote.isNotEmpty
        ? (rawNote.length > 40
            ? '${rawNote.substring(0, 40)}\u2026'
            : rawNote)
        : null;

    return Semantics(
      label: '$typeLabel — $dateStr'
          '${notePreview != null ? ' — $notePreview' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (notePreview != null) ...
                  [
                    const SizedBox(height: 2),
                    Text(
                      notePreview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button row — Story 5.1
// ---------------------------------------------------------------------------

class _ActionButtonRow extends StatefulWidget {
  const _ActionButtonRow({
    required this.friendId,
    required this.mobile,
    required this.actionService,
  });

  final String friendId;
  final String mobile;
  final ContactActionService actionService;

  @override
  State<_ActionButtonRow> createState() => _ActionButtonRowState();
}

class _ActionButtonRowState extends State<_ActionButtonRow> {
  String? _actionError;

  Future<void> _handleCall() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.call(
        widget.mobile,
        friendId: widget.friendId,
        origin: AcquittementOrigin.friendCard,
      );
    } on AppError catch (e) {
      if (mounted) setState(() => _actionError = errorMessageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _handleSms() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.sms(
        widget.mobile,
        friendId: widget.friendId,
        origin: AcquittementOrigin.friendCard,
      );
    } on AppError catch (e) {
      if (mounted) setState(() => _actionError = errorMessageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _handleWhatsApp() async {
    setState(() => _actionError = null);
    try {
      await widget.actionService.whatsapp(
        widget.mobile,
        friendId: widget.friendId,
        origin: AcquittementOrigin.friendCard,
      );
    } on AppError catch (e) {
      if (mounted) setState(() => _actionError = errorMessageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = 'Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.phone_outlined,
                label: context.l10n.callAction,
                onPressed: _handleCall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.sms_outlined,
                label: context.l10n.smsAction,
                onPressed: _handleSms,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.chat_outlined,
                label: context.l10n.whatsappAction,
                onPressed: _handleWhatsApp,
              ),
            ),
          ],
        ),
        if (_actionError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              _actionError!,
              key: const Key('action_error_text'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// Individual action button with 48×48dp minimum touch target and
/// TalkBack-readable semantics (AC8). Async action is properly awaited
/// so launch failures never produce unhandled exceptions.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
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
      label: widget.label,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _handlePress,
          icon: Icon(widget.icon),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.label),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events section — Stories 3.1, 3.3, 3.5
// ---------------------------------------------------------------------------

class _EventsSection extends ConsumerWidget {
  const _EventsSection({required this.friendId});

  final String friendId;

  static final _dateFormat = DateFormat('d MMM yyyy');

  /// Resolves a human-readable display label for an event type string.
  ///
  /// Priority: dynamic event_types table (case-insensitive match) → legacy
  /// EventType enum displayLabel → raw string as-is.
  static String _resolveTypeLabel(
    String rawType,
    List<EventTypeEntry> eventTypes,
  ) {
    final lowerType = rawType.toLowerCase();
    // 1. Try exact match from personalized event_types table.
    for (final et in eventTypes) {
      if (et.name == rawType) return et.name;
    }
    // 2. Try case-insensitive match (handles "birthday" vs "Birthday").
    for (final et in eventTypes) {
      if (et.name.toLowerCase() == lowerType) return et.name;
    }
    // 3. Try legacy enum displayLabel (e.g. "weddingAnniversary" → "Wedding Anniversary").
    final enumMatch = EventType.values
        .where((e) => e.name == rawType)
        .firstOrNull;
    if (enumMatch != null) return enumMatch.displayLabel;
    // 4. Fallback: raw string as-is.
    return rawType;
  }

  // 3.3 AC1: open prefilled edit form.
  void _handleEdit(BuildContext context, Event event) {
    context.push(
      EditEventRoute(friendId: friendId, eventId: event.id).location,
      extra: event,
    );
  }

  // 3.3 AC3: delete with confirmation; list updates reactively (AC4 via stream).
  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    Event event,
    List<EventTypeEntry> eventTypes,
  ) async {
    final typeLabel = _resolveTypeLabel(event.type, eventTypes);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.deleteEventTitle),
            content: Text(
              'Delete "$typeLabel" '
              'on ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(event.date))}? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.actionDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(eventRepositoryProvider).deleteEvent(event.id);
  }

  // 3.5 AC1: acknowledge event; recurring events auto-advance (AC3).
  Future<void> _handleAcknowledge(WidgetRef ref, Event event) async {
    await ref.read(eventRepositoryProvider).acknowledgeEvent(event.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(watchEventsByFriendProvider(friendId));
    // Story 3.4 AC6 (review fix): resolve type labels from dynamic event_types table.
    final asyncTypes = ref.watch(watchEventTypesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _DetailSection(
      title: context.l10n.eventsLabel,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: context.l10n.addEventAction,
        onPressed: () => AddEventRoute(friendId).push(context),
      ),
      child: asyncEvents.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text(
          context.l10n.couldNotLoadEvents,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.error),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Text(
              context.l10n.noEventsYet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            );
          }
          // Resolve event_types list — use empty list while loading (labels fall back gracefully).
          final eventTypes = asyncTypes.value ?? <EventTypeEntry>[];
          return Column(
            children: [
              for (final event in events)
                _EventRow(
                  event: event,
                  typeLabel: _resolveTypeLabel(event.type, eventTypes),
                  dateFormat: _dateFormat,
                  onEdit: () => _handleEdit(context, event),
                  onDelete: () => _handleDelete(context, ref, event, eventTypes),
                  onAcknowledge: () => _handleAcknowledge(ref, event),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.typeLabel,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onAcknowledge,
  });

  final Event event;
  /// Pre-resolved display label from the event_types table (AC6 review fix).
  final String typeLabel;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAcknowledge;

  static String _cadenceLabel(int days) => switch (days) {
        7 => 'Every week',
        14 => 'Every 2 weeks',
        21 => 'Every 3 weeks',
        30 => 'Monthly',
        60 => 'Every 2 months',
        90 => 'Every 3 months',
        _ => 'Every $days days',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Story 3.4 AC6 (review fix): typeLabel is now pre-resolved by
    // _EventsSection from the dynamic event_types table.
    final dateStr = dateFormat
        .format(DateTime.fromMillisecondsSinceEpoch(event.date));

    // 3.5 AC2: acknowledged one-time events shown with muted style + checkmark.
    final isDone = event.isAcknowledged && !event.isRecurring;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3.5 AC2: faded chip for acknowledged events.
          Opacity(
            opacity: isDone ? 0.45 : 1.0,
            child: Chip(
              label: Text(typeLabel),
              visualDensity: VisualDensity.compact,
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontSize: 12,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: isDone ? 0.55 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: theme.textTheme.bodyMedium),
                  if (event.isRecurring && event.cadenceDays != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.repeat, size: 13, color: colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          _cadenceLabel(event.cadenceDays!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.comment != null && event.comment!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.comment!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  // 3.5 AC2: acknowledged timestamp for one-time events.
                  if (isDone && event.acknowledgedAt != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 13,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Done ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(event.acknowledgedAt!))}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 3.3 / 3.5: popup menu — Edit, Mark done (or Recurring: advance), Delete.
          PopupMenuButton<_EventAction>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Event actions',
            itemBuilder: (ctx) => [
              if (!isDone)
                PopupMenuItem(
                  value: _EventAction.acknowledge,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.isRecurring
                            ? ctx.l10n.markDoneAdvance
                            : ctx.l10n.markAsDone,
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: _EventAction.edit,
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(ctx.l10n.actionEdit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _EventAction.delete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ctx.l10n.actionDelete,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _EventAction.edit:
                  onEdit();
                case _EventAction.delete:
                  onDelete();
                case _EventAction.acknowledge:
                  onAcknowledge();
              }
            },
          ),
        ],
      ),
    );
  }
}

enum _EventAction { edit, delete, acknowledge }


// ---------------------------------------------------------------------------
// Generic detail section
// ---------------------------------------------------------------------------

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.titleColor,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Color? titleColor;

  /// Optional widget rendered at the end of the title row (e.g. action button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: titleColor ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
        Divider(
          height: 24,
          color: theme.colorScheme.outlineVariant,
        ),
      ],
    );
  }
}

