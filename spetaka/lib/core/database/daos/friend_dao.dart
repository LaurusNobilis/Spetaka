import 'package:drift/drift.dart';

import '../app_database.dart';

part 'friend_dao.g.dart';

/// DAO for Friend entity persistence.
///
/// SQL queries and table references will be added in Epic 2
/// (Friend Card feature stories).
@DriftAccessor(tables: [])
class FriendDao extends DatabaseAccessor<AppDatabase>
    with _$FriendDaoMixin {
  FriendDao(super.db);

  // TODO(laurus): Add friend CRUD queries when the Friend table is introduced (Epic 2).
}
