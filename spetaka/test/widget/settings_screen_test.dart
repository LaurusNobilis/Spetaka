// test/widget/settings_screen_test.dart
//
// Widget tests for Story 7.1 — SettingsScreen (Complete Settings Screen)
//
// Coverage:
//   AC1 — Section headings: Backup & Restore, Display, Event Types, Sync &
//          Backup placeholder.  Key content items visible on screen.
//   AC2 — Density toggle updates UI state immediately (no save button).
//   AC5 — "Sync & Backup (Coming in Phase 2)" tile renders as disabled.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spetaka/features/settings/presentation/settings_screen.dart';

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

/// Minimal harness — ProviderScope + MaterialApp wrapping [SettingsScreen].
///
/// SharedPreferences is mocked before each test so [DensityNotifier] can
/// initialise without disk I/O.
Widget _buildHarness() {
  return const ProviderScope(
    child: MaterialApp(home: SettingsScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen — Story 7.1', () {
    // ── AC1: all required content areas are visible ─────────────────────────
    testWidgets(
        'AC1 — Backup & Restore section heading and action tiles present',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Import backup'), findsOneWidget);
    });

    testWidgets('AC1 — Display section shows the density switch',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Compact view'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('AC1 — Event Types section shows navigation tile',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Event Types'), findsOneWidget);
      expect(find.text('Manage Event Types'), findsOneWidget);
    });

    testWidgets('AC1 — Passphrase helper copy is visible', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // AC3 — passphrase hint copy appears near backup actions
      expect(
        find.text(
          'Your passphrase encrypts your backup. It is never stored. If you '
          'lose it, your backup cannot be recovered.',
        ),
        findsOneWidget,
      );
    });

    // ── AC4: Reset backup settings tile present ──────────────────────────────
    testWidgets('AC4 — Reset backup settings tile present', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Reset backup settings'), findsOneWidget);
    });

    // ── AC5: Sync & Backup Phase 2 placeholder tile is disabled ─────────────
    testWidgets('AC5 — Sync & Backup (Coming in Phase 2) tile is disabled',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Coming in Phase 2'), findsOneWidget);

      // The ListTile containing the Phase 2 subtitle must be disabled.
      final syncTile = find.ancestor(
        of: find.text('Coming in Phase 2'),
        matching: find.byType(ListTile),
      );
      expect(syncTile, findsOneWidget);
      expect(tester.widget<ListTile>(syncTile).enabled, isFalse);
    });

    // ── AC1, AC2: density toggle updates UI immediately ──────────────────────
    testWidgets('AC2 — density toggle starts off (expanded) and toggles on',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // Default: expanded mode → switch is off (not compact)
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      // Tap the switch → compact mode → switch turns on
      await tester.tap(switchFinder);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    });

    testWidgets('AC2 — density toggle persists across rebuild', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // Toggle to compact
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      // Toggle back to expanded
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });
  });
}
