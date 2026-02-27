// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [FriendRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime (same pattern as
/// [appDatabaseProvider] and [encryptionServiceProvider]).

@ProviderFor(friendRepository)
final friendRepositoryProvider = FriendRepositoryProvider._();

/// Riverpod provider for [FriendRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime (same pattern as
/// [appDatabaseProvider] and [encryptionServiceProvider]).

final class FriendRepositoryProvider extends $FunctionalProvider<
    FriendRepository,
    FriendRepository,
    FriendRepository> with $Provider<FriendRepository> {
  /// Riverpod provider for [FriendRepository].
  ///
  /// keepAlive: true — the repository wraps the root [AppDatabase] connection
  /// and must remain alive for the full app lifetime (same pattern as
  /// [appDatabaseProvider] and [encryptionServiceProvider]).
  FriendRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'friendRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$friendRepositoryHash();

  @$internal
  @override
  $ProviderElement<FriendRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FriendRepository create(Ref ref) {
    return friendRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FriendRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FriendRepository>(value),
    );
  }
}

String _$friendRepositoryHash() => r'5e9bbb68d89f1f2a19e653354105872d4de081ea';
