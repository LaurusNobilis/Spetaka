import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore_for_file: directives_ordering
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:spetaka/features/friends/data/friend_repository_provider.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/shared/theme/app_tokens.dart';
import 'package:spetaka/shared/theme/app_theme.dart';
import 'package:spetaka/shared/widgets/app_error_widget.dart';
import 'package:spetaka/shared/widgets/loading_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Disable network fetching in tests — fonts fall back to system default.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ── AppTokens ───────────────────────────────────────────────────────────

  group('AppTokens', () {
    test('light palette primary is terracotta', () {
      expect(AppTokens.lightPrimary, const Color(0xFFC47B5A));
    });

    test('light palette secondary is sage', () {
      expect(AppTokens.lightSecondary, const Color(0xFF7D9E8C));
    });

    test('dark background avoids cold grey', () {
      // Must be warm brown, not cold grey (#121212 or similar)
      const bg = AppTokens.darkBackground;
      // red channel >= blue channel for warmth (floating-point 0.0–1.0)
      expect(bg.r, greaterThanOrEqualTo(bg.b));
    });

    test('card radius is 14dp', () {
      expect(AppTokens.radiusCard, 14.0);
    });

    test('normal motion is 300ms', () {
      expect(AppTokens.motionNormal.inMilliseconds, 300);
    });

    test('spacing LG is at least 20dp', () {
      expect(AppTokens.spaceLG, greaterThanOrEqualTo(20.0));
    });

    test('font family body is DM Sans', () {
      expect(AppTokens.fontBody, 'DM Sans');
    });

    test('font family display is Lora', () {
      expect(AppTokens.fontDisplay, 'Lora');
    });
  });

  // ── AppTheme ────────────────────────────────────────────────────────────

  group('AppTheme', () {
    test('light() returns ThemeData with M3 enabled', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('dark() returns ThemeData with M3 enabled and dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('dark theme surface is warm brown, not cold grey', () {
      final theme = AppTheme.dark();
      final surface = theme.colorScheme.surface;
      // warm brown has red > blue (floating-point 0.0–1.0)
      expect(surface.r, greaterThanOrEqualTo(surface.b));
    });

    test('light theme card shape uses 14dp radius', () {
      final theme = AppTheme.light();
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder?;
      expect(cardShape, isNotNull);
      final br = (cardShape!.borderRadius as BorderRadius).topLeft;
      expect(br.x, AppTokens.radiusCard);
    });
  });

  // ── appRouter ───────────────────────────────────────────────────────────

  group('appRouter routes', () {
    RouteBase? findRoute(List<RouteBase> routes, String path) {
      for (final r in routes) {
        if (r is GoRoute && r.path == path) return r;
        if (r is GoRoute && r.routes.isNotEmpty) {
          final found = findRoute(r.routes, path);
          if (found != null) return found;
        }
      }
      return null;
    }

    test('root route "/" exists', () {
      final root = appRouter.configuration.routes.first as GoRoute;
      expect(root.path, '/');
    });

    test('friends route exists', () {
      final found = findRoute(appRouter.configuration.routes, 'friends');
      expect(found, isNotNull);
    });

    test('friends/new route exists', () {
      final found = findRoute(appRouter.configuration.routes, 'new');
      expect(found, isNotNull);
    });

    test('friends/:id route exists', () {
      final found = findRoute(appRouter.configuration.routes, ':id');
      expect(found, isNotNull);
    });

    test('settings route exists', () {
      final found = findRoute(appRouter.configuration.routes, 'settings');
      expect(found, isNotNull);
    });

    test('settings/sync route exists', () {
      final found = findRoute(appRouter.configuration.routes, 'sync');
      expect(found, isNotNull);
    });
  });

  group('appRouter navigation', () {
    /// Pump a full app with a real router; optionally pre-seed the friends
    /// list provider so /friends renders without a real DB connection.
    Future<void> pumpAppWithRouter(
      WidgetTester tester,
      GoRouter router, {
      bool stubFriendsList = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (stubFriendsList)
              allFriendsProvider.overrideWith((ref) => Stream<List<Friend>>.value(const <Friend>[])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('can navigate to / (Daily)', (tester) async {
      final router = createAppRouter();
      await pumpAppWithRouter(tester, router);
      expect(find.text('Daily'), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to /friends (Friends)', (tester) async {
      final router = createAppRouter();
      // Override allFriendsProvider to avoid real DB access in this
      // navigation-only test. Story 2.2 AC5 is covered by widget tests.
      await pumpAppWithRouter(tester, router, stubFriendsList: true);
      router.go(const FriendsRoute().location);
      await tester.pumpAndSettle();
      expect(find.text('Friends'), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to /friends/new (Add Friend)', (tester) async {
      final router = createAppRouter();
      await pumpAppWithRouter(tester, router, stubFriendsList: true);
      router.go(const NewFriendRoute().location);
      await tester.pumpAndSettle();
      expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to /friends/:id (Friend <id>)', (tester) async {
      final router = createAppRouter();
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
      final enc = EncryptionService(lifecycleService: lifecycle);
      await enc.initialize('spetaka-router-test-pass');
      final repo = FriendRepository(db: db, encryptionService: enc);

      const id = 'abc-123';
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        Friend(
          id: id,
          name: 'Friend $id',
          mobile: '+33600000000',
          tags: null,
          notes: null,
          careScore: 0.0,
          isConcernActive: false,
          concernNote: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(repo),
            allFriendsProvider.overrideWith(
              (ref) => Stream<List<Friend>>.value(const <Friend>[]),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );

      router.go(const FriendDetailRoute(id).location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Friend $id'), findsAtLeastNWidgets(1));

      await db.close();
      enc.dispose();
      lifecycle.dispose();
    });

    testWidgets('can navigate to /settings (Settings)', (tester) async {
      final router = createAppRouter();
      await pumpAppWithRouter(tester, router);
      router.go(const SettingsRoute().location);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to /settings/sync (Sync)', (tester) async {
      final router = createAppRouter();
      await pumpAppWithRouter(tester, router);
      router.go(const SettingsSyncRoute().location);
      await tester.pumpAndSettle();
      expect(find.text('Sync'), findsAtLeastNWidgets(1));
    });
  });

  // ── LoadingWidget ───────────────────────────────────────────────────────

  group('LoadingWidget', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: LoadingWidget()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: LoadingWidget(label: 'Loading…')),
        ),
      );
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('no label rendered when omitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: LoadingWidget()),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  // ── AppErrorWidget ──────────────────────────────────────────────────────

  group('AppErrorWidget', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppErrorWidget(message: 'Something went wrong'),
          ),
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows Retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Oops',
              onRetry: () {},
            ),
          ),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('no Retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppErrorWidget(message: 'Oops'),
          ),
        ),
      );
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('onRetry callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Oops',
              onRetry: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });
  });
}
