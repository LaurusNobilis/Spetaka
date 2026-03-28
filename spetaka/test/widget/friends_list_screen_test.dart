import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friends_list_screen.dart';
import 'package:spetaka/shared/widgets/app_error_widget.dart';

Friend _makeFriend({
  String id = 'f1',
  String name = 'Alice',
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

Widget _harness({
  required List<Friend> friends,
  Map<String, int> lastContactByFriend = const <String, int>{},
  GoRouter? router,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final r = router ??
      GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const FriendsListScreen(),
          ),
          GoRoute(
            path: '/friends/:id',
            builder: (ctx, state) => Scaffold(
              appBar: AppBar(
                title: Text('Detail ${state.pathParameters['id']}'),
              ),
            ),
          ),
          GoRoute(
            path: '/friends/new',
            builder: (_, __) => const Scaffold(body: Text('New')),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      allFriendsProvider.overrideWith((_) => Stream.value(friends)),
      lastContactByFriendProvider.overrideWith(
        (_) => Stream.value(lastContactByFriend),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      routerConfig: r,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests — Story 2.5
// ---------------------------------------------------------------------------

void main() {
  group('FriendsListScreen — Story 2.5', () {
    // AC4: empty state
    testWidgets(
      'AC4 — shows empty state when list is empty',
      (tester) async {
        await tester.pumpWidget(_harness(friends: []));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('No friends yet.'), findsOneWidget);
        expect(find.text('Add first friend'), findsOneWidget);
      },
    );

    // AC1: list renders
    testWidgets(
      'AC1 — renders friend names in list',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(name: 'Alice'),
              _makeFriend(id: 'f2', name: 'Bob'),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
      },
    );

    // AC2: tags displayed
    testWidgets(
      'AC2 — displays category tags on tile',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(tags: '["Family","Work"]'),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final tile = find.byType(FriendCardTile);
        expect(
          find.descendant(of: tile, matching: find.text('Family')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tile, matching: find.text('Work')),
          findsOneWidget,
        );
      },
    );

    // AC2: concern indicator
    testWidgets(
      'AC2 — shows concern indicator when active',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(isConcernActive: true),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.icon == Icons.warning_amber_rounded,
          ),
          findsOneWidget,
        );
      },
    );

    // AC6: semantics label
    testWidgets(
      'AC6 — tile has meaningful semantics label',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(name: 'Alice', tags: '["Family"]'),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final semantics = tester.getSemantics(find.byType(FriendCardTile));
        expect(semantics.label, contains('Alice'));
        expect(semantics.label, contains('Family'));
      },
    );
  });

  // =========================================================================
  // Story 8.1 — Filter Friend List by Category Tags
  // =========================================================================

  group('FriendsListScreen — Story 8.1 Tag Filtering', () {
    // AC1: distinct chips derived from live friend data
    testWidgets('AC1 — renders distinct tag chips from live friend data',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', tags: '["Family","Work"]'),
            _makeFriend(id: 'f2', name: 'Bob', tags: '["Family","Club"]'),
            _makeFriend(id: 'f3', name: 'Claire', tags: '["Work"]'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show 3 distinct chips: Club, Family, Work (sorted alphabetically)
      expect(find.widgetWithText(FilterChip, 'Club'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Family'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Work'), findsOneWidget);
      // All three friends visible (no filter active)
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Claire'), findsOneWidget);
    });

    // AC2: multiple selected chips use OR logic
    testWidgets(
      'AC2 — selecting chips filters with OR logic',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(id: 'f1', name: 'Alice', tags: '["Family"]'),
              _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
              _makeFriend(id: 'f3', name: 'Claire', tags: '["Club"]'),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap "Family" chip
        await tester.tap(find.widgetWithText(FilterChip, 'Family'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Only Alice visible
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsNothing);
        expect(find.text('Claire'), findsNothing);

        // Tap "Work" chip — OR logic: Alice (Family) + Bob (Work)
        await tester.tap(find.widgetWithText(FilterChip, 'Work'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('Claire'), findsNothing);
      },
    );

    // AC3: deselecting last chip restores full list
    testWidgets('AC3 — deselecting final chip restores full list',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          friends: [
            _makeFriend(id: 'f1', name: 'Alice', tags: '["Family"]'),
            _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Family
      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bob'), findsNothing);

      // Deselect Family — full list restored
      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    // AC4: zero-match empty-state copy
    testWidgets(
      'AC4 — shows filtered empty state when live data removes all matches',
      (tester) async {
        final controller = StreamController<List<Friend>>.broadcast();

        addTearDown(controller.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              allFriendsProvider.overrideWith((_) => controller.stream),
              lastContactByFriendProvider.overrideWith(
                (_) => Stream.value(const <String, int>{}),
              ),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, __) => const FriendsListScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        controller.add([
          _makeFriend(id: 'f1', name: 'Alice', tags: '["Family"]'),
          _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.widgetWithText(FilterChip, 'Family'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsNothing);

        controller.add([
          _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('No friends with these tags yet.'), findsOneWidget);
        expect(find.text('Alice'), findsNothing);
        expect(find.text('Bob'), findsNothing);
      },
    );

    testWidgets('AC6 — chips disappear when no friend uses the tag anymore',
        (tester) async {
      final controller = StreamController<List<Friend>>.broadcast();

      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allFriendsProvider.overrideWith((_) => controller.stream),
            lastContactByFriendProvider.overrideWith(
              (_) => Stream.value(const <String, int>{}),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const FriendsListScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      controller.add([
        _makeFriend(id: 'f1', name: 'Alice', tags: '["Family"]'),
        _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(FilterChip, 'Family'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Work'), findsOneWidget);

      controller.add([
        _makeFriend(id: 'f2', name: 'Bob', tags: '["Work"]'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(FilterChip, 'Family'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'Work'), findsOneWidget);
    });

    // AC5: filter state is session-only (autoDispose handles this)
    // Verified by provider being StateProvider.autoDispose — no persistence test needed.

    // AC7: semantics labels for selected/unselected chips
    testWidgets(
      'AC7 — filter chips have correct semantics labels',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(
                id: 'f1',
                name: 'Alice',
                tags: '["Family","Work"]',
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Find the Semantics widget wrapping the Family chip
        final familyChipSemantics = find.bySemanticsLabel(
          RegExp(r'Filter by Family, not selected'),
        );
        expect(familyChipSemantics, findsOneWidget);

        // Tap Family chip to select it
        await tester.tap(find.widgetWithText(FilterChip, 'Family'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final familyChipSelectedSemantics = find.bySemanticsLabel(
          RegExp(r'Filter by Family, selected'),
        );
        expect(familyChipSelectedSemantics, findsOneWidget);
      },
    );

    // No chips when friends have no tags
    testWidgets(
      'no chips bar when no friends have tags',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(id: 'f1', name: 'Alice'),
              _makeFriend(id: 'f2', name: 'Bob'),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FilterChip), findsNothing);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
      },
    );
  });

  group('FriendsListScreen — Story 8.4 Last Contact', () {
    testWidgets(
      'AC1/AC3 — FriendCardTile shows last contact when available',
      (tester) async {
        final lastContactAt = DateTime.now()
            .subtract(const Duration(days: 21))
            .millisecondsSinceEpoch;

        await tester.pumpWidget(
          _harness(
            friends: [_makeFriend(name: 'Alice')],
            lastContactByFriend: {'f1': lastContactAt},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Last contact: 3 weeks ago'), findsOneWidget);

        final semantics = tester.getSemantics(find.byType(FriendCardTile));
        expect(semantics.label, contains('Last contact: 3 weeks ago'));
      },
    );

    testWidgets(
      'AC2 — FriendCardTile hides last contact when absent',
      (tester) async {
        await tester.pumpWidget(
          _harness(friends: [_makeFriend(name: 'Alice')]),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Last contact:'), findsNothing);
      },
    );

    testWidgets(
      'AC1/AC2 — FriendsListScreen renders last contact per friend',
      (tester) async {
        final lastContactAt = DateTime.now()
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch;

        await tester.pumpWidget(
          _harness(
            friends: [
              _makeFriend(id: 'f1', name: 'Alice'),
              _makeFriend(id: 'f2', name: 'Bob'),
            ],
            lastContactByFriend: {'f1': lastContactAt},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Last contact: 2 weeks ago'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        expect(find.textContaining('Last contact:'), findsOneWidget);
      },
    );

    testWidgets(
      'keeps the friend list visible when last-contact metadata fails',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lastContactByFriendProvider.overrideWith(
                (_) => Stream<Map<String, int>>.error(Exception('last-contact failed')),
              ),
              allFriendsProvider.overrideWith(
                (_) => Stream.value([_makeFriend(name: 'Alice')]),
              ),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, __) => const FriendsListScreen(),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Alice'), findsOneWidget);
        expect(find.byType(AppErrorWidget), findsNothing);
        expect(find.textContaining('Last contact:'), findsNothing);
      },
    );

    testWidgets(
      'uses the dark-mode secondary token for last-contact text',
      (tester) async {
        final lastContactAt = DateTime.now()
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch;

        await tester.pumpWidget(
          _harness(
            friends: [_makeFriend(name: 'Alice')],
            lastContactByFriend: {'f1': lastContactAt},
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final textWidget = tester.widget<Text>(find.text('Last contact: 2 weeks ago'));
        expect(textWidget.style?.color, equals(const Color(0xFFB0A09A)));
      },
    );
  });
}
