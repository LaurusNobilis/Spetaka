// Features barrel — each sub-directory owns a bounded feature module.
// Sub-packages added story-by-story.

// Friends feature — Story 2.1
export 'friends/data/friend_repository.dart';
export 'friends/data/friend_repository_provider.dart';
export 'friends/domain/friend.dart';
export 'friends/domain/friend_tags_codec.dart';
export 'friends/presentation/friend_card_screen.dart';
export 'friends/presentation/friend_form_screen.dart';
export 'friends/presentation/friends_list_screen.dart';
