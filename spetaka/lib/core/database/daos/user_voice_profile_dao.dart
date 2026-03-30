import 'package:drift/drift.dart';

import '../../../features/voice_profile/domain/user_voice_profile.dart';
import '../app_database.dart';

part 'user_voice_profile_dao.g.dart';

@DriftAccessor(tables: [UserVoiceProfiles])
class UserVoiceProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserVoiceProfileDaoMixin {
  UserVoiceProfileDao(super.db);

  static const _singletonId = 'user';

  Future<UserVoiceProfile?> getProfile() =>
      (select(userVoiceProfiles)
            ..where((t) => t.id.equals(_singletonId)))
          .getSingleOrNull();

  Future<void> upsertProfile(UserVoiceProfilesCompanion entry) =>
      into(userVoiceProfiles).insertOnConflictUpdate(entry);

  Future<void> deleteProfile() =>
      (delete(userVoiceProfiles)..where((t) => t.id.equals(_singletonId))).go();
}
