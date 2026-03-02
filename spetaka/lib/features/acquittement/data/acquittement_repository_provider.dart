import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service_provider.dart';
import 'acquittement_repository.dart';

/// Riverpod provider that exposes [AcquittementRepository] to the widget tree.
///
/// Uses keepAlive-equivalent semantics (autoDispose: false) via the manual
/// [Provider] API so that no code-generation step is required.
///
/// The repository wraps the root [AppDatabase] connection and must remain
/// alive for the full app lifetime — same pattern as [appDatabaseProvider]
/// and [encryptionServiceProvider].
final acquittementRepositoryProvider = Provider<AcquittementRepository>(
  (ref) => AcquittementRepository(
    db: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  ),
  name: 'acquittementRepositoryProvider',
);
