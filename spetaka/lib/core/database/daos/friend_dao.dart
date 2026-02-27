import 'package:drift/drift.dart';

import '../../../features/friends/domain/friend.dart';
import '../app_database.dart';

part 'friend_dao.g.dart';

/// DAO for Friend entity persistence.
///
/// Encryption-agnostic: receives and returns raw stored values.
/// Sensitive fields (`notes`, `concern_note`) will be ciphertext strings
/// when persisted; decryption is the sole responsibility of
/// [FriendRepository].
///
/// Table: [Friends] — schema introduced in Story 1.7.
@DriftAccessor(tables: [Friends])
class FriendDao extends DatabaseAccessor<AppDatabase> with _$FriendDaoMixin {
  FriendDao(super.db);

  /// Inserts a new friend row. Returns the SQLite rowid of the inserted row.
  Future<int> insertFriend(Insertable<Friend> entry) =>
      into(friends).insert(entry);

  /// Returns the [Friend] row with the given UUID [id], or null if absent.
  Future<Friend?> findById(String id) =>
      (select(friends)..where((f) => f.id.equals(id))).getSingleOrNull();

  /// Watches all friends; emits a new list on every database change.
  Stream<List<Friend>> watchAll() => select(friends).watch();

  /// Watches a single friend by UUID [id]; emits on every database change.
  ///
  /// Emits `null` when no friend with [id] exists in the table.
  Stream<Friend?> watchById(String id) =>
      (select(friends)..where((f) => f.id.equals(id))).watchSingleOrNull();

  /// Replaces the existing friend row identified by the companion's primary key.
  Future<bool> updateFriend(Insertable<Friend> entry) =>
      update(friends).replace(entry);

  /// Deletes the friend row with [id]. Returns the number of rows deleted.
  Future<int> deleteFriend(String id) =>
      (delete(friends)..where((f) => f.id.equals(id))).go();

  /// Returns all friend rows — useful for raw DAO-level ciphertext assertions
  /// in repository tests.
  Future<List<Friend>> selectAll() => select(friends).get();
}
