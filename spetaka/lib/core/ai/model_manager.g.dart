// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod stream provider for reactive UI updates.

@ProviderFor(ModelManagerNotifier)
final modelManagerProvider = ModelManagerNotifierProvider._();

/// Riverpod stream provider for reactive UI updates.
final class ModelManagerNotifierProvider
    extends $NotifierProvider<ModelManagerNotifier, ModelDownloadState> {
  /// Riverpod stream provider for reactive UI updates.
  ModelManagerNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'modelManagerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$modelManagerNotifierHash();

  @$internal
  @override
  ModelManagerNotifier create() => ModelManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelDownloadState>(value),
    );
  }
}

String _$modelManagerNotifierHash() =>
    r'282a190f9adf8252ba05f0478b6484c378a71895';

/// Riverpod stream provider for reactive UI updates.

abstract class _$ModelManagerNotifier extends $Notifier<ModelDownloadState> {
  ModelDownloadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ModelDownloadState, ModelDownloadState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ModelDownloadState, ModelDownloadState>,
        ModelDownloadState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
