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

  // TODO(laurus): Add acquittement queries when the Acquittement table is introduced (Epic 5).
}
