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
import '../../features/settings/presentation/manage_category_tags_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
import '../l10n/l10n_extension.dart';
import 'app_route_types.dart';

// Re-export route types so existing `import app_router.dart` consumers
// continue to resolve AppRoute, HomeRoute, FriendsRoute, etc.
export 'app_route_types.dart';

GoRouter createAppRouter({
  WidgetBuilder? modelDownloadBuilder,
  String initialLocation = '/',
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
      initialLocation: initialLocation,
      navigatorKey: rootNavigatorKey,
      routes: <RouteBase>[
        // Model download gate — overlays the shell (Story 10.1 AC5).
        GoRoute(
          path: const ModelDownloadRoute().location,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              modelDownloadBuilder != null
                  ? modelDownloadBuilder(context)
                  : const SizedBox.shrink(),
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => AppShellScreen(child: child),
          routes: <RouteBase>[
            // Base index routes — AppShellScreen decides which page to show.
            GoRoute(
              path: const HomeRoute().location,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: SizedBox.shrink(),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'settings',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const SettingsScreen(),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'sync',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WebDavSetupScreen(),
                    ),
                    GoRoute(
                      path: 'event-types',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ManageEventTypesScreen(),
                    ),
                    GoRoute(
                      path: 'category-tags',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ManageCategoryTagsScreen(),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: const FriendsRoute().location,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: SizedBox.shrink(),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const FriendFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => FriendCardScreen(
                    id: state.pathParameters['id'] ?? '',
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => FriendFormScreen(
                        editFriendId: state.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'events/new',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => AddEventScreen(
                        friendId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                    GoRoute(
                      path: 'events/:eventId/edit',
                      parentNavigatorKey: rootNavigatorKey,
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
          ],
        ),
      ],
    );
}

// Stub router instance used by tests that import app_router.dart directly.
// The production router (with the real ModelDownloadScreen) is built in
// app.dart where flutter_gemma is explicitly imported.
//
// ignore: prefer_const_constructors
final GoRouter appRouter = createAppRouter();

class _EditEventRouteLoader extends ConsumerWidget {
  const _EditEventRouteLoader({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.editEventTitle)),
        body: Center(child: Text(context.l10n.invalidEventIdMessage)),
      );
    }

    final future = ref.read(eventRepositoryProvider).findById(eventId);
    return FutureBuilder<Event?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.editEventTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.editEventTitle)),
            body: Center(child: Text(context.l10n.couldNotLoadEventMessage)),
          );
        }
        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.editEventTitle)),
            body: Center(child: Text(context.l10n.eventNotFoundMessage)),
          );
        }
        return EditEventScreen(event: event);
      },
    );
  }
}

class WebDavSetupScreen extends StatelessWidget {
  const WebDavSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(title: context.l10n.syncSectionTitle);
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
