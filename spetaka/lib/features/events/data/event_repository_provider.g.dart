// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [EventRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.

@ProviderFor(eventRepository)
final eventRepositoryProvider = EventRepositoryProvider._();

/// Riverpod provider for [EventRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.

final class EventRepositoryProvider extends $FunctionalProvider<EventRepository,
    EventRepository, EventRepository> with $Provider<EventRepository> {
  /// Riverpod provider for [EventRepository].
  ///
  /// keepAlive: true — the repository wraps the root [AppDatabase] connection
  /// and must remain alive for the full app lifetime.
  EventRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'eventRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventRepository create(Ref ref) {
    return eventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRepository>(value),
    );
  }
}

String _$eventRepositoryHash() => r'8a3773e9dc0c54a63d3cafc6a36a4f0dbbad6080';
