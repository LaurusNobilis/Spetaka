// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encryption_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(encryptionService)
final encryptionServiceProvider = EncryptionServiceProvider._();

final class EncryptionServiceProvider extends $FunctionalProvider<
    EncryptionService,
    EncryptionService,
    EncryptionService> with $Provider<EncryptionService> {
  EncryptionServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'encryptionServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$encryptionServiceHash();

  @$internal
  @override
  $ProviderElement<EncryptionService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EncryptionService create(Ref ref) {
    return encryptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EncryptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EncryptionService>(value),
    );
  }
}

String _$encryptionServiceHash() => r'0c9018a838e8de9f482ab6680c53d001f2addb9a';
