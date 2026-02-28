import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../../features/events/data/event_repository_provider.dart';
import '../../../features/events/data/events_providers.dart';
import '../../../features/events/domain/event_type.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friend_repository_provider.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

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
          appBar: AppBar(title: const Text('Friend')),
          body: Center(child: AppErrorWidget(message: message)),
        );
      },
      data: (friend) {
        if (friend == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Friend')),
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

class _FriendDetailBody extends ConsumerWidget {
  const _FriendDetailBody({required this.friend});

  final Friend friend;

  // 2.8/AC1,AC3: show confirmation dialog before deleting.
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete friend?'),
            content: Text(
              'Delete "${friend.name}"? '  
              'All contact history will be permanently removed and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 2.8/AC2,AC4: delete friend + cascade, then navigate to list.
  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    await ref.read(friendRepositoryProvider).delete(friend.id);
    if (context.mounted) const FriendsRoute().go(context);
  }

  // 2.9/AC1: set concern flag with optional note.
  Future<void> _handleSetConcern(BuildContext context, WidgetRef ref) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Flag concern'),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Optional note…',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Flag'),
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
  Future<void> _handleClearConcern(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear concern?'),
            content: const Text(
                'Remove the concern flag and its note for this friend?',),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await ref.read(friendRepositoryProvider).clearConcern(friend.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = decodeFriendTags(friend.tags);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(friend.name),
        actions: [
          // 2.6/AC4: Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => EditFriendRoute(friend.id).push(context),
          ),
          // 2.8/AC1: Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _handleDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact action row — AC2 (placeholder, Epic 5) ──────────────
            _ActionButtonRow(friendId: friend.id),
            const SizedBox(height: 24),

            // ── Mobile — AC1 ─────────────────────────────────────────────────
            _DetailSection(
              title: 'Mobile',
              child: SelectableText(
                friend.mobile,
                style: textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),

            // ── Tags — AC1 ───────────────────────────────────────────────────
            _DetailSection(
              title: 'Tags',
              child: tags.isEmpty
                  ? Text(
                      'No tags',
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
                title: 'Notes',
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
                  onPressed: () => _handleSetConcern(context, ref),
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  label: const Text('Flag concern'),
                ),
              ),
            ] else ...[
              // 2.9/AC2: concern section with clear action (AC3).
              _DetailSection(
                title: 'Concern',
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
                          'Concern flag is active',
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
                      onPressed: () => _handleClearConcern(context, ref),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Clear concern'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Events — Story 3.1 ────────────────────────────────────────
            _EventsSection(friendId: friend.id),
            const SizedBox(height: 20),

            // ── Contact history — AC1 placeholder (Epic 5)───────────────────
            _DetailSection(
              title: 'Contact History',
              child: Text(
                'No contact history yet. (Story 5.x)',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button row — AC2 placeholders
// ---------------------------------------------------------------------------

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.phone_outlined,
          label: 'Call',
          onPressed: null, // Epic 5 will wire ContactActionService
        ),
        _ActionButton(
          icon: Icons.sms_outlined,
          label: 'SMS',
          onPressed: null,
        ),
        _ActionButton(
          icon: Icons.chat_outlined,
          label: 'WhatsApp',
          onPressed: null,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label (coming soon)',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
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
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete event?'),
            content: Text(
              'Delete "${EventType.fromString(event.type).displayLabel}" '
              'on ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(event.date))}? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _DetailSection(
      title: 'Events',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Add event',
        onPressed: () => AddEventRoute(friendId).push(context),
      ),
      child: asyncEvents.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text(
          'Could not load events.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.error),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Text(
              'No events yet. Tap + to add one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            );
          }
          return Column(
            children: [
              for (final event in events)
                _EventRow(
                  event: event,
                  dateFormat: _dateFormat,
                  onEdit: () => _handleEdit(context, event),
                  onDelete: () => _handleDelete(context, ref, event),
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
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onAcknowledge,
  });

  final Event event;
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
    // Story 3.4: type label is now the raw string from the events table.
    // For legacy enum-style names (e.g. "regularCheckin"), fall back to the
    // EventType enum's displayLabel; otherwise display the string as-is.
    final typeLabel = EventType.values
            .where((e) => e.name == event.type)
            .firstOrNull
            ?.displayLabel ??
        event.type;
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
            itemBuilder: (_) => [
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
                            ? 'Mark done (advance)'
                            : 'Mark as done',
                      ),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: _EventAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _EventAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
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

