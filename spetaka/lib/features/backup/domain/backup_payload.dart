import '../../../core/database/app_database.dart';

/// Serializable snapshot of all user data for a portable encrypted backup.
///
/// - Demo friends (`isDemo == true`) are **always excluded** (Story 6.5 AC1).
/// - All timestamps are exposed as-is (Unix-epoch milliseconds); ISO 8601
///   conversion for the JSON envelope is handled by [BackupRepository].
/// - Drift-generated data classes already provide `toJson()` / `fromJson()` so
///   serialization is straightforward.
class BackupPayload {
  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.friends,
    required this.events,
    required this.acquittements,
    required this.eventTypes,
  });

  /// Current schema version; increment on breaking layout changes.
  static const int currentVersion = 1;

  /// Backup schema version (written on export, validated on import).
  final int version;

  /// ISO 8601 timestamp of when the backup was created.
  final String exportedAt;

  /// Non-demo friend records (sensitive fields arrive decrypted).
  final List<Friend> friends;

  /// All event records for the exported friends.
  final List<Event> events;

  /// All acquittement (contact-log) records; [note] arrives decrypted.
  final List<Acquittement> acquittements;

  /// User-defined event types.
  final List<EventTypeEntry> eventTypes;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Converts to a JSON-serialisable map.
  ///
  /// Drift data classes supply their own `toJson()` implementations, so each
  /// entity list is mapped directly.
  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt,
        'friends': friends.map((f) => f.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'acquittements': acquittements.map((a) => a.toJson()).toList(),
        'eventTypes': eventTypes.map((t) => t.toJson()).toList(),
      };

  /// Deserialises from a JSON map produced by [toJson].
  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      version: (json['version'] as num?)?.toInt() ?? currentVersion,
      exportedAt: json['exportedAt'] as String? ?? '',
      friends: (json['friends'] as List<dynamic>)
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      acquittements: (json['acquittements'] as List<dynamic>)
          .map((e) => Acquittement.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventTypes: (json['eventTypes'] as List<dynamic>)
          .map((e) => EventTypeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
