// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_type_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [EventTypeRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.

@ProviderFor(eventTypeRepository)
final eventTypeRepositoryProvider = EventTypeRepositoryProvider._();

/// Riverpod provider for [EventTypeRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.

final class EventTypeRepositoryProvider extends $FunctionalProvider<
    EventTypeRepository,
    EventTypeRepository,
    EventTypeRepository> with $Provider<EventTypeRepository> {
  /// Riverpod provider for [EventTypeRepository].
  ///
  /// keepAlive: true — the repository wraps the root [AppDatabase] connection
  /// and must remain alive for the full app lifetime.
  EventTypeRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'eventTypeRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventTypeRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventTypeRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventTypeRepository create(Ref ref) {
    return eventTypeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventTypeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventTypeRepository>(value),
    );
  }
}

String _$eventTypeRepositoryHash() =>
    r'a24c808dcf0b97d6782b477ff73dd605931ad3a0';
