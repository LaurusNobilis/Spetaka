import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/actions/phone_normalizer.dart';
import 'package:spetaka/core/errors/app_error.dart';

void main() {
  const normalizer = PhoneNormalizer();

  group('PhoneNormalizer.normalize()', () {
    // ── AC2 / AC5 mandatory cases ──────────────────────────────────────────

    test('French local 10-digit: 0612345678 → +33612345678', () {
      expect(normalizer.normalize('0612345678'), '+33612345678');
    });

    test('Already E.164: +33612345678 unchanged', () {
      expect(normalizer.normalize('+33612345678'), '+33612345678');
    });

    test('Letters-only input throws PhoneNormalizationAppError', () {
      expect(
        () => normalizer.normalize('abcdefgh'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });

    // ── Additional robustness ──────────────────────────────────────────────

    test('Empty string throws PhoneNormalizationAppError', () {
      expect(
        () => normalizer.normalize(''),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });

    test('Strips spaces before normalizing: "06 12 34 56 78" → +33612345678',
        () {
      expect(normalizer.normalize('06 12 34 56 78'), '+33612345678');
    });

    test('Strips dashes: "06-12-34-56-78" → +33612345678', () {
      expect(normalizer.normalize('06-12-34-56-78'), '+33612345678');
    });

    test('Strips dots: "06.12.34.56.78" → +33612345678', () {
      expect(normalizer.normalize('06.12.34.56.78'), '+33612345678');
    });

    test('Strips parentheses: "(06)12345678" → +33612345678', () {
      expect(normalizer.normalize('(06)12345678'), '+33612345678');
    });

    test('Mixed letters and digits throws PhoneNormalizationAppError', () {
      expect(
        () => normalizer.normalize('0612abc78'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });

    test('Already E.164 international: +447911123456 unchanged', () {
      expect(normalizer.normalize('+447911123456'), '+447911123456');
    });

    test('Unrecognized pure digit format (8 digits, no leading 0) throws', () {
      expect(
        () => normalizer.normalize('12345678'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });

    test('PhoneNormalizationAppError has code phone_normalization_failed', () {
      const error = PhoneNormalizationAppError('test_reason');
      expect(error.code, 'phone_normalization_failed');
      expect(error.reason, 'test_reason');
    });

    test('PhoneNormalizationAppError is an AppError', () {
      expect(const PhoneNormalizationAppError('x'), isA<AppError>());
    });
  });
}
