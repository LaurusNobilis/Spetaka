import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import 'event_type_repository.dart';

part 'event_type_providers.g.dart';

/// Riverpod provider for [EventTypeRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.
@Riverpod(keepAlive: true)
EventTypeRepository eventTypeRepository(Ref ref) {
  return EventTypeRepository(
    db: ref.watch(appDatabaseProvider),
  );
}

/// Watches all event types ordered by sort_order.
///
/// Story 3.4 AC6: pickers and management screen use this reactive stream.
final watchEventTypesProvider =
    StreamProvider.autoDispose<List<EventTypeEntry>>((ref) {
  return ref.watch(eventTypeRepositoryProvider).watchAll();
});
