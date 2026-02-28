import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import 'event_repository.dart';

part 'event_repository_provider.g.dart';

/// Riverpod provider for [EventRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime.
@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository(
    db: ref.watch(appDatabaseProvider),
  );
}
