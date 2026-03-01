// DensityProvider — Story 4.4
//
// Persists the user's density preference (compact / expanded) for the daily
// list using shared_preferences (key: 'density_mode').
//
// The notifier initialises to [DensityMode.expanded] then asynchronously
// loads the stored preference so the UI never blocks on I/O at startup.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable density for the daily view card list.
enum DensityMode { compact, expanded }

const _kDensityModeKey = 'density_mode';

/// Riverpod notifier that exposes and persists [DensityMode].
class DensityNotifier extends Notifier<DensityMode> {
  @override
  DensityMode build() {
    // Schedule async load; first frame shows the default.
    Future.microtask(_loadFromPrefs);
    return DensityMode.expanded;
  }

  /// Toggles between [DensityMode.compact] and [DensityMode.expanded] and
  /// persists the new value.
  Future<void> toggle() async {
    final next =
        state == DensityMode.compact ? DensityMode.expanded : DensityMode.compact;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDensityModeKey, next.name);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDensityModeKey);
    if (stored == DensityMode.compact.name) {
      state = DensityMode.compact;
    }
  }
}

/// Provider for the current [DensityMode].
///
/// Consume with `ref.watch(densityModeProvider)` and toggle via
/// `ref.read(densityModeProvider.notifier).toggle()`.
final densityModeProvider =
    NotifierProvider<DensityNotifier, DensityMode>(DensityNotifier.new);
