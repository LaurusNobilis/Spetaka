import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';

/// Friends list screen — Story 2.5 will flesh out the list view.
///
/// For Story 2.1, the screen provides the entry point to add a friend
/// via the floating action button (navigates to [NewFriendRoute]).
class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: const Center(
        child: Text(
          'No friends yet.\nTap + to add your first friend.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => const NewFriendRoute().push(context),
        tooltip: 'Add friend',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
