// Stories 4.4 + 4.6 — Widget tests for DailyViewScreen.
//
// 4.4 — Greeting banner variants; density toggle compact ↔ expanded.
// 4.6 — Inline card expansion: single-open rule, action-row visibility,
//        back-gesture collapse.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/actions/contact_action_service.dart';
import 'package:spetaka/core/actions/phone_normalizer.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';
import 'package:spetaka/features/daily/presentation/daily_view_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _friend({
  required String id,
  required String name,
  bool isConcernActive = false,
  String? notes,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: null,
    notes: notes,
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
  UrgencyTier tier = UrgencyTier.important,
  int daysUntil = 1,
  bool isConcernActive = false,
  String? notes,
}) {
  return DailyViewEntry(
    friend: _friend(
      id: id,
      name: name,
      isConcernActive: isConcernActive,
      notes: notes,
    ),
    prioritized: PrioritizedFriend(
      friendId: id,
      score: 10.0,
      tier: tier,
      daysUntilNextEvent: daysUntil,
    ),
  );
}

Widget _harness(List<DailyViewEntry> entries) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const DailyViewScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (_, __) => const Scaffold(body: Text('Friends')),
      ),
      GoRoute(
        path: '/friends/:id',
        builder: (ctx, state) => Scaffold(
          appBar: AppBar(
            title: Text('Detail ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );

  final fakeActionService = ContactActionService(
    normalizer: const PhoneNormalizer(),
    lifecycleService:
        AppLifecycleService(binding: WidgetsBinding.instance),
  );

  return ProviderScope(
    overrides: [
      watchDailyViewProvider
          .overrideWith((_) => AsyncData(entries)),
      contactActionServiceProvider.overrideWithValue(fakeActionService),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // 4.4 — Greeting banner
  // -------------------------------------------------------------------------

  group('Story 4.4 — Greeting banner', () {
    testWidgets('AC1 — greeting banner is present when entries exist',
        (tester) async {
      final entries = [
        _entry(id: 'a', name: 'Alice'),
        _entry(id: 'b', name: 'Bob'),
      ];
      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      // Greeting banner widget key is set
      expect(find.byKey(const Key('greeting_banner')), findsOneWidget);
    });

    testWidgets('AC1 — greeting banner absent when no entries', (tester) async {
      await tester.pumpWidget(_harness([]));
      await tester.pump();

      expect(find.byKey(const Key('greeting_banner')), findsNothing);
    });

    testWidgets('AC2 — greeting text is non-empty and non-punitive',
        (tester) async {
      final entries = [_entry(id: 'a', name: 'Alice', isConcernActive: true)];
      await tester.pumpWidget(_harness(entries));
      await tester.pump();

      final text = tester
          .widget<Text>(find.byKey(const Key('greeting_banner')))
          .data!;
      expect(text, isNotEmpty);
      expect(text.toLowerCase(), isNot(contains('failed')));
      expect(text.toLowerCase(), isNot(contains('missed')));
    });
  });

  // -------------------------------------------------------------------------
  // -------------------------------------------------------------------------
  // 4.6 — Inline card expansion
  // -------------------------------------------------------------------------

  group('Story 4.6 — Inline card expansion', () {
    final twoEntries = [
      _entry(id: 'a', name: 'Alice', notes: 'Last note for Alice'),
      _entry(id: 'b', name: 'Bob'),
    ];

    testWidgets('AC3 — initially no card is expanded (no action row)',
        (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      expect(
          find.byKey(const Key('action_call_a')).hitTestable(), findsNothing,);
      expect(
          find.byKey(const Key('action_sms_a')).hitTestable(), findsNothing,);
    });

    testWidgets('AC1 — tapping a card expands it (shows action row)',
        (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_call_a')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('action_sms_a')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('action_wa_a')).hitTestable(), findsOneWidget);
    });

    testWidgets('AC2 — expanded card shows last note when present',
        (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(find.text('Last note').hitTestable(), findsOneWidget);
      expect(find.text('Last note for Alice').hitTestable(), findsOneWidget);
    });

    testWidgets('AC2 — expanded card shows Full details link', (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('full_details_a')).hitTestable(), findsOneWidget);
    });

    testWidgets('AC3 — only one card expanded at a time', (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      // Expand card A
      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_call_a')), findsOneWidget);

      // Expand card B → card A must collapse
      await tester.tap(find.byKey(const Key('card_b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_call_b')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('action_call_a')).hitTestable(), findsNothing);
    });

    testWidgets('AC1 — tapping expanded card collapses it', (tester) async {
      await tester.pumpWidget(_harness(twoEntries));
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_call_a')).hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_call_a')).hitTestable(), findsNothing);
    });
  });

  // ── Story 7.3 Accessibility assertions ──────────────────────────────────
  group('DailyViewScreen — Accessibility (Story 7.3)', () {
    final oneEntry = [_entry(id: 'x', name: 'Emma')];

    testWidgets('a11y — expanded card action buttons have semantic labels',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(oneEntry));
      await tester.pump();

      // Expand the card to show action buttons.
      await tester.tap(find.byKey(const Key('card_x')));
      await tester.pumpAndSettle();

      // Action buttons are wrapped in Semantics(label: widget.label, button:true).
      expect(find.bySemanticsLabel('Call'), findsWidgets);
      expect(find.bySemanticsLabel('SMS'), findsWidgets);
      expect(find.bySemanticsLabel('WhatsApp'), findsWidgets);

      semanticsHandle.dispose();
    });

    testWidgets('a11y — action buttons meet 48dp touch target', (tester) async {
      await tester.pumpWidget(_harness(oneEntry));
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_x')));
      await tester.pumpAndSettle();

      final callBtn = tester.getRect(find.byKey(const Key('action_call_x')));
      expect(callBtn.height, greaterThanOrEqualTo(48.0),
          reason: 'Call action button must meet 48dp min touch target',
      );
    });
  });
}
