// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_capability_checker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider — cached for the session (keepAlive).

@ProviderFor(AiCapabilityCheckerNotifier)
final aiCapabilityCheckerProvider = AiCapabilityCheckerNotifierProvider._();

/// Riverpod provider — cached for the session (keepAlive).
final class AiCapabilityCheckerNotifierProvider
    extends $NotifierProvider<AiCapabilityCheckerNotifier, bool> {
  /// Riverpod provider — cached for the session (keepAlive).
  AiCapabilityCheckerNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'aiCapabilityCheckerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$aiCapabilityCheckerNotifierHash();

  @$internal
  @override
  AiCapabilityCheckerNotifier create() => AiCapabilityCheckerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$aiCapabilityCheckerNotifierHash() =>
    r'd3c964e8000c782c63cceaa4199ba2fa8dabdecf';

/// Riverpod provider — cached for the session (keepAlive).

abstract class _$AiCapabilityCheckerNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
