import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friends_list_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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
    createdAt: now,
    updatedAt: now,
  );
}

Widget _harness({
  required List<Friend> friends,
  GoRouter? router,
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
            builder: (ctx, state) =>
                Scaffold(appBar: AppBar(title: Text('Detail ${state.pathParameters['id']}'))),
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
    ],
    child: MaterialApp.router(routerConfig: r),
  );
}

// ---------------------------------------------------------------------------
// Tests — Story 2.5
// ---------------------------------------------------------------------------

void main() {
  group('FriendsListScreen — Story 2.5', () {
    // AC4: empty state
    testWidgets('AC4 — shows empty state when list is empty', (tester) async {
      await tester.pumpWidget(_harness(friends: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No friends yet.'), findsOneWidget);
      expect(find.text('Add first friend'), findsOneWidget);
    });

    // AC1: list renders
    testWidgets('AC1 — renders friend names in list', (tester) async {
      await tester.pumpWidget(
        _harness(friends: [
          _makeFriend(name: 'Alice'),
          _makeFriend(id: 'f2', name: 'Bob'),
        ],),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    // AC2: tags displayed
    testWidgets('AC2 — displays category tags on tile', (tester) async {
      await tester.pumpWidget(
        _harness(friends: [
          _makeFriend(tags: '["Family","Work"]'),
        ],),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    // AC2: concern indicator
    testWidgets('AC2 — shows concern indicator when active', (tester) async {
      await tester.pumpWidget(
        _harness(friends: [
          _makeFriend(isConcernActive: true),
        ],),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.warning_amber_rounded,
        ),
        findsOneWidget,
      );
    });

    // AC6: semantics label
    testWidgets('AC6 — tile has meaningful semantics label', (tester) async {
      await tester.pumpWidget(
        _harness(friends: [
          _makeFriend(name: 'Alice', tags: '["Family"]'),
        ],),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final semantics = tester.getSemantics(find.byType(FriendCardTile));
      expect(semantics.label, contains('Alice'));
      expect(semantics.label, contains('Family'));
    });
  });
}
