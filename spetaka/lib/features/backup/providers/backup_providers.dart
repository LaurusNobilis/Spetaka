import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service_provider.dart';
import '../../friends/data/friend_repository_provider.dart';
import '../data/backup_repository.dart';

part 'backup_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides [BackupRepository] for the lifetime of the app.
///
/// `keepAlive: true` mirrors the pattern used by other repository providers
/// ([friendRepositoryProvider], [acquittementRepositoryProvider]).
@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) {
  return BackupRepository(
    db: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    friendRepository: ref.watch(friendRepositoryProvider),
  );
}

// ---------------------------------------------------------------------------
// BackupNotifier — export state
// ---------------------------------------------------------------------------

/// Manages async state for the "Export backup" action.
///
/// State holds the exported file path on success, `null` while idle.
@riverpod
class BackupExportNotifier extends _$BackupExportNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// Initiates an encrypted export with [passphrase].
  ///
  /// Sets state to [AsyncLoading] while in progress; emits
  /// [AsyncData]&lt;String&gt; with the saved file path on success, or
  /// [AsyncError] on failure.
  Future<void> export(String passphrase) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(backupRepositoryProvider).exportEncrypted(passphrase),
    );
  }

  /// Resets the notifier back to idle / no path.
  void reset() => state = const AsyncData(null);
}

// ---------------------------------------------------------------------------
// BackupNotifier — import state
// ---------------------------------------------------------------------------

/// Manages async state for the "Import backup" action.
///
/// State is `true` on successful import, `false` while idle.
@riverpod
class BackupImportNotifier extends _$BackupImportNotifier {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  /// Initiates an encrypted import from [filePath] using [passphrase].
  ///
  /// Sets state to [AsyncLoading] while in progress; emits
  /// [AsyncData(true)] on success, or [AsyncError] on failure.
  Future<void> importBackup(String filePath, String passphrase) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(backupRepositoryProvider)
          .importEncrypted(filePath, passphrase);
      return true;
    });
  }

  /// Resets the notifier back to idle.
  void reset() => state = const AsyncData(false);
}

// ---------------------------------------------------------------------------
// BackupNotifier — reset backup settings state
// ---------------------------------------------------------------------------

/// Manages async state for the "Reset backup settings" action.
///
/// State is `true` after a successful reset, `false` while idle.
@riverpod
class BackupResetNotifier extends _$BackupResetNotifier {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  /// Rotates the per-install PBKDF2 salt and re-encrypts sensitive fields.
  Future<void> resetBackupSettings(String passphrase) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(backupRepositoryProvider).resetBackupSettings(passphrase);
      return true;
    });
  }

  /// Resets the notifier back to idle.
  void reset() => state = const AsyncData(false);
}
