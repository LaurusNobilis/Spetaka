// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_action_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactActionService)
final contactActionServiceProvider = ContactActionServiceProvider._();

final class ContactActionServiceProvider extends $FunctionalProvider<
    ContactActionService,
    ContactActionService,
    ContactActionService> with $Provider<ContactActionService> {
  ContactActionServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'contactActionServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$contactActionServiceHash();

  @$internal
  @override
  $ProviderElement<ContactActionService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContactActionService create(Ref ref) {
    return contactActionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactActionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactActionService>(value),
    );
  }
}

String _$contactActionServiceHash() =>
    r'da092aa1c7c719a563f6cf5bde47495248866e72';
