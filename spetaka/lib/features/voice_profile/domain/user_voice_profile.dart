import 'package:drift/drift.dart';

/// Drift table definition for the `user_voice_profiles` table.
///
/// Singleton row — always keyed 'user'. Stores the 3 implicitly-learned
/// style vectors for LLM prompt injection (Story 10.6).
class UserVoiceProfiles extends Table {
  TextColumn get id => text()();
  IntColumn get formalityScore =>
      integer().withDefault(const Constant(5))();
  RealColumn get avgWordCount =>
      real().withDefault(const Constant(0.0))();
  TextColumn get frequentKeywords =>
      text().withDefault(const Constant('[]'))();
  IntColumn get observationCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
