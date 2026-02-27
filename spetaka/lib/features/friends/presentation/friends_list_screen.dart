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

/// Friends list screen — Story 2.5.
///
/// AC1: scrollable `FriendCardTile` list backed by [allFriendsProvider].
/// AC2: tile shows name, category tags, concern indicator.
/// AC3: reactive [StreamProvider] backed by Drift `watchAll()`.
/// AC4: empty state prompts first-friend add.
/// AC5: data is stream-driven (no timer/polling), open time target respected.
/// AC6: `Semantics` labels for TalkBack navigation.
class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFriends = ref.watch(allFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: asyncFriends.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (err, _) {
          final message = err is AppError
              ? errorMessageFor(err)
              : 'Something went wrong. Please try again.';
          return Center(child: AppErrorWidget(message: message));
        },
        data: (friends) {
          if (friends.isEmpty) {
            return _EmptyFriendsState(
              onAddFriend: () => const NewFriendRoute().push(context),
            );
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return FriendCardTile(
                friend: friend,
                onTap: () => FriendDetailRoute(friend.id).push(context),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => const NewFriendRoute().push(context),
        tooltip: 'Add friend',
        child: const Icon(Icons.person_add),
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
    required this.onTap,
  });

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tags = decodeFriendTags(friend.tags);
    final hasConcern = friend.isConcernActive;

    // AC6: build a meaningful accessibility description.
    final semanticsBuffer = StringBuffer(friend.name);
    if (tags.isNotEmpty) {
      semanticsBuffer.write(', ${tags.join(', ')}');
    }
    if (hasConcern) {
      semanticsBuffer.write(', concern flagged');
    }

    return Semantics(
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
                      const Tooltip(
                        message: 'Concern flagged',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Colors.orange,
                          semanticLabel: 'Concern',
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
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No friends yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your first friend.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add),
            label: const Text('Add first friend'),
          ),
        ],
      ),
    );
  }
}

