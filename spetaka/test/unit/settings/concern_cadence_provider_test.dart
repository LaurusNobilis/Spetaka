// test/unit/settings/concern_cadence_provider_test.dart
//
// Unit tests for Story 9.2 — ConcernCadenceNotifier
//
// Coverage:
//   AC4 — default value is 7 when no preference stored
//   AC2 — set() updates state and persists to shared_preferences
//   AC2 — build() reads stored value from shared_preferences on init

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spetaka/features/settings/data/concern_cadence_provider.dart';

void main() {
  group('ConcernCadenceNotifier — Story 9.2', () {
    // ── AC4: default value is 7 when no preference stored ──────────────
    test('default value is 7 when no preference stored', () {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(concernCadenceProvider);
      expect(value, 7);
    });

    // ── AC2: set(14) → state updates to 14, persisted to shared_preferences ─
    test('set() updates state and persists to shared_preferences', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial default
      expect(container.read(concernCadenceProvider), 7);

      // Set new value
      await container.read(concernCadenceProvider.notifier).set(14);

      // State updated
      expect(container.read(concernCadenceProvider), 14);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('concern_cadence_days'), 14);
    });

    // ── AC2/AC4: build reads stored value from shared_preferences on init ──
    test('build reads stored value from shared_preferences on init', () async {
      SharedPreferences.setMockInitialValues({'concern_cadence_days': 21});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Immediately returns default (7) — async load hasn't fired yet
      expect(container.read(concernCadenceProvider), 7);

      // Wait for microtask to complete the async load
      await Future<void>.delayed(Duration.zero);

      // Now should reflect the stored value
      expect(container.read(concernCadenceProvider), 21);
    });

    test('invalid stored value falls back to 7 and rewrites preference', () async {
      SharedPreferences.setMockInitialValues({'concern_cadence_days': 999});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(concernCadenceProvider), 7);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(concernCadenceProvider), 7);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('concern_cadence_days'), 7);
    });

    test('set() sanitizes unsupported value back to 7', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(concernCadenceProvider.notifier).set(999);

      expect(container.read(concernCadenceProvider), 7);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('concern_cadence_days'), 7);
    });
  });
}
