import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/shared/utils/relative_date.dart';

void main() {
  group('formatRelativeDate', () {
    final now = DateTime(2026, 3, 25, 12);

    test('returns English relative dates', () {
      expect(
        formatRelativeDate(now, now: now, languageCode: 'en'),
        equals('Today'),
      );
      expect(
        formatRelativeDate(
          now.add(const Duration(days: 1)),
          now: now,
          languageCode: 'en',
        ),
        equals('Tomorrow'),
      );
      expect(
        formatRelativeDate(
          now.add(const Duration(days: 3)),
          now: now,
          languageCode: 'en',
        ),
        equals('In 3 days'),
      );
      expect(
        formatRelativeDate(
          now.subtract(const Duration(days: 1)),
          now: now,
          languageCode: 'en',
        ),
        equals('Yesterday'),
      );
      expect(
        formatRelativeDate(
          now.subtract(const Duration(days: 21)),
          now: now,
          languageCode: 'en',
        ),
        equals('3 weeks ago'),
      );
    });

    test('returns French relative dates', () {
      expect(
        formatRelativeDate(now, now: now, languageCode: 'fr'),
        equals("Aujourd'hui"),
      );
      expect(
        formatRelativeDate(
          now.add(const Duration(days: 1)),
          now: now,
          languageCode: 'fr',
        ),
        equals('Demain'),
      );
      expect(
        formatRelativeDate(
          now.add(const Duration(days: 3)),
          now: now,
          languageCode: 'fr',
        ),
        equals('Dans 3 jours'),
      );
      expect(
        formatRelativeDate(
          now.subtract(const Duration(days: 1)),
          now: now,
          languageCode: 'fr',
        ),
        equals('Hier'),
      );
      expect(
        formatRelativeDate(
          now.subtract(const Duration(days: 60)),
          now: now,
          languageCode: 'fr',
        ),
        equals('Il y a 2 mois'),
      );
    });
  });
}