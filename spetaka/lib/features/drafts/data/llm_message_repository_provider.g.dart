// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_message_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [LlmMessageRepository].
///
/// keepAlive: true — the repository wraps long-lived singleton services and
/// must survive navigation (matches the keepAlive pattern used by other
/// infrastructure providers).

@ProviderFor(llmMessageRepository)
final llmMessageRepositoryProvider = LlmMessageRepositoryProvider._();

/// Riverpod provider for [LlmMessageRepository].
///
/// keepAlive: true — the repository wraps long-lived singleton services and
/// must survive navigation (matches the keepAlive pattern used by other
/// infrastructure providers).

final class LlmMessageRepositoryProvider extends $FunctionalProvider<
    LlmMessageRepository,
    LlmMessageRepository,
    LlmMessageRepository> with $Provider<LlmMessageRepository> {
  /// Riverpod provider for [LlmMessageRepository].
  ///
  /// keepAlive: true — the repository wraps long-lived singleton services and
  /// must survive navigation (matches the keepAlive pattern used by other
  /// infrastructure providers).
  LlmMessageRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'llmMessageRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$llmMessageRepositoryHash();

  @$internal
  @override
  $ProviderElement<LlmMessageRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmMessageRepository create(Ref ref) {
    return llmMessageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmMessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmMessageRepository>(value),
    );
  }
}

String _$llmMessageRepositoryHash() =>
    r'f9d1b91baf2e4e002f00da47b12bf768ba85eeb0';
