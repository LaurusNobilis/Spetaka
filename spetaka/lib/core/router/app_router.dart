import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/events/presentation/add_event_screen.dart';
import '../../features/friends/presentation/friend_card_screen.dart';
import '../../features/friends/presentation/friend_form_screen.dart';
import '../../features/friends/presentation/friends_list_screen.dart';

sealed class AppRoute {
  const AppRoute();

  String get location;

  void go(BuildContext context) => context.go(location);

  void push(BuildContext context) => context.push(location);
}

class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  String get location => '/';
}

class FriendsRoute extends AppRoute {
  const FriendsRoute();

  @override
  String get location => '/friends';
}

class NewFriendRoute extends AppRoute {
  const NewFriendRoute();

  @override
  String get location => '/friends/new';
}

class FriendDetailRoute extends AppRoute {
  const FriendDetailRoute(this.id);

  final String id;

  @override
  String get location => '/friends/$id';
}

class EditFriendRoute extends AppRoute {
  const EditFriendRoute(this.id);

  final String id;

  @override
  String get location => '/friends/$id/edit';
}

class AddEventRoute extends AppRoute {
  const AddEventRoute(this.friendId);

  final String friendId;

  @override
  String get location => '/friends/$friendId/events/new';
}

class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  String get location => '/settings';
}

class SettingsSyncRoute extends AppRoute {
  const SettingsSyncRoute();

  @override
  String get location => '/settings/sync';
}

GoRouter createAppRouter() => GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: const HomeRoute().location,
          builder: (context, state) => const DailyViewScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'friends',
              builder: (context, state) => const FriendsListScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const FriendFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => FriendCardScreen(
                    id: state.pathParameters['id'] ?? '',
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => FriendFormScreen(
                        editFriendId: state.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'events/new',
                      builder: (context, state) => AddEventScreen(
                        friendId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'sync',
                  builder: (context, state) => const WebDavSetupScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

final GoRouter appRouter = createAppRouter();

class DailyViewScreen extends StatelessWidget {
  const DailyViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(title: 'Daily');
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(title: 'Settings');
  }
}

class WebDavSetupScreen extends StatelessWidget {
  const WebDavSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(title: 'Sync');
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
