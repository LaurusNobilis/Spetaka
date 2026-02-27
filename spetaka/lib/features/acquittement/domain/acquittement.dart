import 'package:drift/drift.dart';

/// Drift table definition for the `acquittements` table.
///
/// Schema introduced in Story 1.7 (encryption infrastructure).
/// Extended in Epic 5 Story 5.3 with UI/UX interaction.
///
/// Sensitive field:
///   - [note] — optional free-text note; ENCRYPTED at repository layer.
///
/// Non-sensitive fields remain plaintext: friendId, type, createdAt.
class Acquittements extends Table {
  /// UUID v4 primary key generated in Dart at creation time.
  TextColumn get id => text()();

  /// Foreign key reference to [Friends.id].
  TextColumn get friendId => text()();

  /// Action type (e.g., 'call', 'sms', 'whatsapp', 'in_person') — plaintext.
  TextColumn get type => text()();

  /// Optional free-text note — ENCRYPTED at repository layer.
  TextColumn get note => text().nullable()();

  /// Unix-epoch milliseconds — timezone-independent creation timestamp.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
