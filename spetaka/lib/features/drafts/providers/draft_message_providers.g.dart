// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_message_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the in-memory state for [DraftMessageSheet].
///
/// - `AsyncData(null)` — no active draft (initial state or after [clear]).
/// - `AsyncLoading()` — inference is running.
/// - `AsyncData(DraftMessage)` — ≥ 1 variant available for display.
/// - `AsyncError(...)` — inference threw an unhandled exception.
///
/// The draft is NEVER written to SQLite. [clear] resets to `AsyncData(null)`.

@ProviderFor(DraftMessageNotifier)
final draftMessageProvider = DraftMessageNotifierProvider._();

/// Holds the in-memory state for [DraftMessageSheet].
///
/// - `AsyncData(null)` — no active draft (initial state or after [clear]).
/// - `AsyncLoading()` — inference is running.
/// - `AsyncData(DraftMessage)` — ≥ 1 variant available for display.
/// - `AsyncError(...)` — inference threw an unhandled exception.
///
/// The draft is NEVER written to SQLite. [clear] resets to `AsyncData(null)`.
final class DraftMessageNotifierProvider
    extends $NotifierProvider<DraftMessageNotifier, AsyncValue<DraftMessage?>> {
  /// Holds the in-memory state for [DraftMessageSheet].
  ///
  /// - `AsyncData(null)` — no active draft (initial state or after [clear]).
  /// - `AsyncLoading()` — inference is running.
  /// - `AsyncData(DraftMessage)` — ≥ 1 variant available for display.
  /// - `AsyncError(...)` — inference threw an unhandled exception.
  ///
  /// The draft is NEVER written to SQLite. [clear] resets to `AsyncData(null)`.
  DraftMessageNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'draftMessageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$draftMessageNotifierHash();

  @$internal
  @override
  DraftMessageNotifier create() => DraftMessageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DraftMessage?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DraftMessage?>>(value),
    );
  }
}

String _$draftMessageNotifierHash() =>
    r'8ea2d28e5c028d65d9b41bef36bf0ff9b1d670a6';

/// Holds the in-memory state for [DraftMessageSheet].
///
/// - `AsyncData(null)` — no active draft (initial state or after [clear]).
/// - `AsyncLoading()` — inference is running.
/// - `AsyncData(DraftMessage)` — ≥ 1 variant available for display.
/// - `AsyncError(...)` — inference threw an unhandled exception.
///
/// The draft is NEVER written to SQLite. [clear] resets to `AsyncData(null)`.

abstract class _$DraftMessageNotifier
    extends $Notifier<AsyncValue<DraftMessage?>> {
  AsyncValue<DraftMessage?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DraftMessage?>, AsyncValue<DraftMessage?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<DraftMessage?>, AsyncValue<DraftMessage?>>,
        AsyncValue<DraftMessage?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
