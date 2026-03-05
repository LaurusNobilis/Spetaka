// GreetingService — Story 4.4
//
// Pure Dart — no Flutter/Drift imports.
//
// Returns a single greeting phrase in Lora's voice, adapted to:
//   • number of surfaced cards (0 / 1 / 2+)
//   • concern active among surfaced entries
//   • time of day (morning / afternoon / evening)
//   • user name (defaults to 'Laurus' per project config)
//
// Tone: always encouraging, never punitive.

/// Generates a context-aware greeting for the daily view header.
///
/// This class is intentionally stateless and pure; instantiate it with a
/// custom [userName] or test-supply different [hour] values without mocking.
class GreetingService {
  const GreetingService({this.userName = 'Laurus'});

  final String userName;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a greeting string.
  ///
  /// [surfacedCount] — number of friends surfaced in today's daily view.
  /// [hasConcern]     — true if at least one surfaced friend has an active concern.
  /// [hour]           — hour of the day (0–23); defaults to [DateTime.now().hour].
  String greeting({
    required int surfacedCount,
    required bool hasConcern,
    int? hour,
  }) {
    final h = hour ?? DateTime.now().hour;
    final salutation = _salutation(h);

    if (surfacedCount == 0) {
      return '$salutation $userName — tout est calme aujourd\'hui. Prenez soin de vous 🌿';
    }

    if (hasConcern) {
      if (surfacedCount == 1) {
        return '$salutation $userName — quelqu\'un à qui vous tenez mérite un peu d\'attention aujourd\'hui 💙';
      }
      return '$salutation $userName — quelques personnes vous sont proches aujourd\'hui. Allez-y doucement, un geste à la fois 💙';
    }

    if (surfacedCount == 1) {
      return '$salutation $userName — une belle occasion de renouer le contact aujourd\'hui ✨';
    }

    return '$salutation $userName — $surfacedCount connexions vous attendent. Chaque petit geste compte 🌟';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _salutation(int hour) {
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}
