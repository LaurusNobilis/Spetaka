import 'package:drift/drift.dart';

/// Drift table definition for the `user_voice_profiles` table.
///
/// Singleton row — always keyed 'user'. Stores the implicitly-learned
/// style vectors for LLM prompt injection.
class UserVoiceProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get frequentKeywords =>
      text().withDefault(const Constant('[]'))();
  TextColumn get frequentEmoji =>
      text().withDefault(const Constant('[]'))();
  TextColumn get frequentExpression =>
      text().withDefault(const Constant('[]'))();
  IntColumn get observationCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
