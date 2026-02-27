import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

/// Friend card detail screen — Story 2.6.
///
/// AC implementation map:
///   AC1: name, formatted mobile, tags, notes, concern note, events placeholder,
///        contact history placeholder.
///   AC2: Call / SMS / WhatsApp action buttons (placeholder — wired in Epic 5).
///   AC3: reactive stream (watchFriendByIdProvider) ensures < 300ms from DB.
///   AC4: Edit icon-button in AppBar → EditFriendRoute(id).
///   AC5: StreamProvider auto-refreshes on SQLite updates without manual reload.
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

class _FriendDetailBody extends StatelessWidget {
  const _FriendDetailBody({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final tags = decodeFriendTags(friend.tags);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(friend.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => EditFriendRoute(friend.id).push(context),
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

            // ── Concern — AC1 (shown only when concern is active) ─────────
            if (friend.isConcernActive) ...[
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Events — AC1 placeholder (Epic 3) ────────────────────────────
            _DetailSection(
              title: 'Events',
              child: Text(
                'No events yet. (Story 3.1)',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
// Generic detail section
// ---------------------------------------------------------------------------

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.titleColor,
  });

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: titleColor ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
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

