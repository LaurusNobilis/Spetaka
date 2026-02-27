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

  // TODO(laurus): Add event CRUD queries when the Event table is introduced (Epic 3).
}
