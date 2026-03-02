// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides [BackupRepository] for the lifetime of the app.
///
/// `keepAlive: true` mirrors the pattern used by other repository providers
/// ([friendRepositoryProvider], [acquittementRepositoryProvider]).

@ProviderFor(backupRepository)
final backupRepositoryProvider = BackupRepositoryProvider._();

/// Provides [BackupRepository] for the lifetime of the app.
///
/// `keepAlive: true` mirrors the pattern used by other repository providers
/// ([friendRepositoryProvider], [acquittementRepositoryProvider]).

final class BackupRepositoryProvider extends $FunctionalProvider<
    BackupRepository,
    BackupRepository,
    BackupRepository> with $Provider<BackupRepository> {
  /// Provides [BackupRepository] for the lifetime of the app.
  ///
  /// `keepAlive: true` mirrors the pattern used by other repository providers
  /// ([friendRepositoryProvider], [acquittementRepositoryProvider]).
  BackupRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupRepositoryHash();

  @$internal
  @override
  $ProviderElement<BackupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupRepository create(Ref ref) {
    return backupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupRepository>(value),
    );
  }
}

String _$backupRepositoryHash() => r'7cc2ab9415bb0bb216b3c351bc139f7d6bb8e8e5';

/// Manages async state for the "Export backup" action.
///
/// State holds the exported file path on success, `null` while idle.

@ProviderFor(BackupExportNotifier)
final backupExportProvider = BackupExportNotifierProvider._();

/// Manages async state for the "Export backup" action.
///
/// State holds the exported file path on success, `null` while idle.
final class BackupExportNotifierProvider
    extends $NotifierProvider<BackupExportNotifier, AsyncValue<String?>> {
  /// Manages async state for the "Export backup" action.
  ///
  /// State holds the exported file path on success, `null` while idle.
  BackupExportNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupExportProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupExportNotifierHash();

  @$internal
  @override
  BackupExportNotifier create() => BackupExportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$backupExportNotifierHash() =>
    r'51b352cd47bf0666fa651c054c21d9fd1f869843';

/// Manages async state for the "Export backup" action.
///
/// State holds the exported file path on success, `null` while idle.

abstract class _$BackupExportNotifier extends $Notifier<AsyncValue<String?>> {
  AsyncValue<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, AsyncValue<String?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<String?>, AsyncValue<String?>>,
        AsyncValue<String?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

/// Manages async state for the "Import backup" action.
///
/// State is `true` on successful import, `false` while idle.

@ProviderFor(BackupImportNotifier)
final backupImportProvider = BackupImportNotifierProvider._();

/// Manages async state for the "Import backup" action.
///
/// State is `true` on successful import, `false` while idle.
final class BackupImportNotifierProvider
    extends $NotifierProvider<BackupImportNotifier, AsyncValue<bool>> {
  /// Manages async state for the "Import backup" action.
  ///
  /// State is `true` on successful import, `false` while idle.
  BackupImportNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupImportProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupImportNotifierHash();

  @$internal
  @override
  BackupImportNotifier create() => BackupImportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$backupImportNotifierHash() =>
    r'37e9f6de4974984468481d74ddbdfcefceb7dadc';

/// Manages async state for the "Import backup" action.
///
/// State is `true` on successful import, `false` while idle.

abstract class _$BackupImportNotifier extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

/// Manages async state for the "Reset backup settings" action.
///
/// State is `true` after a successful reset, `false` while idle.

@ProviderFor(BackupResetNotifier)
final backupResetProvider = BackupResetNotifierProvider._();

/// Manages async state for the "Reset backup settings" action.
///
/// State is `true` after a successful reset, `false` while idle.
final class BackupResetNotifierProvider
    extends $NotifierProvider<BackupResetNotifier, AsyncValue<bool>> {
  /// Manages async state for the "Reset backup settings" action.
  ///
  /// State is `true` after a successful reset, `false` while idle.
  BackupResetNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupResetProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupResetNotifierHash();

  @$internal
  @override
  BackupResetNotifier create() => BackupResetNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$backupResetNotifierHash() =>
    r'98dc550d5a8de5e0614406306cc0c64e7f321c1a';

/// Manages async state for the "Reset backup settings" action.
///
/// State is `true` after a successful reset, `false` while idle.

abstract class _$BackupResetNotifier extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
