import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/events/data/events_providers.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friend_card_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _makeFriend({
  String id = 'f1',
  String name = 'Alice',
  String mobile = '+33600000001',
  String? tags,
  String? notes,
  bool isConcernActive = false,
  String? concernNote,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: mobile,
    tags: tags,
    notes: notes,
    careScore: 0.0,
    isConcernActive: isConcernActive,
    concernNote: concernNote,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _harnessWithRouter({required Friend? friend}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const FriendCardScreen(id: 'f1'),
        routes: [
          GoRoute(
            path: 'friends/f1/edit',
            builder: (_, __) =>
                const Scaffold(body: Text('Edit Screen')),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      watchFriendByIdProvider('f1').overrideWith(
        (_) => Stream.value(friend),
      ),
      // Stub events stream — no events in widget tests (unit behaviour in repo tests).
      watchEventsByFriendProvider('f1').overrideWith(
        (_) => Stream.value([]),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests — Story 2.6
// ---------------------------------------------------------------------------

void main() {
  group('FriendCardScreen — Story 2.6', () {
    testWidgets('AC1 — displays friend name and mobile', (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(name: 'Alice', mobile: '+33600000001')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('+33600000001'), findsOneWidget);
    });

    testWidgets('AC1 — displays tags section', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend(tags: '["Family"]')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
    });

    testWidgets('AC1 — displays notes when present', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend(notes: 'Loves hiking')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Loves hiking'), findsOneWidget);
    });

    testWidgets('AC1 — shows concern section when active', (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(
          friend: _makeFriend(isConcernActive: true, concernNote: 'Going through a hard time'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Concern'), findsOneWidget);
      expect(find.text('Going through a hard time'), findsOneWidget);
    });

    testWidgets('AC1 — shows events and contact history placeholders', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Contact History'), findsOneWidget);
    });

    testWidgets('AC2 — shows Call, SMS, WhatsApp buttons', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Call'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('AC4 — edit icon button visible in AppBar', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byWidgetPredicate((w) => w is IconButton), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows not-found message for null friend', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Friend not found.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Tests — Story 2.9
  // ---------------------------------------------------------------------------

  group('FriendCardScreen — Story 2.9', () {
    testWidgets('AC1 — shows Flag concern button when concern is inactive',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Flag concern'), findsOneWidget);
    });

    testWidgets('AC2 — concern section shows when isConcernActive=true',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(
          friend: _makeFriend(isConcernActive: true, concernNote: 'Rough patch'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Concern'), findsOneWidget);
      expect(find.text('Rough patch'), findsOneWidget);
      expect(find.text('Flag concern'), findsNothing);
    });

    testWidgets('AC3 — Clear concern button visible when concern is active',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: true)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear concern'), findsOneWidget);
    });

    testWidgets('AC2 — Flag concern button absent when concern is active',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear concern'), findsNothing);
    });
  });
}
