import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/friends_providers.dart';
import '../domain/friend_tags_codec.dart';

/// Friend detail screen — minimal tag display for Story 2.3.
///
/// Story 2.6 owns the full detail view.
class FriendCardScreen extends ConsumerWidget {
  const FriendCardScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendAsync = ref.watch(friendByIdProvider(id));

    return friendAsync.when(
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

        final tags = decodeFriendTags(friend.tags);

        return Scaffold(
          appBar: AppBar(title: Text(friend.name)),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (tags.isEmpty)
                  const Text('No tags')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in tags) Chip(label: Text(tag)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
