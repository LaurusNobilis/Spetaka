import 'package:drift/drift.dart';

import '../app_database.dart';

part 'settings_dao.g.dart';

/// DAO for Settings entity persistence.
///
/// SQL queries and table references will be added in Epic 7
/// (Settings feature stories).
@DriftAccessor(tables: [])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // TODO(laurus): Add settings queries when the Settings table is introduced (Epic 7).
}
