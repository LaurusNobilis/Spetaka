import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  /// Opens the system file-picker so the user can choose the destination
  /// folder and filename. Sets state to [AsyncLoading] while in progress;
  /// emits [AsyncData]&lt;String&gt; with the saved file name on success (or
  /// [AsyncData(null)] if the user cancelled), or [AsyncError] on failure.
  Future<void> export(String passphrase) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(backupRepositoryProvider);

      // 1. Produce the encrypted backup bytes (no I/O).
      final bytes = await repo.exportToBytes(passphrase);

      // 2. Build a timestamped file name.
      final now = DateTime.now().toUtc();
      String pad(int n, [int w = 2]) => n.toString().padLeft(w, '0');
      final dateTag =
          '${pad(now.year, 4)}${pad(now.month)}${pad(now.day)}'
          '_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
      final fileName = 'spetaka_backup_$dateTag.enc';

      // 3. Let the user choose the save folder via the system file picker.
      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['enc'],
      );

      // null means the user cancelled — return null (idle, no snackbar).
      if (result == null) return null;

      return fileName;
    });
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

  /// Initiates an encrypted import from [bytes] using [passphrase].
  ///
  /// Accepts the raw file bytes directly (avoids Android content-URI issues
  /// with [File] I/O on scoped storage).
  ///
  /// Sets state to [AsyncLoading] while in progress; emits
  /// [AsyncData(true)] on success, or [AsyncError] on failure.
  Future<void> importBackup(Uint8List bytes, String passphrase) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(backupRepositoryProvider)
          .importFromBytes(bytes, passphrase);
      return true;
    });
  }

  /// Resets the notifier back to idle.
  void reset() => state = const AsyncData(false);
}
