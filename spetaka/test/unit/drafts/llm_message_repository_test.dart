// Unit tests for LlmMessageRepository — Story 10.2 (AC2, TDD Task 9)
//
// Tests cover:
//   - Happy path: 3 variants parsed from numbered list
//   - Empty response → empty variants list (AC6)
//   - Single variant parsed from single-item response

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/features/drafts/data/llm_message_repository.dart';

void main() {
  // ---------------------------------------------------------------------------
  // _parseVariants (static, exposed as parseVariants for testing)
  // ---------------------------------------------------------------------------

  group('LlmMessageRepository.parseVariants — Story 10.2 AC2', () {
    test('parses 3 variants from a standard numbered list', () {
      final raw = [
        '1. Bonjour Sophie!\n2. Comment vas-tu?\n3. Pense à toi.',
      ];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants.length, 3);
      expect(variants[0], 'Bonjour Sophie!');
      expect(variants[1], 'Comment vas-tu?');
      expect(variants[2], 'Pense à toi.');
    });

    test('parses variants using ) bullet style', () {
      final raw = [
        '1) Premier message\n2) Deuxième message\n3) Troisième',
      ];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants.length, 3);
    });

    test('empty string returns empty list (AC6)', () {
      final variants = LlmMessageRepository.parseVariants(['']);
      expect(variants, isEmpty);
    });

    test('empty list returns empty list (AC6)', () {
      final variants = LlmMessageRepository.parseVariants([]);
      expect(variants, isEmpty);
    });

    test('single variant in response returns length 1 (AC2)', () {
      final raw = ['1. Only one.'];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants.length, 1);
      expect(variants[0], 'Only one.');
    });

    test('trims whitespace from parsed variants', () {
      final raw = ['1.   Trimmed   '];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants[0], 'Trimmed');
    });

    test('multiple raw strings joined before parsing', () {
      final raw = [
        '1. First fragment',
        '2. Second fragment',
        '3. Third fragment',
      ];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants.length, 3);
    });

    test('filters empty-after-trim variants', () {
      final raw = ['1.   \n2. Valid message\n3.   '];
      final variants = LlmMessageRepository.parseVariants(raw);
      expect(variants.length, 1);
      expect(variants[0], 'Valid message');
    });
  });
}
