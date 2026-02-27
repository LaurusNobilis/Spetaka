import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service.dart';

/// Repository for Acquittement (contact-log) operations.
///
/// **Encryption boundary:** This class is the ONLY place where the sensitive
/// `note` field is encrypted on write and decrypted on read.
///
/// Sensitive field (encrypted at repository layer, per Story 1.7 / NFR6):
///   - [Acquittement.note] → `acquittements.note` column
///
/// Plaintext fields (never encrypted; required for filtering/history ops):
///   - id, friendId, type, createdAt
///
/// **Error propagation:** `EncryptionService` may throw:
///   - [EncryptionNotInitializedAppError] — no active key (not initialised)
///   - [DecryptionFailedAppError]         — GCM auth tag mismatch
///   - [CiphertextFormatAppError]         — ciphertext format is corrupted
/// Repositories do NOT swallow these; callers handle them for UI messaging.
class AcquittementRepository {
  AcquittementRepository({required this.db, required this.encryptionService});

  final AppDatabase db;
  final EncryptionService encryptionService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Encrypts the note field (if present) and inserts a new acquittement row.
  Future<void> insert(Acquittement entry) async {
    await db.acquittementDao.insertAcquittement(_toEncryptedCompanion(entry));
  }

  /// Reads an acquittement by [id]; decrypts the note before returning.
  ///
  /// Returns null if no acquittement with [id] exists.
  Future<Acquittement?> findById(String id) async {
    final row = await db.acquittementDao.findById(id);
    return row != null ? _decryptRow(row) : null;
  }

  /// Returns all acquittements for [friendId] with note decrypted.
  Future<List<Acquittement>> findByFriendId(String friendId) async {
    final rows = await db.acquittementDao.selectByFriendId(friendId);
    return rows.map(_decryptRow).toList();
  }

  /// Watches all acquittements; each emission has the note decrypted.
  Stream<List<Acquittement>> watchAll() =>
      db.acquittementDao
          .watchAll()
          .map((rows) => rows.map(_decryptRow).toList());

  // ---------------------------------------------------------------------------
  // Private helpers — encryption boundary
  // ---------------------------------------------------------------------------

  /// Converts a plaintext [entry] to an [AcquittementsCompanion] with the
  /// note field encrypted.
  AcquittementsCompanion _toEncryptedCompanion(Acquittement entry) {
    final encNote =
        entry.note != null ? encryptionService.encrypt(entry.note!) : null;

    return AcquittementsCompanion(
      id: Value(entry.id),
      friendId: Value(entry.friendId),
      type: Value(entry.type),
      note: Value(encNote),
      createdAt: Value(entry.createdAt),
    );
  }

  /// Returns a copy of [row] with the note replaced by its decrypted value.
  Acquittement _decryptRow(Acquittement row) {
    final decNote =
        row.note != null ? encryptionService.decrypt(row.note!) : null;

    return row.copyWith(note: Value<String?>(decNote));
  }
}
