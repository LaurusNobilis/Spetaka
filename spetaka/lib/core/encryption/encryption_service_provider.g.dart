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

String _$encryptionServiceHash() => r'50eaddb414623727178902e88a247d0e3a3fdaf0';
