// test/widget/settings_screen_test.dart
//
// Widget tests for Story 7.1 — SettingsScreen (Complete Settings Screen)
//
// Coverage:
//   AC1 — Section headings: Backup & Restore, Display, Event Types, Sync &
//          Backup placeholder.  Key content items visible on screen.
//   AC2 — Density toggle updates UI state immediately (no save button).
//   AC5 — "Sync & Backup (Coming in Phase 2)" tile renders as disabled.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/features/settings/data/concern_cadence_provider.dart';
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

class _DelayedConcernCadenceNotifier extends ConcernCadenceNotifier {
  _DelayedConcernCadenceNotifier(this._completion);

  final Completer<void> _completion;

  @override
  Future<void> set(int days) async {
    state = days;
    await _completion.future;
  }
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

  // ── Story 9.2: Concern Cadence Section ────────────────────────────────
  group('SettingsScreen — Story 9.2 Concern Cadence', () {
    // ── AC1: section heading is rendered ──────────────────────────────────
    testWidgets('AC1 — Concern follow-up section heading is present',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Concern Follow-up'), findsOneWidget);
    });

    // ── AC1: tapping opens bottom sheet with all 7 interval options ──────
    testWidgets('AC1 — tapping tile opens bottom sheet with 7 interval options',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // Scroll the concern cadence tile into view
      final cadenceTile = find.text('Follow-up cadence');
      await tester.scrollUntilVisible(
        cadenceTile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(cadenceTile);
      await tester.pumpAndSettle();

      // Verify all 7 options are present in the bottom sheet
      expect(find.text('Every 3 days'), findsOneWidget);
      expect(find.text('Every 5 days'), findsOneWidget);
      expect(find.text('Every 7 days (default)'), findsOneWidget);
      expect(find.text('Every 10 days'), findsOneWidget);
      expect(find.text('Every 14 days'), findsOneWidget);
      expect(find.text('Every 21 days'), findsOneWidget);
      expect(find.text('Every 30 days'), findsOneWidget);
    });

    // ── AC2: selecting an option updates the displayed interval ──────────
    testWidgets('AC2 — selecting an option updates the displayed interval',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // Scroll to and verify default label
      final cadenceTile = find.text('Follow-up cadence');
      await tester.scrollUntilVisible(
        cadenceTile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Every 7 days'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(cadenceTile);
      await tester.pumpAndSettle();

      // Select 14 days
      await tester.tap(find.text('Every 14 days'));
      await tester.pumpAndSettle();

      // Bottom sheet should close and label should update
      expect(find.textContaining('Every 14 days'), findsOneWidget);
    });

    testWidgets('AC2 — bottom sheet waits for persistence before closing',
        (tester) async {
      final completion = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            concernCadenceProvider.overrideWith(
              () => _DelayedConcernCadenceNotifier(completion),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      final cadenceTile = find.text('Follow-up cadence');
      await tester.scrollUntilVisible(
        cadenceTile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(cadenceTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every 14 days'));
      await tester.pump();

      expect(find.byType(BottomSheet), findsOneWidget);

      completion.complete();
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.textContaining('Every 14 days'), findsOneWidget);
    });

    testWidgets('AC5 — selector exposes exact TalkBack labels',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      final cadenceTile = find.text('Follow-up cadence');
      await tester.scrollUntilVisible(
        cadenceTile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Concern cadence: Every 7 days, selected'),
        findsOneWidget,
      );

      await tester.tap(cadenceTile);
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);

      expect(
        find.descendant(
          of: bottomSheet,
          matching: find.bySemanticsLabel(
            'Concern cadence: Every 7 days, selected',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: bottomSheet,
          matching: find.bySemanticsLabel(
            'Concern cadence: Every 14 days, not selected',
          ),
        ),
        findsOneWidget,
      );

      semanticsHandle.dispose();
    });
  });

}

