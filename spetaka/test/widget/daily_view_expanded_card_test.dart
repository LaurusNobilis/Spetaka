// Story 10.5 AC3/AC4/AC7 — Widget tests for the "✦ Message IA" AI button
// in the _ExpandedContent action row of DailyViewScreen.
//
// Tests cover:
//   - Button visible when LLM supported + model ready + nearestEvent non-null
//   - Button absent when LLM not supported
//   - Button absent when model not ready
//   - Button absent when nearestEvent is null

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/actions/contact_action_service.dart';
import 'package:spetaka/core/actions/phone_normalizer.dart';
import 'package:spetaka/core/ai/ai_capability_checker.dart';
import 'package:spetaka/core/ai/model_manager.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';
import 'package:spetaka/features/daily/presentation/daily_view_screen.dart';
import 'package:spetaka/features/drafts/domain/draft_message.dart';
import 'package:spetaka/features/drafts/providers/draft_message_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _friend({required String id, required String name}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: null,
    notes: null,
    careScore: 0.0,
    isConcernActive: false,
    concernNote: null,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

Event _event({required String friendId}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Event(
    id: 'ev_$friendId',
    friendId: friendId,
    type: 'Anniversaire',
    date: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    isRecurring: false,
    comment: null,
    isAcknowledged: false,
    acknowledgedAt: null,
    createdAt: now,
    cadenceDays: null,
  );
}

DailyViewEntry _entry({
  required String id,
  required String name,
  Event? nearestEvent,
}) {
  return DailyViewEntry(
    friend: _friend(id: id, name: name),
    prioritized: PrioritizedFriend(
      friendId: id,
      score: 10.0,
      tier: UrgencyTier.important,
      daysUntilNextEvent: 1,
    ),
    nearestEvent: nearestEvent,
  );
}

/// Stub DraftMessageNotifier that never calls actual LLM inference.
class _StubDraftNotifier extends DraftMessageNotifier {
  @override
  AsyncValue<DraftMessage?> build() => const AsyncData(null);

  @override
  Future<void> requestSuggestions({
    required String friendId,
    required Event event,
    required String channel,
  }) async {}
}

Widget _harness(
  List<DailyViewEntry> entries, {
  bool isAiSupported = false,
  ModelDownloadState modelState = const ModelDownloadIdle(),
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const DailyViewScreen(),
      ),
      GoRoute(
        path: '/friends/:id',
        builder: (ctx, state) => Scaffold(
          appBar: AppBar(title: Text('Detail ${state.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/model-download',
        builder: (_, __) => const Scaffold(body: Text('Model Download')),
      ),
    ],
  );

  final fakeActionService = ContactActionService(
    normalizer: const PhoneNormalizer(),
    lifecycleService: AppLifecycleService(binding: WidgetsBinding.instance),
  );

  return ProviderScope(
    overrides: [
      watchDailyViewProvider.overrideWith((_) => AsyncData(entries)),
      aiCapabilityCheckerProvider.overrideWithValue(isAiSupported),
      modelManagerProvider.overrideWithValue(modelState),
      contactActionServiceProvider.overrideWithValue(fakeActionService),
      draftMessageProvider.overrideWith(() => _StubDraftNotifier()),
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

  group('Story 10.5 AC3/AC4 — "✦ Message IA" button gating', () {
    testWidgets(
        'button visible when LLM supported + model ready + nearestEvent non-null',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final ev = _event(friendId: 'a');
      final entries = [_entry(id: 'a', name: 'Alice', nearestEvent: ev)];

      await tester.pumpWidget(
        _harness(
          entries,
          isAiSupported: true,
          modelState: const ModelReady(),
        ),
      );
      await tester.pump();

      // Expand the card
      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('action_llm_a')).hitTestable(),
        findsOneWidget,
        reason: 'AI button must appear when LLM ready and event available',
      );
      expect(
        find.bySemanticsLabel('Compose an AI-suggested message for Alice'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('button absent when LLM not supported', (tester) async {
      final ev = _event(friendId: 'a');
      final entries = [_entry(id: 'a', name: 'Alice', nearestEvent: ev)];

      await tester.pumpWidget(
        _harness(
          entries,
          isAiSupported: false, // LLM not supported
          modelState: const ModelReady(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('action_llm_a')).hitTestable(),
        findsNothing,
        reason: 'AI button must be hidden when LLM is not supported',
      );
    });

    testWidgets('button absent when model not ready', (tester) async {
      final ev = _event(friendId: 'a');
      final entries = [_entry(id: 'a', name: 'Alice', nearestEvent: ev)];

      await tester.pumpWidget(
        _harness(
          entries,
          isAiSupported: true,
          modelState: const ModelDownloadIdle(), // not ready
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('action_llm_a')).hitTestable(),
        findsNothing,
        reason: 'AI button must be hidden when model is not downloaded',
      );
    });

    testWidgets('button absent when nearestEvent is null', (tester) async {
      final entries = [
        _entry(id: 'a', name: 'Alice', nearestEvent: null), // no event
      ];

      await tester.pumpWidget(
        _harness(
          entries,
          isAiSupported: true,
          modelState: const ModelReady(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('action_llm_a')).hitTestable(),
        findsNothing,
        reason: 'AI button must be hidden when no nearest event exists',
      );
    });

    testWidgets('3 standard action buttons always present when expanded',
        (tester) async {
      final ev = _event(friendId: 'a');
      final entries = [_entry(id: 'a', name: 'Alice', nearestEvent: ev)];

      await tester.pumpWidget(
        _harness(
          entries,
          isAiSupported: true,
          modelState: const ModelReady(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_call_a')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('action_sms_a')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('action_wa_a')).hitTestable(), findsOneWidget);
    });
  });
}
