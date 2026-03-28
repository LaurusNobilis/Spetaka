// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_form_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier holding the in-memory session draft for [FriendFormScreen].
///
/// State is `null` when no draft is active. Survives app-switch
/// (`AppLifecycleState.paused`/`resumed`) but is intentionally lost on
/// process kill (architecture addendum Q5).

@ProviderFor(FriendFormDraftNotifier)
final friendFormDraftProvider = FriendFormDraftNotifierProvider._();

/// Riverpod notifier holding the in-memory session draft for [FriendFormScreen].
///
/// State is `null` when no draft is active. Survives app-switch
/// (`AppLifecycleState.paused`/`resumed`) but is intentionally lost on
/// process kill (architecture addendum Q5).
final class FriendFormDraftNotifierProvider
    extends $NotifierProvider<FriendFormDraftNotifier, FriendFormDraft?> {
  /// Riverpod notifier holding the in-memory session draft for [FriendFormScreen].
  ///
  /// State is `null` when no draft is active. Survives app-switch
  /// (`AppLifecycleState.paused`/`resumed`) but is intentionally lost on
  /// process kill (architecture addendum Q5).
  FriendFormDraftNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'friendFormDraftProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$friendFormDraftNotifierHash();

  @$internal
  @override
  FriendFormDraftNotifier create() => FriendFormDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FriendFormDraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FriendFormDraft?>(value),
    );
  }
}

String _$friendFormDraftNotifierHash() =>
    r'd721cd587ebbec5e17955389271bf26c3fc53d43';

/// Riverpod notifier holding the in-memory session draft for [FriendFormScreen].
///
/// State is `null` when no draft is active. Survives app-switch
/// (`AppLifecycleState.paused`/`resumed`) but is intentionally lost on
/// process kill (architecture addendum Q5).

abstract class _$FriendFormDraftNotifier extends $Notifier<FriendFormDraft?> {
  FriendFormDraft? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FriendFormDraft?, FriendFormDraft?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<FriendFormDraft?, FriendFormDraft?>,
        FriendFormDraft?,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
