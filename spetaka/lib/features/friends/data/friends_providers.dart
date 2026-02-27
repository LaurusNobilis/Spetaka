import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/friends/data/friend_repository_provider.dart';

/// Minimal reactive provider that streams all friends for the list screen.
///
/// Why stream (not Future)? In GoRouter nested routes, `/friends` stays mounted
/// while `/friends/new` is on top. A Future-based provider would NOT refresh
/// automatically after an insert, breaking Story 2.2 AC5.
///
/// NOTE: Story 2.5 still owns the full list UX (tiles, search, sort).
final allFriendsProvider = StreamProvider.autoDispose<List<Friend>>((ref) {
  return ref.watch(friendRepositoryProvider).watchAll();
});

/// Loads a single friend record by id for detail pages.
///
/// Story 2.3 only needs tags display; Story 2.6 will expand the full detail UX.
final friendByIdProvider = FutureProvider.autoDispose.family<Friend?, String>((
  ref,
  id,
) {
  return ref.watch(friendRepositoryProvider).findById(id);
});

