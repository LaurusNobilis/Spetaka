import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

/// Friends list screen — minimal list rendering for Story 2.2.
///
/// Shows friend names loaded via [allFriendsProvider]. An empty state message
/// is shown when no friends exist. The full tile design (avatar, tags, priority
/// score) is Story 2.5.
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
            return const Center(
              child: Text(
                'No friends yet.\nTap + to add your first friend.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final tags = decodeFriendTags(friend.tags);
              // Mobile omitted — PII; Story 2.5 owns the full tile design.
              return ListTile(
                title: Text(friend.name),
                subtitle: tags.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in tags) Chip(label: Text(tag)),
                          ],
                        ),
                      ),
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

