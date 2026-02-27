import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/friends_providers.dart';

/// Friends list screen — minimal list rendering for Story 2.2.
///
/// Shows friend names loaded via [allFriendsFutureProvider].  An empty state
/// message is shown when no friends exist.  The full tile design (avatar,
/// tags, priority score) is Story 2.5.
class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFriends = ref.watch(allFriendsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: asyncFriends.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
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
              return ListTile(
                title: Text(friend.name),
                subtitle: Text(friend.mobile),
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

