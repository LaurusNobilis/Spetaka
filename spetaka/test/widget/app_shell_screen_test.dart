import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/acquittement/data/acquittement_providers.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/events/data/event_type_providers.dart';
import 'package:spetaka/features/events/data/events_providers.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/shell/presentation/app_shell_screen.dart';


void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> settleShell(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<GoRouter> pumpShellApp(
    WidgetTester tester, {
    List<dynamic> overrides = const [],
  }) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchDailyViewProvider.overrideWith(
            (_) => const AsyncData(<DailyViewEntry>[]),
          ),
          allFriendsProvider.overrideWith(
            (_) => Stream<List<Friend>>.value(const <Friend>[]),
          ),
          lastContactByFriendProvider.overrideWith(
            (_) => Stream<Map<String, int>>.value(const <String, int>{}),
          ),
          ...overrides,
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    await settleShell(tester);
    return router;
  }

  testWidgets('swipe switches Daily → Friends', (tester) async {
    await pumpShellApp(tester);

    expect(find.text('Daily'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await settleShell(tester);

    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('Android back from Friends returns to Daily', (tester) async {
    await pumpShellApp(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await settleShell(tester);

    expect(find.text('Friends'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settleShell(tester);

    expect(find.text('Daily'), findsOneWidget);
  });

  testWidgets('page indicator has localized semantics label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShellApp(tester);

    expect(
      find.bySemanticsLabel(
        'Current page: Daily. Swipe left or right to switch pages.',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await settleShell(tester);

    expect(
      find.bySemanticsLabel(
        'Current page: Friends. Swipe left or right to switch pages.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets(
    'new friend overlay pushed from Daily returns to Daily without switching shell page',
    (tester) async {
      final router = await pumpShellApp(tester);

      expect(find.text('Daily'), findsOneWidget);

      router.push(const NewFriendRoute().location);
      await settleShell(tester);

      expect(find.text('Add Friend'), findsAtLeastNWidgets(1));

      router.pop();
      await settleShell(tester);

      expect(find.text('Daily'), findsOneWidget);
    },
  );

  testWidgets(
    'settings overlay pushed from Friends returns to Friends without switching shell page',
    (tester) async {
      final router = await pumpShellApp(tester);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);

      router.push(const SettingsRoute().location);
      await settleShell(tester);

      expect(find.text('Settings'), findsAtLeastNWidgets(1));

      router.pop();
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
    },
  );

  testWidgets(
    'friend detail pushed from Daily returns to Daily without switching shell page',
    (tester) async {
      const friendId = 'friend-1';
      final now = DateTime(2026, 3, 25).millisecondsSinceEpoch;
      final friend = Friend(
        id: friendId,
        name: 'Alice Example',
        mobile: '+33600000000',
        tags: null,
        notes: null,
        careScore: 0,
        isConcernActive: false,
        concernNote: null,
        isDemo: false,
        createdAt: now,
        updatedAt: now,
      );

      final router = await pumpShellApp(
        tester,
        overrides: [
          watchFriendByIdProvider(friendId).overrideWith(
            (_) => Stream<Friend?>.value(friend),
          ),
          watchEventsByFriendProvider(friendId).overrideWith(
            (_) => Stream<List<Event>>.value(const <Event>[]),
          ),
          watchEventTypesProvider.overrideWith(
            (_) => Stream<List<EventTypeEntry>>.value(
              const <EventTypeEntry>[],
            ),
          ),
          watchAcquittementsProvider(friendId).overrideWith(
            (_) => Stream<List<Acquittement>>.value(
              const <Acquittement>[],
            ),
          ),
        ],
      );

      expect(find.text('Daily'), findsOneWidget);

      router.push(FriendDetailRoute(friendId).location);
      await settleShell(tester);

      expect(find.text('Alice Example'), findsAtLeastNWidgets(1));

      router.pop();
      await settleShell(tester);

      expect(find.text('Daily'), findsOneWidget);
    },
  );

  testWidgets(
    'direct /friends/new start keeps shell mounted underneath',
    (tester) async {
      final router = createAppRouter(initialLocation: const NewFriendRoute().location);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchDailyViewProvider.overrideWith(
              (_) => const AsyncData(<DailyViewEntry>[]),
            ),
            allFriendsProvider.overrideWith(
              (_) => Stream<List<Friend>>.value(const <Friend>[]),
            ),
            lastContactByFriendProvider.overrideWith(
              (_) => Stream<Map<String, int>>.value(const <String, int>{}),
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

      await settleShell(tester);

      expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
      expect(find.byType(PageView, skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets(
    'direct /settings start keeps shell mounted underneath',
    (tester) async {
      final router = createAppRouter(initialLocation: const SettingsRoute().location);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchDailyViewProvider.overrideWith(
              (_) => const AsyncData(<DailyViewEntry>[]),
            ),
            allFriendsProvider.overrideWith(
              (_) => Stream<List<Friend>>.value(const <Friend>[]),
            ),
            lastContactByFriendProvider.overrideWith(
              (_) => Stream<Map<String, int>>.value(const <String, int>{}),
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

      await settleShell(tester);

      expect(find.text('Settings'), findsAtLeastNWidgets(1));
      expect(find.byType(PageView, skipOffstage: false), findsOneWidget);
    },
  );

  // AC6 — event sub-routes are pushed above the shell without resetting state.

  testWidgets(
    'AC6 — add-event overlay pushed from Friends preserves Friends shell page',
    (tester) async {
      const friendId = 'friend-ac6-events';

      final router = await pumpShellApp(
        tester,
        overrides: [
          watchEventTypesProvider.overrideWith(
            (_) => Stream<List<EventTypeEntry>>.value(const <EventTypeEntry>[]),
          ),
        ],
      );

      // Navigate shell to Friends.
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await settleShell(tester);
      expect(find.text('Friends'), findsOneWidget);

      // Push add-event overlay.
      router.push(AddEventRoute(friendId).location);
      await settleShell(tester);

      expect(find.text('Add Event'), findsAtLeastNWidgets(1));
      // Shell must still be mounted beneath the overlay.
      expect(find.byType(AppShellScreen, skipOffstage: false), findsOneWidget);

      // Pop back — shell must remain on Friends.
      router.pop();
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
    },
  );

  testWidgets(
    'AC6 — edit-event overlay pushed from Friends preserves Friends shell page',
    (tester) async {
      const friendId = 'friend-ac6-edit-event';
      const eventId = 'event-ac6-1';
      final now = DateTime(2026, 3, 27).millisecondsSinceEpoch;
      final event = Event(
        id: eventId,
        friendId: friendId,
        type: 'Birthday',
        date: now,
        isRecurring: false,
        cadenceDays: null,
        comment: null,
        isAcknowledged: false,
        acknowledgedAt: null,
        createdAt: now,
      );

      final router = await pumpShellApp(
        tester,
        overrides: [
          watchEventTypesProvider.overrideWith(
            (_) => Stream<List<EventTypeEntry>>.value(const <EventTypeEntry>[]),
          ),
        ],
      );

      // Navigate shell to Friends.
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await settleShell(tester);
      expect(find.text('Friends'), findsOneWidget);

      // Push edit-event overlay, passing the event via router extra.
      router.push(EditEventRoute(friendId: friendId, eventId: eventId).location, extra: event);
      await settleShell(tester);

      expect(find.text('Edit Event'), findsAtLeastNWidgets(1));
      // Shell must still be mounted beneath the overlay.
      expect(find.byType(AppShellScreen, skipOffstage: false), findsOneWidget);

      // Pop back — shell must remain on Friends.
      router.pop();
      await settleShell(tester);

      expect(find.text('Friends'), findsOneWidget);
    },
  );
}
