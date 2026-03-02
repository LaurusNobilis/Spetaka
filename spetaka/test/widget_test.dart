// This is a basic Flutter scaffold smoke test.
//
// To run: flutter test
// Expected: AppShell renders without exceptions — confirms dependency
// graph is wired correctly and the app shell starts with zero errors.
//
// Story 4.2: DailyViewScreen replaced the placeholder so tests now stub
// allFriendsProvider + watchPriorityInputEventsProvider to avoid leaving
// open Drift stream timers (which fail the test harness teardown).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/events/data/events_providers.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/shared/theme/app_theme.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';

/// Minimal router scaffold with stubbed stream providers so the
/// DailyViewScreen (root route) renders immediately without Drift timers.
Widget _appScaffold() => ProviderScope(
      overrides: [
        allFriendsProvider.overrideWith(
          (_) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (_) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        title: 'Spetaka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: createAppRouter(),
      ),
    );

void main() {
  group('SpetakaApp — scaffold smoke tests', () {
    testWidgets('App renders without exceptions (AC: 1)', (tester) async {
      await tester.pumpWidget(_appScaffold());
      await tester.pump();
      // Verify MaterialApp widget tree is present
      expect(find.byType(MaterialApp), findsAtLeastNWidgets(1));
    });

    testWidgets('Daily view screen is visible after boot (AC: 6)',
        (tester) async {
      await tester.pumpWidget(_appScaffold());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Root route renders the DailyViewScreen — confirms navigation scaffold boots
      expect(find.text('Daily'), findsAtLeastNWidgets(1));
    });
  });
}

