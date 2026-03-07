import '../../../core/database/app_database.dart';

/// Small snapshot of lightweight app settings that must survive restore.
///
/// This is Phase-1 scoped: only preferences that exist today and are
/// user-facing are included.
class BackupSettings {
  const BackupSettings({this.densityMode, this.darkModeEnabled});

  /// Daily view density preference stored in SharedPreferences.
  ///
  /// Expected values: 'compact' | 'expanded' (see DensityMode enum).
  final String? densityMode;

  /// Whether the app forces dark mode (stored in SharedPreferences).
  final bool? darkModeEnabled;

  Map<String, dynamic> toJson() => {
        'densityMode': densityMode,
      'darkModeEnabled': darkModeEnabled,
      };

  factory BackupSettings.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return BackupSettings(
      densityMode: map['densityMode'] as String?,
      darkModeEnabled: map['darkModeEnabled'] as bool?,
    );
  }
}

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
    required this.settings,
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

  /// Lightweight user settings snapshot (excluding any secrets/passphrases).
  final BackupSettings settings;

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
        'settings': settings.toJson(),
        'friends': friends.map((f) => _friendToBackupJson(f)).toList(),
        'events': events.map((e) => _eventToBackupJson(e)).toList(),
        'acquittements':
            acquittements.map((a) => _acquittementToBackupJson(a)).toList(),
        'eventTypes':
            eventTypes.map((t) => _eventTypeToBackupJson(t)).toList(),
      };

  /// Deserialises from a JSON map produced by [toJson].
  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      version: (json['version'] as num?)?.toInt() ?? currentVersion,
      exportedAt: json['exportedAt'] as String? ?? '',
      settings:
          BackupSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      friends: (json['friends'] as List<dynamic>? ?? const [])
          .map(
            (e) => Friend.fromJson(
              _friendFromBackupJson(e as Map<String, dynamic>),
            ),
          )
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .map(
            (e) => Event.fromJson(
              _eventFromBackupJson(e as Map<String, dynamic>),
            ),
          )
          .toList(),
      acquittements: (json['acquittements'] as List<dynamic>? ?? const [])
          .map(
            (e) => Acquittement.fromJson(
              _acquittementFromBackupJson(e as Map<String, dynamic>),
            ),
          )
          .toList(),
      eventTypes: (json['eventTypes'] as List<dynamic>? ?? const [])
          .map(
            (e) => EventTypeEntry.fromJson(
              _eventTypeFromBackupJson(e as Map<String, dynamic>),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Timestamp conversion helpers (AC: ISO 8601 timestamps in JSON)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _friendToBackupJson(Friend f) {
    final map = Map<String, dynamic>.from(f.toJson());
    _intMsToIso(map, 'createdAt');
    _intMsToIso(map, 'updatedAt');
    return map;
  }

  static Map<String, dynamic> _friendFromBackupJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    _isoToIntMs(map, 'createdAt');
    _isoToIntMs(map, 'updatedAt');
    return map;
  }

  static Map<String, dynamic> _eventToBackupJson(Event e) {
    final map = Map<String, dynamic>.from(e.toJson());
    _intMsToIso(map, 'date');
    _intMsToIso(map, 'acknowledgedAt');
    _intMsToIso(map, 'createdAt');
    return map;
  }

  static Map<String, dynamic> _eventFromBackupJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    _isoToIntMs(map, 'date');
    _isoToIntMs(map, 'acknowledgedAt');
    _isoToIntMs(map, 'createdAt');
    return map;
  }

  static Map<String, dynamic> _acquittementToBackupJson(Acquittement a) {
    final map = Map<String, dynamic>.from(a.toJson());
    _intMsToIso(map, 'createdAt');
    return map;
  }

  static Map<String, dynamic> _acquittementFromBackupJson(
    Map<String, dynamic> json,
  ) {
    final map = Map<String, dynamic>.from(json);
    _isoToIntMs(map, 'createdAt');
    return map;
  }

  static Map<String, dynamic> _eventTypeToBackupJson(EventTypeEntry t) {
    final map = Map<String, dynamic>.from(t.toJson());
    _intMsToIso(map, 'createdAt');
    return map;
  }

  static Map<String, dynamic> _eventTypeFromBackupJson(
    Map<String, dynamic> json,
  ) {
    final map = Map<String, dynamic>.from(json);
    _isoToIntMs(map, 'createdAt');
    return map;
  }

  static void _intMsToIso(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is int) {
      map[key] =
          DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toIso8601String();
    } else if (v is num) {
      map[key] = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true)
          .toIso8601String();
    }
  }

  static void _isoToIntMs(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is String && v.isNotEmpty) {
      // Accept ISO 8601 strings for portable backups.
      map[key] = DateTime.parse(v).toUtc().millisecondsSinceEpoch;
    }
  }
}
