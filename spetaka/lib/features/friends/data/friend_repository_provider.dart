import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service_provider.dart';
import 'friend_repository.dart';

part 'friend_repository_provider.g.dart';

/// Riverpod provider for [FriendRepository].
///
/// keepAlive: true — the repository wraps the root [AppDatabase] connection
/// and must remain alive for the full app lifetime (same pattern as
/// [appDatabaseProvider] and [encryptionServiceProvider]).
@Riverpod(keepAlive: true)
FriendRepository friendRepository(Ref ref) {
  return FriendRepository(
    db: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}
