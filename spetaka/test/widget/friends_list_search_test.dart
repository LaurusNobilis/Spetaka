import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/acquittement/data/acquittement_providers.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friends_list_screen.dart';

Friend makeFriend({
  required String id,
  required String name,
  String? tags,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: tags,
    notes: null,
    careScore: 0.0,
    isConcernActive: false,
    concernNote: null,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

Widget buildHarness({required List<Friend> friends}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const FriendsListScreen(),
      ),
      GoRoute(
        path: '/friends/:id',
        builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/friends/new',
        builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      allFriendsProvider.overrideWith((_) => Stream.value(friends)),
      lastContactByFriendProvider.overrideWith(
        (_) => Stream.value(const <String, int>{}),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

Future<void> settleShell(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<GoRouter> pumpShellHarness(
  WidgetTester tester, {
  required List<Friend> friends,
}) async {
  final router = createAppRouter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchDailyViewProvider.overrideWith(
          (_) => const AsyncData(<DailyViewEntry>[]),
        ),
        allFriendsProvider.overrideWith((_) => Stream.value(friends)),
        lastContactByFriendProvider.overrideWith(
          (_) => Stream.value(const <String, int>{}),
        ),
        watchAcquittementsProvider.overrideWith(
          (ref, _) => Stream.value(const <Acquittement>[]),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
  await tester.pumpAndSettle();

  return router;
}

void main() {
  group('FriendsListScreen search — Story 8.2', () {
    testWidgets('shows inline search field when tapping search icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice'),
            makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('typing filters the list in real time', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice'),
            makeFriend(id: 'f2', name: 'Bob'),
            makeFriend(id: 'f3', name: 'Alicia'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), ' ali ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Alicia'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('search composes with tag filters as an intersection', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice Family', tags: '["Family"]'),
            makeFriend(id: 'f2', name: 'Alice Work', tags: '["Work"]'),
            makeFriend(id: 'f3', name: 'Bob Family', tags: '["Family"]'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice Family'), findsOneWidget);
      expect(find.text('Alice Work'), findsNothing);
      expect(find.text('Bob Family'), findsNothing);
    });

    testWidgets('shows localized empty state when search has no results', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice'),
            makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'zoe');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No friend named "zoe" in your circle.'), findsOneWidget);
    });

    testWidgets('clear icon resets search and restores full list', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice'),
            makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('Android back clears search before leaving the list', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          friends: [
            makeFriend(id: 'f1', name: 'Alice'),
            makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('navigation away from Friends clears search state', (
      tester,
    ) async {
      await pumpShellHarness(
        tester,
        friends: [
          makeFriend(id: 'f1', name: 'Alice'),
          makeFriend(id: 'f2', name: 'Bob'),
        ],
      );

      expect(find.text('Friends'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await settleShell(tester);
      expect(find.text('Daily'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('Android back in shell clears active search before leaving Friends', (
      tester,
    ) async {
      await pumpShellHarness(
        tester,
        friends: [
          makeFriend(id: 'f1', name: 'Alice'),
          makeFriend(id: 'f2', name: 'Bob'),
        ],
      );

      expect(find.text('Friends'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.binding.handlePopRoute();
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('settings overlay navigation clears search state on return', (
      tester,
    ) async {
      final router = await pumpShellHarness(
        tester,
        friends: [
          makeFriend(id: 'f1', name: 'Alice'),
          makeFriend(id: 'f2', name: 'Bob'),
        ],
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.tap(find.byTooltip('Settings'));
      await settleShell(tester);

      expect(find.text('Settings'), findsOneWidget);

      router.pop();
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('search field exposes localized semantics label', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          buildHarness(
            friends: [makeFriend(id: 'f1', name: 'Alice')],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final semantics = tester.getSemantics(find.byType(TextField));
        expect(semantics.label, contains('Search friends by name'));
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}