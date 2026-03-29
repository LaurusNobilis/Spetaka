// DraftMessageProviders — Story 10.2 (AC1, AC3, AC5, AC6)
//
// Riverpod notifier that holds the in-memory draft message state.
// State is never persisted to SQLite (AC7, anti-pattern list).

import 'dart:developer' as dev;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../data/llm_message_repository_provider.dart';
import '../domain/draft_message.dart';

part 'draft_message_providers.g.dart';

/// Holds the in-memory state for [DraftMessageSheet].
///
/// - `AsyncData(null)` — no active draft (initial state or after [clear]).
/// - `AsyncLoading()` — inference is running.
/// - `AsyncData(DraftMessage)` — ≥ 1 variant available for display.
/// - `AsyncError(...)` — inference threw an unhandled exception.
///
/// The draft is NEVER written to SQLite. [clear] resets to `AsyncData(null)`.
@Riverpod(keepAlive: false)
class DraftMessageNotifier extends _$DraftMessageNotifier {
  int _requestVersion = 0;

  @override
  AsyncValue<DraftMessage?> build() => const AsyncData(null);

  /// Triggers on-device inference and transitions through loading → data/error.
  ///
  /// AC1: sheet opens in AsyncLoading state immediately after this is called.
  /// Streaming: intermediate AsyncData emissions with isStreaming == true let
  ///   the sheet display partial variants as they arrive, keeping the progress
  ///   indicator visible until the final emission (isStreaming == false).
  /// AC6: empty variants list → AsyncData(DraftMessage) with empty variants
  ///   (the sheet renders the error state — no separate AsyncError needed).
  Future<void> requestSuggestions({
    required String friendId,
    required Event event,
    required String channel,
  }) async {
    final requestVersion = ++_requestVersion;
    state = const AsyncLoading();

    dev.log(
      'DraftMessageNotifier: requestSuggestions for friend=$friendId',
      name: 'drafts.notifier',
    );

    try {
      await for (final draft in ref
          .read(llmMessageRepositoryProvider)
          .generateSuggestionsStream(
            friendId: friendId,
            event: event,
            channel: channel,
          )) {
        if (requestVersion != _requestVersion) return;

        // Preserve selected variant and any user-typed text across streaming
        // updates so the text field doesn't jump while the user is editing.
        final current = state.value;
        if (draft.isStreaming && current != null) {
          state = AsyncData(draft.copyWith(
            selectedIndex: current.selectedIndex,
            editedText: current.editedText,
          ),);
        } else {
          state = AsyncData(draft);
        }
      }
    } catch (e, st) {
      if (requestVersion != _requestVersion) return;
      dev.log(
        'DraftMessageNotifier: stream error — $e',
        name: 'drafts.notifier',
      );
      state = AsyncError(e, st);
    }
  }

  /// Selects a different variant card by index.
  ///
  /// Resets [DraftMessage.editedText] so the text field is re-populated with
  /// the newly selected variant.
  void selectVariant(int index) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(selectedIndex: index, editedText: null),
    );
  }

  /// Updates the user's edited text in the text field.
  void updateEditedText(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(editedText: text));
  }

  /// Discards the draft. Never persists to database (AC5, AC7).
  void clear() {
    dev.log('DraftMessageNotifier: clear()', name: 'drafts.notifier');
    _requestVersion++;
    state = const AsyncData(null);
  }
}
