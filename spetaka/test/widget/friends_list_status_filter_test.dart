import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friends_list_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _makeFriend({
  required String id,
  required String name,
  String? tags,
  bool isConcernActive = false,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: tags,
    notes: null,
    careScore: 0.0,
    isConcernActive: isConcernActive,
    concernNote: null,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

Event _makeEvent({
  required String friendId,
  required bool isAcknowledged,
  required int date, // Unix-epoch ms
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Event(
    id: 'ev-$friendId',
    friendId: friendId,
    type: 'Check-in',
    date: date,
    isRecurring: false,
    comment: null,
    isAcknowledged: isAcknowledged,
    acknowledgedAt: isAcknowledged ? now : null,
    createdAt: now,
    cadenceDays: null,
  );
}

Widget _harness({
  required List<Friend> friends,
  Map<String, int> lastContactByFriend = const <String, int>{},
  List<Event> events = const <Event>[],
}) {
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
        (_) => Stream.value(lastContactByFriend),
      ),
      allEventsForStatusProvider.overrideWith((_) => Stream.value(events)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FriendsListScreen status filter — Story 8.3', () {
    // AC1, AC3: filter icon is visible in the AppBar
    testWidgets('shows filter icon in AppBar', (tester) async {
      await tester.pumpWidget(_harness(friends: [_makeFriend(id: 'f1', name: 'Alice')]));
      await _settle(tester);

      expect(find.byIcon(Icons.filter_list_outlined), findsOneWidget);
    });

    // AC1: tapping filter icon opens bottom sheet with 3 toggles
    testWidgets('tapping filter icon opens StatusFilterSheet with 3 toggles', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(friends: [_makeFriend(id: 'f1', name: 'Alice')]));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      expect(find.text('Active concern'), findsOneWidget);
      expect(find.text('Overdue event'), findsOneWidget);
      expect(find.text('No recent contact'), findsOneWidget);
    });

    // AC2: sheet can also be dismissed with an explicit close button
    testWidgets('close button dismisses the status filter sheet', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(friends: [_makeFriend(id: 'f1', name: 'Alice')]));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      expect(find.text('Filter by status'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      expect(find.text('Filter by status'), findsNothing);
      expect(find.text('Active concern'), findsNothing);
    });

    // AC1: "Active concern" filter hides friends without concern
    testWidgets('Active concern filter shows only isConcernActive friends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: true),
            _makeFriend(id: 'f2', name: 'Bob', isConcernActive: false),
          ],
        ),
      );
      await _settle(tester);

      // Open sheet and toggle "Active concern"
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);
      await tester.tap(find.byType(Switch).first); // first = activeConcern
      await _settle(tester);

      // Dismiss sheet
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    // AC1: "Overdue event" filter
    testWidgets('Overdue event filter shows only friends with overdue events', (
      tester,
    ) async {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final tomorrow =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;

      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice'), // overdue
            _makeFriend(id: 'f2', name: 'Bob'), // not overdue
            _makeFriend(id: 'f3', name: 'Carol'), // no events
          ],
          events: [
            _makeEvent(friendId: 'f1', isAcknowledged: false, date: yesterday),
            _makeEvent(friendId: 'f2', isAcknowledged: false, date: tomorrow),
          ],
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      // Second switch = overdueEvent
      final switches = find.byType(Switch);
      await tester.tap(switches.at(1));
      await _settle(tester);

      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Carol'), findsNothing);
    });

    // AC1, AC5: "No recent contact" includes never-contacted friends
    testWidgets('No recent contact filter includes never-contacted friends', (
      tester,
    ) async {
      final recent = DateTime.now()
          .subtract(const Duration(days: 5))
          .millisecondsSinceEpoch;
      final old = DateTime.now()
          .subtract(const Duration(days: 40))
          .millisecondsSinceEpoch;

      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice'), // recent contact
            _makeFriend(id: 'f2', name: 'Bob'), // old contact
            _makeFriend(id: 'f3', name: 'Carol'), // never contacted
          ],
          lastContactByFriend: {
            'f1': recent,
            'f2': old,
            // f3 absent → never contacted
          },
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      // Third switch = noRecentContact
      final switches = find.byType(Switch);
      await tester.tap(switches.at(2));
      await _settle(tester);

      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    // AC2: multiple status filters compose as a union before tag/search intersection
    testWidgets('multiple status filters compose as a union', (
      tester,
    ) async {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: true),
            _makeFriend(id: 'f2', name: 'Bob'),
            _makeFriend(id: 'f3', name: 'Carol'),
          ],
          events: [
            _makeEvent(friendId: 'f2', isAcknowledged: false, date: yesterday),
          ],
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      final switches = find.byType(Switch);
      await tester.tap(switches.at(0));
      await _settle(tester);
      await tester.tap(switches.at(1));
      await _settle(tester);

      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsNothing);
    });

    // AC3: badge count shows when filter is active
    testWidgets('badge count increments when status filter is toggled', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(friends: [_makeFriend(id: 'f1', name: 'Alice')]));
      await _settle(tester);

      // No badge initially — outlined icon
      expect(find.byIcon(Icons.filter_list_outlined), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsNothing);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);

      await tester.tap(find.byType(Switch).first);
      await _settle(tester);

      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      // Filled icon + badge visible
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_outlined), findsNothing);
    });

    // AC4: "Clear all filters" resets
    testWidgets('Clear all filters restores full list', (tester) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: true),
            _makeFriend(id: 'f2', name: 'Bob', isConcernActive: false),
          ],
        ),
      );
      await _settle(tester);

      // Activate concern filter
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);
      await tester.tap(find.byType(Switch).first);
      await _settle(tester);

      // Tap "Clear all filters"
      await tester.tap(find.text('Clear all filters'));
      await _settle(tester);

      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      // Both friends visible again
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    // AC2: status filter + tag filter compose as intersection
    testWidgets('status filter composes with tag filter as intersection', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(
              id: 'f1',
              name: 'Alice',
              tags: '["Family"]',
              isConcernActive: true,
            ),
            _makeFriend(
              id: 'f2',
              name: 'Bob',
              tags: '["Family"]',
              isConcernActive: false,
            ),
            _makeFriend(
              id: 'f3',
              name: 'Carol',
              tags: '["Work"]',
              isConcernActive: true,
            ),
          ],
        ),
      );
      await _settle(tester);

      // Activate "Family" tag filter
      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await _settle(tester);

      // Activate "Active concern" status filter
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);
      await tester.tap(find.byType(Switch).first);
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      // Only Alice: Family tag AND concern active
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Carol'), findsNothing);
    });

    // AC2: zero-match empty state
    testWidgets('shows status filter empty state when no friends match', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: false),
          ],
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);
      await tester.tap(find.byType(Switch).first); // activeConcern
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.text('No friends match the active filters.'), findsOneWidget);
    });

    // AC6 / Task 6.11: filters are session-only and reset after provider disposal
    testWidgets('status filters are session-only after widget disposal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: true),
            _makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await _settle(tester);
      await tester.tap(find.byType(Switch).first);
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);

      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', isConcernActive: true),
            _makeFriend(id: 'f2', name: 'Bob'),
          ],
        ),
      );
      await _settle(tester);

      expect(find.byIcon(Icons.filter_list_outlined), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
