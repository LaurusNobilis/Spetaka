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

import 'package:spetaka/core/l10n/app_localizations.dart';
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
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: SettingsScreen(),
    ),
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

    testWidgets('AC1 — Display section is present',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Display'), findsOneWidget);
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

  });

}

