import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/encryption/encryption_service.dart';

/// Repository for Friend CRUD operations.
///
/// **Encryption boundary:** This class is the ONLY place where sensitive
/// narrative fields are encrypted on write and decrypted on read.
///
/// Sensitive fields (encrypted at repository layer, per Story 1.7 / NFR6):
///   - [Friend.notes]       → `friends.notes` column
///   - [Friend.concernNote] → `friends.concern_note` column
///
/// Plaintext fields (never encrypted; required for search/sort/phone ops):
///   - name, mobile, tags, careScore, isConcernActive, createdAt, updatedAt
///
/// Drift DAOs are encryption-agnostic; they receive and return raw stored
/// string values (ciphertext for sensitive fields, plaintext for others).
///
/// **Error propagation:** `EncryptionService` may throw:
///   - [EncryptionNotInitializedAppError] — no active key (not initialised)
///   - [DecryptionFailedAppError]         — GCM auth tag mismatch
///   - [CiphertextFormatAppError]         — ciphertext format is corrupted
/// Repositories do NOT swallow these; callers handle them for UI messaging.
class FriendRepository {
  FriendRepository({required this.db, required this.encryptionService});

  final AppDatabase db;
  final EncryptionService encryptionService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Encrypts sensitive fields and inserts a new [friend] record into SQLite.
  Future<void> insert(Friend friend) async {
    await db.friendDao.insertFriend(_toEncryptedCompanion(friend));
  }

  /// Reads a friend by [id]; decrypts sensitive fields before returning.
  ///
  /// Returns null if no friend with [id] exists.
  Future<Friend?> findById(String id) async {
    final row = await db.friendDao.findById(id);
    return row != null ? _decryptRow(row) : null;
  }

  /// Returns all friends, with sensitive fields decrypted in each record.
  Future<List<Friend>> findAll() async {
    final rows = await db.friendDao.selectAll();
    return rows.map(_decryptRow).toList();
  }

  /// Watches all friends via a reactive stream; each emission is decrypted.
  Stream<List<Friend>> watchAll() =>
      db.friendDao.watchAll().map((rows) => rows.map(_decryptRow).toList());

  /// Watches a single friend by [id] via a reactive stream; decrypts on each emission.
  ///
  /// Emits `null` when no friend with [id] exists.
  Stream<Friend?> watchById(String id) =>
      db.friendDao.watchById(id).map((row) => row != null ? _decryptRow(row) : null);

  /// Encrypts sensitive fields and replaces the existing [friend] record.
  Future<void> update(Friend friend) async {
    await db.friendDao.updateFriend(_toEncryptedCompanion(friend));
  }

  /// Deletes the friend record identified by [id].
  ///
  /// Returns the number of rows deleted (0 or 1).
  Future<int> delete(String id) => db.friendDao.deleteFriend(id);

  // ---------------------------------------------------------------------------
  // Private helpers — encryption boundary
  // ---------------------------------------------------------------------------

  /// Converts a plaintext [friend] to a [FriendsCompanion] with sensitive
  /// fields encrypted via [encryptionService].
  ///
  /// Non-sensitive fields are passed through unchanged.
  FriendsCompanion _toEncryptedCompanion(Friend friend) {
    final encNotes =
        friend.notes != null ? encryptionService.encrypt(friend.notes!) : null;
    final encConcernNote = friend.concernNote != null
        ? encryptionService.encrypt(friend.concernNote!)
        : null;

    return FriendsCompanion(
      id: Value(friend.id),
      name: Value(friend.name),
      mobile: Value(friend.mobile),
      tags: Value(friend.tags),
      notes: Value(encNotes),
      careScore: Value(friend.careScore),
      isConcernActive: Value(friend.isConcernActive),
      concernNote: Value(encConcernNote),
      createdAt: Value(friend.createdAt),
      updatedAt: Value(friend.updatedAt),
    );
  }

  /// Returns a copy of [row] with its sensitive fields replaced by their
  /// decrypted plaintext counterparts.
  Friend _decryptRow(Friend row) {
    final decNotes =
        row.notes != null ? encryptionService.decrypt(row.notes!) : null;
    final decConcernNote = row.concernNote != null
        ? encryptionService.decrypt(row.concernNote!)
        : null;

    return row.copyWith(
      notes: Value<String?>(decNotes),
      concernNote: Value<String?>(decConcernNote),
    );
  }
}
