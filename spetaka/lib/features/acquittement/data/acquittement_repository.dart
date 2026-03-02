import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../features/daily/domain/priority_engine.dart';
import '../../../features/friends/domain/friend_tags_codec.dart';

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

  /// Watches acquittements for [friendId] in reverse chronological order.
  ///
  /// Used by Story 5-4 (contact history log) and 5-5 (care-score update).
  Stream<List<Acquittement>> watchByFriendId(String friendId) =>
      db.acquittementDao
          .watchByFriendId(friendId)
          .map((rows) => rows.map(_decryptRow).toList());

  // ---------------------------------------------------------------------------
  // Story 5-5 — atomic acquittement + care-score update
  // ---------------------------------------------------------------------------

  /// Inserts a new acquittement and atomically updates the owning friend's
  /// [careScore] in a single Drift transaction (Story 5-5 AC1).
  ///
  /// The care score is computed using [computeCareScore] from
  /// [priority_engine.dart] — **no magic numbers in this repository**.
  ///
  /// Algorithm:
  ///   1. Encrypt note and insert acquittement row.
  ///   2. Fetch owning friend row (raw; tags are plaintext).
  ///   3. Find minimum recurring-event cadence for the friend.
  ///   4. Call [computeCareScore] with daysSince = 0 (just logged).
  ///   5. Persist updated careScore on the friend row.
  ///
  /// If the friend no longer exists the transaction still inserts the
  /// acquittement but skips the care-score update.
  ///
  /// [now] is injectable for deterministic tests.
  Future<void> insertAndUpdateCareScore(
    Acquittement entry, {
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();

    await db.transaction(() async {
      // Step 1: insert acquittement (note encrypted).
      await db.acquittementDao.insertAcquittement(_toEncryptedCompanion(entry));

      // Step 2: fetch the owning friend (raw row — tags are plaintext).
      final friend = await db.friendDao.findById(entry.friendId);
      if (friend == null) return; // guard: friend deleted concurrently.

      // Step 3: find the minimum recurring-event cadence for this friend.
      final events = await db.eventDao.findByFriendId(entry.friendId);
      int? minCadence;
      for (final e in events) {
        if (e.isRecurring && e.cadenceDays != null) {
          final d = e.cadenceDays!;
          if (minCadence == null || d < minCadence) minCadence = d;
        }
      }

      // Step 4: compute care score (tags plaintext — no decryption needed).
      final tags = decodeFriendTags(friend.tags);
      final newCareScore = computeCareScore(
        daysSinceLastContact: 0, // just logged → fully reset
        expectedIntervalDays: minCadence,
        tags: tags,
      );

      // Step 5: persist updated careScore (non-sensitive — no encryption).
      await db.friendDao.updateFriend(
        friend.copyWith(
          careScore: newCareScore,
          updatedAt: ts.millisecondsSinceEpoch,
        ),
      );
    });
  }

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
