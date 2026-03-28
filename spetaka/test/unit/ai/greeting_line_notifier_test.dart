// Story 10.3 — Unit tests for GreetingLineNotifier (AC1, AC2, AC3, AC5).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/llm_inference_service.dart';
import 'package:spetaka/core/ai/model_manager.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/daily/data/greeting_line_provider.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DailyViewEntry _entry({
  String id = 'test-id',
  UrgencyTier tier = UrgencyTier.normal,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return DailyViewEntry(
    friend: Friend(
      id: id,
      name: 'Alice',
      mobile: '+33600000001',
      tags: null,
      notes: null,
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    ),
    prioritized: PrioritizedFriend(
      friendId: id,
      score: 10.0,
      tier: tier,
      daysUntilNextEvent: 1,
    ),
  );
}

/// Fake ModelManagerNotifier that returns a fixed initial state without
/// accessing the file system.
class _FakeModelManagerNotifier extends ModelManagerNotifier {
  _FakeModelManagerNotifier({required ModelDownloadState initialState})
      : _initialState = initialState;
  final ModelDownloadState _initialState;

  @override
  ModelDownloadState build() => _initialState;
}

class _MutableModelManagerNotifier extends ModelManagerNotifier {
  _MutableModelManagerNotifier({required ModelDownloadState initialState})
      : _initialState = initialState;

  final ModelDownloadState _initialState;

  @override
  ModelDownloadState build() => _initialState;

  void setStateForTest(ModelDownloadState nextState) {
    state = nextState;
  }
}

final _testDailyViewProvider =
    NotifierProvider<_TestDailyViewNotifier, AsyncValue<List<DailyViewEntry>>>(
  _TestDailyViewNotifier.new,
);

class _TestDailyViewNotifier extends Notifier<AsyncValue<List<DailyViewEntry>>> {
  @override
  AsyncValue<List<DailyViewEntry>> build() =>
      const AsyncData(<DailyViewEntry>[]);

  void setStateForTest(AsyncValue<List<DailyViewEntry>> nextState) {
    state = nextState;
  }
}

class _SeededTestDailyViewNotifier extends _TestDailyViewNotifier {
  _SeededTestDailyViewNotifier({required this.initialState});

  final AsyncValue<List<DailyViewEntry>> initialState;

  @override
  AsyncValue<List<DailyViewEntry>> build() => initialState;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GreetingLineNotifier — Story 10.3', () {
    // -----------------------------------------------------------------------
    // AC1 / AC3 — static fallback shown immediately when model not ready
    // -----------------------------------------------------------------------
    test('AC1/AC3 — static fallback returned immediately when model not ready',
        () async {
      final container = ProviderContainer(
        overrides: [
          watchDailyViewProvider.overrideWith((_) => AsyncData([_entry()])),
          modelManagerProvider.overrideWith(
            () => _FakeModelManagerNotifier(
              initialState: const ModelDownloadIdle(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(inferenceRunner: (_) async => []),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Use listen() to keep auto-dispose provider alive and capture state.
      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Initial state must be available synchronously — no spinner, no blank.
      expect(states, isNotEmpty);
      expect(states.first, isA<String>());
      expect(states.first, isNotEmpty);

      // Even after pumping, no LLM update (model not ready).
      await pumpEventQueue();
      expect(states.length, equals(1));
    });

    // -----------------------------------------------------------------------
    // AC2 — LLM result updates state when model ready
    // -----------------------------------------------------------------------
    test('AC2 — LLM result updates state when model ready', () async {
      const llmResult = 'Bonjour Laurus, belle journée !';

      final container = ProviderContainer(
        overrides: [
          watchDailyViewProvider.overrideWith((_) => AsyncData([_entry()])),
          modelManagerProvider.overrideWith(
            () => _FakeModelManagerNotifier(
              initialState: const ModelReady(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(
              inferenceRunner: (_) async => [llmResult],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Use listen() to keep auto-dispose provider alive and capture changes.
      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Initial state is static fallback.
      expect(states.first, isNotEmpty);

      // Pump the full async chain: microtask → _generateAsync → infer → state.
      await pumpEventQueue();

      // LLM result must overwrite the static fallback.
      expect(states.length, greaterThan(1), reason: 'state should have updated');
      expect(states.last, equals(llmResult));
    });

    // -----------------------------------------------------------------------
    // AC3 — static retained when LLM returns empty list (timeout / no result)
    // -----------------------------------------------------------------------
    test('AC3 — static retained when LLM returns empty list', () async {
      final container = ProviderContainer(
        overrides: [
          watchDailyViewProvider.overrideWith((_) => AsyncData([_entry()])),
          modelManagerProvider.overrideWith(
            () => _FakeModelManagerNotifier(
              initialState: const ModelReady(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(inferenceRunner: (_) async => []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final initial = states.first;
      expect(initial, isNotEmpty);

      // Pump the full async chain.
      await pumpEventQueue();

      // State must still be the static fallback — LLM returned empty list.
      expect(states.length, equals(1), reason: 'state should not have changed');
      expect(states.last, equals(initial));
    });

    // -----------------------------------------------------------------------
    // AC5 — provider always returns String, never null, never throws
    // -----------------------------------------------------------------------
    test('AC5 — provider always returns String, never throws', () async {
      final container = ProviderContainer(
        overrides: [
          watchDailyViewProvider
              .overrideWith((_) => const AsyncData(<DailyViewEntry>[])),
          modelManagerProvider.overrideWith(
            () => _FakeModelManagerNotifier(
              initialState: const ModelDownloadIdle(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(inferenceRunner: (_) async => []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Must not throw, must return a non-null String.
      expect(states, isNotEmpty);
      expect(states.first, isA<String>());
    });

    test('re-generates when the model becomes ready after initial fallback',
        () async {
      var callCount = 0;

      final container = ProviderContainer(
        overrides: [
          _testDailyViewProvider.overrideWith(
            () => _SeededTestDailyViewNotifier(
              initialState: AsyncData([_entry()]),
            ),
          ),
          watchDailyViewProvider.overrideWith(
            (ref) => ref.watch(_testDailyViewProvider),
          ),
          modelManagerProvider.overrideWith(
            () => _MutableModelManagerNotifier(
              initialState: const ModelDownloadIdle(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(
              inferenceRunner: (_) async {
                callCount += 1;
                return ['Bonjour Laurus'];
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      expect(callCount, 0);

        (container.read(modelManagerProvider.notifier)
            as _MutableModelManagerNotifier)
          .setStateForTest(const ModelReady());
      await pumpEventQueue();

      expect(callCount, 1);
      expect(states.last, 'Bonjour Laurus');
    });

    test('re-generates when urgent or concern context changes', () async {
      final results = ['Bonjour Laurus', 'Belle journee'];
      var callIndex = 0;

      final container = ProviderContainer(
        overrides: [
          _testDailyViewProvider.overrideWith(
            () => _SeededTestDailyViewNotifier(
              initialState: AsyncData([_entry(id: 'a')]),
            ),
          ),
          watchDailyViewProvider.overrideWith(
            (ref) => ref.watch(_testDailyViewProvider),
          ),
          modelManagerProvider.overrideWith(
            () => _MutableModelManagerNotifier(
              initialState: const ModelReady(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(
              inferenceRunner: (_) async => [results[callIndex++]],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await pumpEventQueue();
      expect(states.last, 'Bonjour Laurus');

      container.read(_testDailyViewProvider.notifier).setStateForTest(
            AsyncData([
              _entry(id: 'a', tier: UrgencyTier.urgent),
              _entry(id: 'b', tier: UrgencyTier.urgent),
            ]),
          );
      await pumpEventQueue();

      expect(callIndex, 2);
      expect(states.last, 'Belle journee');
    });

    test('ignores invalid LLM output and keeps static fallback', () async {
      final container = ProviderContainer(
        overrides: [
          watchDailyViewProvider.overrideWith((_) => AsyncData([_entry()])),
          modelManagerProvider.overrideWith(
            () => _FakeModelManagerNotifier(
              initialState: const ModelReady(),
            ),
          ),
          llmInferenceServiceProvider.overrideWithValue(
            LlmInferenceService(
              inferenceRunner: (_) async => ['"Bonjour Laurus 2"\nDeuxieme ligne'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final states = <String>[];
      final sub = container.listen(
        greetingLineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final initial = states.first;
      await pumpEventQueue();

      expect(states.last, initial);
      expect(states.length, 1);
    });
  });
}
