// concern_cadence_provider.dart
//
// Persists the user's preferred concern-cadence interval (in days) via
// shared_preferences.  Follows the same Notifier pattern as
// DarkModeEnabledNotifier / FontScaleNotifier in display_prefs_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kConcernCadenceDaysKey = 'concern_cadence_days';

/// Fixed concern cadence interval options supported by the app.
const concernCadenceOptions = <int>[3, 5, 7, 10, 14, 21, 30];

final _kConcernCadenceOptionsSet = concernCadenceOptions.toSet();

/// Default concern cadence interval in days.
const kDefaultConcernCadenceDays = 7;

/// Notifier that exposes and persists the concern-cadence interval.
///
/// Always returns a valid [int] (default `7`).  Story 9.1 reads this value
/// via `ref.read(concernCadenceProvider)` when auto-creating concern cadences.
class ConcernCadenceNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(_load);
    return kDefaultConcernCadenceDays;
  }

  Future<void> set(int days) async {
    final sanitizedDays = _sanitize(days);
    state = sanitizedDays;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kConcernCadenceDaysKey, sanitizedDays);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kConcernCadenceDaysKey);
    if (stored == null) return;

    final sanitizedDays = _sanitize(stored);
    state = sanitizedDays;

    if (sanitizedDays != stored) {
      await prefs.setInt(_kConcernCadenceDaysKey, sanitizedDays);
    }
  }

  int _sanitize(int days) {
    if (_kConcernCadenceOptionsSet.contains(days)) {
      return days;
    }

    return kDefaultConcernCadenceDays;
  }
}

/// Provider for the concern-cadence interval in days.
final concernCadenceProvider =
    NotifierProvider<ConcernCadenceNotifier, int>(
  ConcernCadenceNotifier.new,
);
