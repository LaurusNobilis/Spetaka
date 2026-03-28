// Unit tests for DraftMessageNotifier — Story 10.2 (AC1, AC3, AC5, TDD Task 9)
//
// Tests cover:
//   - Initial state is AsyncData(null)
//   - requestSuggestions transitions: null → loading → data
//   - clear() transitions to AsyncData(null)
//   - selectVariant updates selectedIndex and clears editedText
//   - updateEditedText updates editedText field
//
// Strategy: override draftMessageProvider with a _SpyNotifier that replaces
// requestSuggestions with an injected callback so the real LlmMessageRepository
// (which requires heavyweight dependencies) is never constructed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/drafts/domain/draft_message.dart';
import 'package:spetaka/features/drafts/providers/draft_message_providers.dart';

// ---------------------------------------------------------------------------
// Test double
// ---------------------------------------------------------------------------

typedef _Generator = Future<DraftMessage> Function(
  String friendId,
  Event event,
  String channel,
);

/// Wraps [DraftMessageNotifier] and replaces the repo call with [_generator].
/// All other state-machine methods (selectVariant, updateEditedText, clear)
/// are inherited as-is — so we test the real implementation.
class _SpyNotifier extends DraftMessageNotifier {
  _SpyNotifier(this._generator);
  final _Generator _generator;

  @override
  Future<void> requestSuggestions({
    required String friendId,
    required Event event,
    required String channel,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _generator(friendId, event, channel),
    );
    state = result;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Event _event() => Event(
      id: 'e1',
      friendId: 'f1',
      type: 'Anniversaire',
      date: DateTime.now().millisecondsSinceEpoch,
      isRecurring: false,
      comment: null,
      isAcknowledged: false,
      acknowledgedAt: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      cadenceDays: null,
    );

DraftMessage _draft({List<String> variants = const ['v1', 'v2', 'v3']}) =>
    DraftMessage(
      friendId: 'f1',
      friendName: 'Sophie',
      eventContext: 'Anniversaire',
      channel: 'whatsapp',
      variants: variants,
    );

ProviderContainer _makeContainer(_Generator generator) {
  return ProviderContainer(
    overrides: [
      draftMessageProvider.overrideWith(() => _SpyNotifier(generator)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DraftMessageNotifier — Story 10.2', () {
    // ── Initial state ───────────────────────────────────────────────────
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer((_, __, ___) async => _draft());
      addTearDown(container.dispose);

      final state = container.read(draftMessageProvider);
      expect(state, isA<AsyncData<DraftMessage?>>());
      expect(state.value, isNull);
    });

    // ── requestSuggestions: loading → data ──────────────────────────────
    test('requestSuggestions transitions to AsyncLoading then AsyncData', () async {
      final container = _makeContainer((_, __, ___) async => _draft());
      addTearDown(container.dispose);

      final states = <AsyncValue<DraftMessage?>>[];
      container.listen(draftMessageProvider, (_, next) => states.add(next));

      await container.read(draftMessageProvider.notifier).requestSuggestions(
            friendId: 'f1',
            event: _event(),
            channel: 'whatsapp',
          );

      expect(states.any((s) => s is AsyncLoading), isTrue);
      expect(states.last, isA<AsyncData<DraftMessage?>>());
      expect(states.last.value, isA<DraftMessage>());
      expect(states.last.value!.variants.length, 3);
    });

    // ── requestSuggestions with empty variants (AC6) ────────────────────
    test('requestSuggestions returns AsyncData with empty variants on parse failure',
        () async {
      final container =
          _makeContainer((_, __, ___) async => _draft(variants: []));
      addTearDown(container.dispose);

      await container.read(draftMessageProvider.notifier).requestSuggestions(
            friendId: 'f1',
            event: _event(),
            channel: 'whatsapp',
          );

      final state = container.read(draftMessageProvider);
      expect(state.value?.variants, isEmpty);
    });

    // ── clear() ─────────────────────────────────────────────────────────
    test('clear() transitions state to AsyncData(null)', () async {
      final container = _makeContainer((_, __, ___) async => _draft());
      addTearDown(container.dispose);

      await container.read(draftMessageProvider.notifier).requestSuggestions(
            friendId: 'f1',
            event: _event(),
            channel: 'whatsapp',
          );

      expect(container.read(draftMessageProvider).value, isNotNull);

      container.read(draftMessageProvider.notifier).clear();

      final afterClear = container.read(draftMessageProvider);
      expect(afterClear, isA<AsyncData<DraftMessage?>>());
      expect(afterClear.value, isNull);
    });

    // ── selectVariant ────────────────────────────────────────────────────
    test('selectVariant updates selectedIndex and clears editedText', () async {
      final container = _makeContainer((_, __, ___) async => _draft());
      addTearDown(container.dispose);

      await container.read(draftMessageProvider.notifier).requestSuggestions(
            friendId: 'f1',
            event: _event(),
            channel: 'whatsapp',
          );

      container.read(draftMessageProvider.notifier).updateEditedText('custom');
      container.read(draftMessageProvider.notifier).selectVariant(2);

      final draft = container.read(draftMessageProvider).value!;
      expect(draft.selectedIndex, 2);
      expect(draft.editedText, isNull); // reset on variant change
    });

    // ── updateEditedText ─────────────────────────────────────────────────
    test('updateEditedText updates editedText field', () async {
      final container = _makeContainer((_, __, ___) async => _draft());
      addTearDown(container.dispose);

      await container.read(draftMessageProvider.notifier).requestSuggestions(
            friendId: 'f1',
            event: _event(),
            channel: 'whatsapp',
          );

      container
          .read(draftMessageProvider.notifier)
          .updateEditedText('Mon texte édité');

      final draft = container.read(draftMessageProvider).value!;
      expect(draft.editedText, 'Mon texte édité');
    });
  });
}
