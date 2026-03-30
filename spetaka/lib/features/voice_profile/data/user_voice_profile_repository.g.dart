// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_voice_profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userVoiceProfileRepository)
final userVoiceProfileRepositoryProvider =
    UserVoiceProfileRepositoryProvider._();

final class UserVoiceProfileRepositoryProvider extends $FunctionalProvider<
    UserVoiceProfileRepository,
    UserVoiceProfileRepository,
    UserVoiceProfileRepository> with $Provider<UserVoiceProfileRepository> {
  UserVoiceProfileRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userVoiceProfileRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userVoiceProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserVoiceProfileRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserVoiceProfileRepository create(Ref ref) {
    return userVoiceProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserVoiceProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserVoiceProfileRepository>(value),
    );
  }
}

String _$userVoiceProfileRepositoryHash() =>
    r'77d0f080fa349a1e07bef62722436bf4725262a9';
