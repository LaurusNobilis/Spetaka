// Route type definitions — shared between app_router.dart and test code.
//
// Kept separate from app_router.dart so that tests can import the route
// classes without pulling in the full router (which transitively imports
// flutter_gemma via ModelDownloadScreen).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/presentation/app_shell_screen.dart';

sealed class AppRoute {
  const AppRoute();

  String get location;

  void go(BuildContext context) => context.go(location);

  void push(BuildContext context) => context.push(location);
}

bool isShellBasePath(String path) => path == '/' || path == '/friends';

class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  String get location => '/';

  @override
  void go(BuildContext context) {
    final shellController = AppShellScope.maybeOf(context);
    final currentPath = GoRouterState.of(context).uri.path;

    if (shellController != null && isShellBasePath(currentPath)) {
      shellController.showDaily();
      return;
    }

    super.go(context);
  }
}

class FriendsRoute extends AppRoute {
  const FriendsRoute();

  @override
  String get location => '/friends';

  @override
  void go(BuildContext context) {
    final shellController = AppShellScope.maybeOf(context);
    final currentPath = GoRouterState.of(context).uri.path;

    if (shellController != null && isShellBasePath(currentPath)) {
      shellController.showFriends();
      return;
    }

    super.go(context);
  }
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

class ManageCategoryTagsRoute extends AppRoute {
  const ManageCategoryTagsRoute();

  @override
  String get location => '/settings/category-tags';
}

class ModelDownloadRoute extends AppRoute {
  const ModelDownloadRoute();

  @override
  String get location => '/model-download';
}
