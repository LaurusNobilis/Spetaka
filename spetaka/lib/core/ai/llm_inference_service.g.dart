// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_inference_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod singleton provider — keepAlive prevents disposal.

@ProviderFor(llmInferenceService)
final llmInferenceServiceProvider = LlmInferenceServiceProvider._();

/// Riverpod singleton provider — keepAlive prevents disposal.

final class LlmInferenceServiceProvider extends $FunctionalProvider<
    LlmInferenceService,
    LlmInferenceService,
    LlmInferenceService> with $Provider<LlmInferenceService> {
  /// Riverpod singleton provider — keepAlive prevents disposal.
  LlmInferenceServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'llmInferenceServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$llmInferenceServiceHash();

  @$internal
  @override
  $ProviderElement<LlmInferenceService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmInferenceService create(Ref ref) {
    return llmInferenceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmInferenceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmInferenceService>(value),
    );
  }
}

String _$llmInferenceServiceHash() =>
    r'8d88508aaddfdf21954490fcf034c2c7a94d70ea';
