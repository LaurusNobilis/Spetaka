// Story 4.3 — Widget tests for HeartBriefingWidget.
//
// Tests the 2+2 selection logic, handling of reduced availability (<2 per tier),
// concern indicator visibility, and navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';
import 'package:spetaka/features/daily/presentation/heart_briefing_widget.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _friend({
  required String id,
  required String name,
  bool isConcernActive = false,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: null,
    notes: null,
    careScore: 0.0,
    isConcernActive: isConcernActive,
    concernNote: null,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

DailyViewEntry _entry({
  required String id,
  required String name,
  required UrgencyTier tier,
  int daysUntil = 0,
  bool isConcernActive = false,
}) {
  return DailyViewEntry(
    friend: _friend(id: id, name: name, isConcernActive: isConcernActive),
    prioritized: PrioritizedFriend(
      friendId: id,
      score: 10.0,
      tier: tier,
      daysUntilNextEvent: daysUntil,
    ),
  );
}

/// Wraps [HeartBriefingWidget] in a minimal router harness so GoRouter
/// navigation calls don't throw during tests.
Widget _harness(List<DailyViewEntry> entries) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: HeartBriefingWidget(entries: entries),
        ),
      ),
      GoRoute(
        path: '/friends/:id',
        builder: (ctx, state) => Scaffold(
          appBar: AppBar(
            title: Text('Friend ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests — Story 4.3
// ---------------------------------------------------------------------------

void main() {
  group('HeartBriefingWidget — Story 4.3', () {
    // AC1: shows up to 2 urgent + 2 important entries
    testWidgets('AC1 — shows max 2 urgent and 2 important', (tester) async {
      final entries = [
        _entry(id: 'u1', name: 'Urgent-1', tier: UrgencyTier.urgent, daysUntil: 0),
        _entry(id: 'u2', name: 'Urgent-2', tier: UrgencyTier.urgent, daysUntil: 0),
        _entry(id: 'u3', name: 'Urgent-3', tier: UrgencyTier.urgent, daysUntil: 0), // 3rd urgent — must NOT appear
        _entry(id: 'i1', name: 'Impt-1', tier: UrgencyTier.important, daysUntil: 1),
        _entry(id: 'i2', name: 'Impt-2', tier: UrgencyTier.important, daysUntil: 2),
        _entry(id: 'i3', name: 'Impt-3', tier: UrgencyTier.important, daysUntil: 3), // 3rd important — must NOT appear
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('Urgent-1'), findsOneWidget);
      expect(find.text('Urgent-2'), findsOneWidget);
      expect(find.text('Urgent-3'), findsNothing, reason: 'Only 2 urgent entries allowed');
      expect(find.text('Impt-1'), findsOneWidget);
      expect(find.text('Impt-2'), findsOneWidget);
      expect(find.text('Impt-3'), findsNothing, reason: 'Only 2 important entries allowed');
    });

    // AC3: handles fewer than 2 urgent without placeholders
    testWidgets('AC3 — only 1 urgent available, no placeholder', (tester) async {
      final entries = [
        _entry(id: 'u1', name: 'Solo Urgent', tier: UrgencyTier.urgent),
        _entry(id: 'i1', name: 'Impt-1', tier: UrgencyTier.important, daysUntil: 2),
        _entry(id: 'i2', name: 'Impt-2', tier: UrgencyTier.important, daysUntil: 3),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('Solo Urgent'), findsOneWidget);
      expect(find.text('Impt-1'), findsOneWidget);
      expect(find.text('Impt-2'), findsOneWidget);
      // No placeholder text
      expect(find.text('—'), findsNothing);
      expect(find.text('Empty'), findsNothing);
    });

    // AC3: handles fewer than 2 important without placeholders
    testWidgets('AC3 — only 1 important available, no placeholder', (tester) async {
      final entries = [
        _entry(id: 'u1', name: 'Urgent-1', tier: UrgencyTier.urgent),
        _entry(id: 'u2', name: 'Urgent-2', tier: UrgencyTier.urgent),
        _entry(id: 'i1', name: 'Solo Impt', tier: UrgencyTier.important, daysUntil: 2),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('Solo Impt'), findsOneWidget);
      // Widget should still render with no placeholder for the missing important slot
      expect(find.text('—'), findsNothing);
    });

    // AC3: nothing rendered when entries is empty
    testWidgets('AC3 — empty list renders nothing (SizedBox.shrink)', (tester) async {
      await tester.pumpWidget(_harness([]));
      await tester.pump();

      expect(find.text('Heart Briefing'), findsNothing);
    });

    // AC2: surfacing reason is displayed
    testWidgets('AC2 — displays surfacing reason text', (tester) async {
      final entries = [
        _entry(
          id: 'u1',
          name: 'Alice',
          tier: UrgencyTier.urgent,
          daysUntil: 0,
        ),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('Due today'), findsOneWidget);
    });

    // AC2: concern indicator is shown when hasConcern = true
    testWidgets('AC2 — concern icon shown when isConcernActive', (tester) async {
      final entries = [
        _entry(
          id: 'u1',
          name: 'Bob',
          tier: UrgencyTier.urgent,
          isConcernActive: true,
        ),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    });

    // AC2: concern icon NOT shown when isConcernActive = false
    testWidgets('AC2 — no concern icon when isConcernActive=false', (tester) async {
      final entries = [
        _entry(
          id: 'u1',
          name: 'Carol',
          tier: UrgencyTier.urgent,
          isConcernActive: false,
        ),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    // AC4: tapping a row navigates to FriendCardScreen
    testWidgets('AC4 — tap navigates to friend detail screen', (tester) async {
      final entries = [
        _entry(id: 'friend-42', name: 'Alice', tier: UrgencyTier.urgent),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(find.text('Friend friend-42'), findsOneWidget);
    });

    // AC5: section labels use "My selection" for both tiers (distinguished by colour)
    testWidgets('AC5 — section labels are visually distinct', (tester) async {
      final entries = [
        _entry(id: 'u1', name: 'Alice', tier: UrgencyTier.urgent),
        _entry(id: 'i1', name: 'Bob', tier: UrgencyTier.important, daysUntil: 2),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      // Both tiers show "MY SELECTION" (colour distinguishes them)
      expect(find.text('MY SELECTION'), findsNWidgets(2));
      // Header
      expect(find.text('Heart Briefing'), findsOneWidget);
    });

    // Only urgent entries — important section omitted entirely
    testWidgets('only urgent entries — no important section rendered', (tester) async {
      final entries = [
        _entry(id: 'u1', name: 'Alice', tier: UrgencyTier.urgent),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('MY SELECTION'), findsOneWidget);
    });

    // Only important entries — urgent section omitted
    testWidgets('only important entries — no urgent section rendered', (tester) async {
      final entries = [
        _entry(id: 'i1', name: 'Bob', tier: UrgencyTier.important, daysUntil: 1),
      ];

      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      expect(find.text('MY SELECTION'), findsOneWidget);
    });
  });
}
