import 'package:drift/drift.dart';

import '../../../features/acquittement/domain/acquittement.dart';
import '../app_database.dart';

part 'acquittement_dao.g.dart';

/// DAO for Acquittement (contact-log) entity persistence.
///
/// Encryption-agnostic: receives and returns raw stored values.
/// The [note] field will be ciphertext when persisted; decryption is the
/// sole responsibility of [AcquittementRepository].
///
/// Table: [Acquittements] — schema introduced in Story 1.7.
@DriftAccessor(tables: [Acquittements])
class AcquittementDao extends DatabaseAccessor<AppDatabase>
    with _$AcquittementDaoMixin {
  AcquittementDao(super.db);

  /// Inserts a new acquittement row. Returns the SQLite rowid.
  Future<int> insertAcquittement(Insertable<Acquittement> entry) =>
      into(acquittements).insert(entry);

  /// Returns the [Acquittement] row with the given UUID [id], or null.
  Future<Acquittement?> findById(String id) =>
      (select(acquittements)..where((a) => a.id.equals(id)))
          .getSingleOrNull();

  /// Returns all acquittement rows for a given [friendId].
  Future<List<Acquittement>> selectByFriendId(String friendId) =>
      (select(acquittements)..where((a) => a.friendId.equals(friendId))).get();

  /// Deletes all acquittements associated with [friendId].
  ///
  /// Used by [FriendRepository.delete] to cascade-delete contact history
  /// when a friend card is removed (Story 2.8 AC2).
  Future<int> deleteByFriendId(String friendId) =>
      (delete(acquittements)..where((a) => a.friendId.equals(friendId))).go();

  /// Watches all acquittements; emits on every database change.
  Stream<List<Acquittement>> watchAll() => select(acquittements).watch();
}
