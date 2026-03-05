/// Default event types introduced in Story 3.1.
///
/// FR15: System provides 5 default event types at first launch.
enum EventType {
  birthday,
  weddingAnniversary,
  importantLifeEvent,
  regularCheckin,
  importantAppointment;

  /// Creates an [EventType] from its persisted name string.
  ///
  /// Falls back to [regularCheckin] for unknown values (forward-compatibility).
  static EventType fromString(String s) => EventType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => EventType.regularCheckin,
      );

  /// Human-readable label shown in the UI.
  String get displayLabel => switch (this) {
        EventType.birthday => 'Anniversaire',
        EventType.weddingAnniversary => 'Anniversaire de mariage',
        EventType.importantLifeEvent => 'Événement important',
        EventType.regularCheckin => 'Appel de suivi',
        EventType.importantAppointment => 'Rendez-vous important',
      };

  /// Compact name persisted in SQLite.
  String get storedName => name;
}
