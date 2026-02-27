import 'package:drift/drift.dart';

import '../app_database.dart';

part 'acquittement_dao.g.dart';

/// DAO for Acquittement (contact-log) entity persistence.
///
/// SQL queries and table references will be added in Epic 5
/// (Acquittement feature stories).
@DriftAccessor(tables: [])
class AcquittementDao extends DatabaseAccessor<AppDatabase>
    with _$AcquittementDaoMixin {
  AcquittementDao(super.db);

  // TODO(Epic 5): Add acquittement queries when Acquittement table is introduced.
}
