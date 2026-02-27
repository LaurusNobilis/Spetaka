// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: prevents auto-disposal — losing pending state would break the
/// acquittement loop.

@ProviderFor(appLifecycleService)
final appLifecycleServiceProvider = AppLifecycleServiceProvider._();

/// keepAlive: prevents auto-disposal — losing pending state would break the
/// acquittement loop.

final class AppLifecycleServiceProvider extends $FunctionalProvider<
    AppLifecycleService,
    AppLifecycleService,
    AppLifecycleService> with $Provider<AppLifecycleService> {
  /// keepAlive: prevents auto-disposal — losing pending state would break the
  /// acquittement loop.
  AppLifecycleServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appLifecycleServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appLifecycleServiceHash();

  @$internal
  @override
  $ProviderElement<AppLifecycleService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLifecycleService create(Ref ref) {
    return appLifecycleService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLifecycleService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLifecycleService>(value),
    );
  }
}

String _$appLifecycleServiceHash() =>
    r'95eecffb42f347fb3a9112aad3dbc7bc1d5c7975';
