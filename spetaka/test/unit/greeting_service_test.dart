// Story 4.4 — Unit tests for GreetingService.
//
// Pure Dart — no Flutter dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/features/daily/domain/greeting_service.dart';

void main() {
  const service = GreetingService(userName: 'Laurus');

  group('GreetingService — Story 4.4', () {
    // -----------------------------------------------------------------------
    // 0 surfaced
    // -----------------------------------------------------------------------

    test('AC1 — 0 surfaced, morning → all-clear greeting', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 8);
      expect(g, contains('Good morning'));
      expect(g, contains('Laurus'));
      expect(g, contains('all clear'));
    });

    test('AC1 — 0 surfaced, afternoon → all-clear greeting', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 14);
      expect(g, contains('Good afternoon'));
    });

    test('AC1 — 0 surfaced, evening → all-clear greeting', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 20);
      expect(g, contains('Good evening'));
    });

    // -----------------------------------------------------------------------
    // 1 surfaced, no concern
    // -----------------------------------------------------------------------

    test('AC1 — 1 surfaced, no concern → reconnect tone', () {
      final g = service.greeting(surfacedCount: 1, hasConcern: false, hour: 9);
      expect(g, contains('Laurus'));
      expect(g, isNot(contains('all clear')));
    });

    // -----------------------------------------------------------------------
    // 2+ surfaced, no concern
    // -----------------------------------------------------------------------

    test('AC1 — 3 surfaced, no concern → mentions count', () {
      final g = service.greeting(surfacedCount: 3, hasConcern: false, hour: 10);
      expect(g, contains('3'));
      expect(g, contains('Laurus'));
    });

    // -----------------------------------------------------------------------
    // Concern present
    // -----------------------------------------------------------------------

    test('AC1 — 1 surfaced, concern active → empathetic tone', () {
      final g = service.greeting(surfacedCount: 1, hasConcern: true, hour: 10);
      expect(g, contains('Laurus'));
      // Should not use generic reconnect phrase — concern variant
      expect(g, isNot(contains('3 connections')));
    });

    test('AC1 — 2 surfaced, concern active → group empathetic tone', () {
      final g = service.greeting(surfacedCount: 2, hasConcern: true, hour: 10);
      expect(g, contains('Laurus'));
    });

    // -----------------------------------------------------------------------
    // AC2 — Tone: always encouraging, non-punitive
    // -----------------------------------------------------------------------

    for (final surfaced in [0, 1, 2, 5]) {
      for (final concern in [false, true]) {
        for (final hour in [7, 13, 21]) {
          test(
              'AC2 — tone non-punitive: surfaced=$surfaced concern=$concern hour=$hour',
              () {
            final g = service.greeting(
              surfacedCount: surfaced,
              hasConcern: concern,
              hour: hour,
            );
            // Should never contain punishing words
            expect(g.toLowerCase(), isNot(contains('failed')));
            expect(g.toLowerCase(), isNot(contains('missed')));
            expect(g.toLowerCase(), isNot(contains('ignored')));
            expect(g.toLowerCase(), isNot(contains('shame')));
            expect(g, isNotEmpty);
          });
        }
      }
    }

    // -----------------------------------------------------------------------
    // Default hour (no override)
    // -----------------------------------------------------------------------

    test('uses DateTime.now().hour when hour not supplied', () {
      // Should not throw; result depends on current time.
      final g = service.greeting(surfacedCount: 1, hasConcern: false);
      expect(g, contains('Laurus'));
    });
  });
}
