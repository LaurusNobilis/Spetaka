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
      (select(acquittements)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Returns all acquittement rows for a given [friendId].
  Future<List<Acquittement>> selectByFriendId(String friendId) =>
      (select(acquittements)..where((a) => a.friendId.equals(friendId))).get();

  /// Deletes all acquittements associated with [friendId].
  ///
  /// Used by [FriendRepository.delete] to cascade-delete contact history
  /// when a friend card is removed (Story 2.8 AC2).
  Future<int> deleteByFriendId(String friendId) =>
      (delete(acquittements)..where((a) => a.friendId.equals(friendId))).go();

  /// Returns all acquittement rows — used by [BackupRepository] for export.
  Future<List<Acquittement>> selectAllRaw() => select(acquittements).get();

  /// Deletes all acquittement rows (used by [BackupRepository] restore — replace-all).
  Future<int> deleteAll() => delete(acquittements).go();

  /// Replaces an existing acquittement row identified by the primary key.
  ///
  /// Used by Story 7.1 "Reset backup settings" to rotate encryption-at-rest.
  Future<bool> updateAcquittement(Insertable<Acquittement> entry) =>
      update(acquittements).replace(entry);

  /// Watches all acquittements; emits on every database change.
  Stream<List<Acquittement>> watchAll() => select(acquittements).watch();

  /// Watches acquittements for [friendId] in reverse chronological order.
  ///
  /// Emits on every database change; used by Story 5-4 contact history log
  /// and Story 5-5 care-score update.
  Stream<List<Acquittement>> watchByFriendId(String friendId) =>
      (select(acquittements)
            ..where((a) => a.friendId.equals(friendId))
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .watch();

  /// Returns the most recent `createdAt` timestamp per friend as a map.
  ///
  /// Result: `{friendId: maxCreatedAtMillis}`. Friends with no acquittements
  /// are absent from the map (LEFT JOIN handled at provider level).
  ///
  /// Story 8.4 — "Last contact" display.
  Future<Map<String, int>> maxCreatedAtByFriendId() async {
    final query = selectOnly(acquittements)
      ..addColumns([acquittements.friendId, acquittements.createdAt.max()])
      ..groupBy([acquittements.friendId]);

    final rows = await query.get();
    final result = <String, int>{};
    for (final row in rows) {
      final fid = row.read(acquittements.friendId);
      final maxTs = row.read(acquittements.createdAt.max());
      if (fid != null && maxTs != null) {
        result[fid] = maxTs;
      }
    }
    return result;
  }

  /// Watches the most recent `createdAt` timestamp per friend.
  ///
  /// Re-emits whenever any acquittement row changes.
  /// Story 8.4 — reactive "Last contact" display on list tiles.
  Stream<Map<String, int>> watchMaxCreatedAtByFriend() {
    final query = selectOnly(acquittements)
      ..addColumns([acquittements.friendId, acquittements.createdAt.max()])
      ..groupBy([acquittements.friendId]);

    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        final fid = row.read(acquittements.friendId);
        final maxTs = row.read(acquittements.createdAt.max());
        if (fid != null && maxTs != null) {
          result[fid] = maxTs;
        }
      }
      return result;
    });
  }
}
