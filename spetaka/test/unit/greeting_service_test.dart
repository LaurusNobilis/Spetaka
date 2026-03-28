// Story 4.4 — Unit tests for GreetingService.
//
// Pure Dart — no Flutter dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/greeting_service.dart';

void main() {
  const service = GreetingService(userName: 'Laurus');

  group('GreetingService — Story 4.4', () {
    // -----------------------------------------------------------------------
    // 0 surfaced
    // -----------------------------------------------------------------------

    test('AC1 — 0 surfaced, matin → message tout-va-bien', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 8);
      expect(g, contains('Bonjour'));
      expect(g, contains('Laurus'));
      expect(g, contains('calme'));
    });

    test('AC1 — 0 surfaced, après-midi → message tout-va-bien', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 14);
      expect(g, contains('Bon après-midi'));
    });

    test('AC1 — 0 surfaced, soir → message tout-va-bien', () {
      final g = service.greeting(surfacedCount: 0, hasConcern: false, hour: 20);
      expect(g, contains('Bonsoir'));
    });

    // -----------------------------------------------------------------------
    // 1 surfaced, no concern
    // -----------------------------------------------------------------------

    test('AC1 — 1 surfaced, pas de préoccupation → ton reconnexion', () {
      final g = service.greeting(surfacedCount: 1, hasConcern: false, hour: 9);
      expect(g, contains('Laurus'));
      expect(g, isNot(contains('calme')));
    });

    // -----------------------------------------------------------------------
    // 2+ surfaced, pas de préoccupation
    // -----------------------------------------------------------------------

    test('AC1 — 3 surfaced, pas de préoccupation → mentionne le nombre', () {
      final g = service.greeting(surfacedCount: 3, hasConcern: false, hour: 10);
      expect(g, contains('3'));
      expect(g, contains('Laurus'));
    });

    // -----------------------------------------------------------------------
    // Préoccupation active
    // -----------------------------------------------------------------------

    test('AC1 — 1 surfaced, préoccupation active → ton empathique', () {
      final g = service.greeting(surfacedCount: 1, hasConcern: true, hour: 10);
      expect(g, contains('Laurus'));
      // Ne doit pas utiliser la formule générique de reconnexion
      expect(g, isNot(contains('3 connexions')));
    });

    test('AC1 — 2 surfaced, préoccupation active → ton empathique groupe', () {
      final g = service.greeting(surfacedCount: 2, hasConcern: true, hour: 10);
      expect(g, contains('Laurus'));
    });

    // -----------------------------------------------------------------------
    // AC2 — Ton : toujours encourageant, jamais culpabilisant
    // -----------------------------------------------------------------------

    for (final surfaced in [0, 1, 2, 5]) {
      for (final concern in [false, true]) {
        for (final hour in [7, 13, 21]) {
          test(
              'AC2 — ton non-culpabilisant : surfaced=$surfaced concern=$concern hour=$hour',
              () {
            final g = service.greeting(
              surfacedCount: surfaced,
              hasConcern: concern,
              hour: hour,
            );
            // Ne doit jamais contenir de mots culpabilisants
            expect(g.toLowerCase(), isNot(contains('raté')));
            expect(g.toLowerCase(), isNot(contains('manqué')));
            expect(g.toLowerCase(), isNot(contains('ignoré')));
            expect(g.toLowerCase(), isNot(contains('honte')));
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
    // Heure par défaut (sans paramètre)
    // -----------------------------------------------------------------------

    test('utilise DateTime.now().hour quand hour n\'est pas fourni', () {
      // Ne doit pas lever d'exception ; résultat dépend de l'heure actuelle.
      final g = service.greeting(surfacedCount: 1, hasConcern: false);
      expect(g, contains('Laurus'));
    });
  });
}
