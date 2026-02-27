import 'package:drift/drift.dart';

import '../app_database.dart';

part 'event_dao.g.dart';

/// DAO for Event entity persistence.
///
/// SQL queries and table references will be added in Epic 3
/// (Event feature stories).
@DriftAccessor(tables: [])
class EventDao extends DatabaseAccessor<AppDatabase>
    with _$EventDaoMixin {
  EventDao(super.db);

  // TODO(Epic 3): Add event CRUD queries when Event table is introduced.
}
