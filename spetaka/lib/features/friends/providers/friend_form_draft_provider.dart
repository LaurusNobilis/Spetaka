import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/friend_form_draft.dart';

part 'friend_form_draft_provider.g.dart';

/// Riverpod notifier holding the in-memory session draft for [FriendFormScreen].
///
/// State is `null` when no draft is active. Survives app-switch
/// (`AppLifecycleState.paused`/`resumed`) but is intentionally lost on
/// process kill (architecture addendum Q5).
@Riverpod(keepAlive: true)
class FriendFormDraftNotifier extends _$FriendFormDraftNotifier {
  @override
  FriendFormDraft? build() => null;

  void update(FriendFormDraft draft) => state = draft;

  void clear() => state = null;
}
