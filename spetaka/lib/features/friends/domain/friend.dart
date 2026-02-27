import 'package:drift/drift.dart';

/// Drift table definition for the `friends` table.
///
/// Schema introduced in Story 1.7 (encryption infrastructure) and aligned
/// with the full schema defined in Epic 2 Story 2.1.
///
/// Sensitive narrative fields:
///   - [notes]       — encrypted at repository layer (Story 1.7).
///   - [concernNote] — encrypted at repository layer (Story 1.7).
///
/// Non-sensitive fields remain plaintext for search/sort/phone operations:
///   name, mobile, careScore, isConcernActive, createdAt, updatedAt.
class Friends extends Table {
  /// UUID v4 primary key generated in Dart at creation time.
  TextColumn get id => text()();

  /// Display name — plaintext; used for search/sort.
  TextColumn get name => text()();

  /// Normalised E.164 mobile number — plaintext; required for phone actions.
  TextColumn get mobile => text()();

  /// Category tags — plaintext.
  ///
  /// Stored as a stable, explicit serialization format (Story 2.3):
  /// recommended JSON array string (e.g. ["Family","Work"]).
  ///
  /// Null means "no tags".
  TextColumn get tags => text().nullable()();

  /// Free-text narrative note — ENCRYPTED at repository layer.
  TextColumn get notes => text().nullable()();

  /// Floating-point care score; range [0.0, 1.0]; default 0.0.
  RealColumn get careScore => real().withDefault(const Constant(0.0))();

  /// Whether the concern/préoccupation flag is active; stored as 0/1.
  BoolColumn get isConcernActive =>
      boolean().withDefault(const Constant(false))();

  /// Free-text concern note — ENCRYPTED at repository layer.
  TextColumn get concernNote => text().nullable()();

  /// Unix-epoch milliseconds — timezone-independent timestamp.
  IntColumn get createdAt => integer()();

  /// Unix-epoch milliseconds — updated on every write.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
