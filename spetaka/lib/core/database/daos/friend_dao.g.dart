// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_dao.dart';

// ignore_for_file: type=lint
mixin _$FriendDaoMixin on DatabaseAccessor<AppDatabase> {
  $FriendsTable get friends => attachedDatabase.friends;
  FriendDaoManager get managers => FriendDaoManager(this);
}

class FriendDaoManager {
  final _$FriendDaoMixin _db;
  FriendDaoManager(this._db);
  $$FriendsTableTableManager get friends =>
      $$FriendsTableTableManager(_db.attachedDatabase, _db.friends);
}
