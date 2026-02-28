import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../features/events/data/event_repository_provider.dart';
import '../../features/events/presentation/add_event_screen.dart';
import '../../features/events/presentation/edit_event_screen.dart';
import '../../features/events/presentation/manage_event_types_screen.dart';
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

class EditEventRoute extends AppRoute {
  const EditEventRoute({required this.friendId, required this.eventId});

  final String friendId;
  final String eventId;

  @override
  String get location => '/friends/$friendId/events/$eventId/edit';
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

class ManageEventTypesRoute extends AppRoute {
  const ManageEventTypesRoute();

  @override
  String get location => '/settings/event-types';
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
                    GoRoute(
                      path: 'events/:eventId/edit',
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is Event) {
                          return EditEventScreen(event: extra);
                        }
                        final eventId = state.pathParameters['eventId'] ?? '';
                        return _EditEventRouteLoader(eventId: eventId);
                      },
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
                GoRoute(
                  path: 'event-types',
                  builder: (context, state) =>
                      const ManageEventTypesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

final GoRouter appRouter = createAppRouter();

class _EditEventRouteLoader extends ConsumerWidget {
  const _EditEventRouteLoader({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Event')),
        body: const Center(child: Text('Invalid event id.')),
      );
    }

    final future = ref.read(eventRepositoryProvider).findById(eventId);
    return FutureBuilder<Event?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Event')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Event')),
            body: const Center(child: Text('Could not load event.')),
          );
        }
        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Event')),
            body: const Center(child: Text('Event not found.')),
          );
        }
        return EditEventScreen(event: event);
      },
    );
  }
}

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
