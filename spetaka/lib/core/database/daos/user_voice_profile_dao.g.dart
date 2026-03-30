// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_voice_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$UserVoiceProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserVoiceProfilesTable get userVoiceProfiles =>
      attachedDatabase.userVoiceProfiles;
  UserVoiceProfileDaoManager get managers => UserVoiceProfileDaoManager(this);
}

class UserVoiceProfileDaoManager {
  final _$UserVoiceProfileDaoMixin _db;
  UserVoiceProfileDaoManager(this._db);
  $$UserVoiceProfilesTableTableManager get userVoiceProfiles =>
      $$UserVoiceProfilesTableTableManager(
          _db.attachedDatabase, _db.userVoiceProfiles);
}
