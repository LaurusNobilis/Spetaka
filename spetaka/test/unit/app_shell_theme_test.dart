import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore_for_file: directives_ordering
import 'package:spetaka/core/router/app_router.dart';
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
