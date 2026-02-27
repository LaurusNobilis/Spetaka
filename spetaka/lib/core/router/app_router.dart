import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

sealed class AppRoute {
  const AppRoute();

  String get location;
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

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: const HomeRoute().location,
      builder: (context, state) => const _PlaceholderScreen(title: 'Daily'),
      routes: <RouteBase>[
        GoRoute(
          path: 'friends',
          builder: (context, state) => const _PlaceholderScreen(title: 'Friends'),
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              builder: (context, state) => const _PlaceholderScreen(title: 'New Friend'),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => _PlaceholderScreen(
                title: 'Friend ${state.pathParameters['id']}',
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
          routes: <RouteBase>[
            GoRoute(
              path: 'sync',
              builder: (context, state) => const _PlaceholderScreen(title: 'Sync'),
            ),
          ],
        ),
      ],
    ),
  ],
);

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
