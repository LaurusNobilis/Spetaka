// Features barrel — each sub-directory owns a bounded feature module.
// Sub-packages added story-by-story.

// Daily feature — Stories 4.1 / 4.2 / 4.3
export 'daily/data/daily_view_provider.dart';
export 'daily/domain/priority_engine.dart';
export 'daily/presentation/daily_view_screen.dart';
export 'daily/presentation/heart_briefing_widget.dart';

// Friends feature — Story 2.1
export 'friends/data/friend_repository.dart';
export 'friends/data/friend_repository_provider.dart';
export 'friends/domain/friend.dart';
export 'friends/domain/friend_tags_codec.dart';
export 'friends/presentation/friend_card_screen.dart';
export 'friends/presentation/friend_form_screen.dart';
export 'friends/presentation/friends_list_screen.dart';
