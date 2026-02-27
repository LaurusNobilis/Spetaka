import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'friend_repository_provider.dart';

/// Minimal provider that fetches all friends for the list screen.
///
/// autoDispose — re-fetches from the repository whenever the screen re-enters
/// the widget tree (e.g. after a save navigates back to /friends).
///
/// NOTE: Story 2.5 will replace this with a full reactive Stream-based
/// provider with search, sorting and pagination.  Do NOT expand this here.
final allFriendsFutureProvider = FutureProvider.autoDispose<List<Friend>>((ref) {
  return ref.watch(friendRepositoryProvider).findAll();
});
