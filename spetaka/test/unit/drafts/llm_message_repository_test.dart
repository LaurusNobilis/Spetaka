// Unit tests for LlmMessageRepository — Story 10.2 (AC2, TDD Task 9)
//                                     — Story 10.5 (AC1, PromptTemplates tonal modifier)
//
// Tests cover:
//   - Happy path: 3 variants parsed from numbered list
//   - Empty response → empty variants list (AC6)
//   - Single variant parsed from single-item response
//   - PromptTemplates.messageSuggestion tonal modifier (Story 10.5 AC1)

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/prompt_templates.dart';
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

  // ---------------------------------------------------------------------------
  // PromptTemplates.messageSuggestion — tonal modifier (Story 10.5 AC1)
  // ---------------------------------------------------------------------------

  group('PromptTemplates.messageSuggestion — tonal modifier (Story 10.5 AC1)',
      () {
    test('with eventNote=null → prompt does NOT contain "Contexte important"',
        () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
        eventNote: null,
      );
      expect(prompt, isNot(contains('Contexte important')));
    });

    test('with eventNote="" → prompt does NOT contain "Contexte important"',
        () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
        eventNote: '',
      );
      expect(prompt, isNot(contains('Contexte important')));
    });

    test(
        'with eventNote non-empty → prompt DOES contain tonal instruction with note',
        () {
      // Use a neutral eventNote (no emotion markers) so Story 10.5 toneInstruction
      // fires; notes with emotion markers now trigger Story 10.6 emotion override.
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
        eventNote: 'prépare un voyage en vacances prochainement',
      );
      expect(
        prompt,
        contains(
          'Contexte important : prépare un voyage en vacances prochainement. Adapte le ton',
        ),
      );
    });

    test('prompt always contains "Génère 3 courts messages" (smoke test)', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
      );
      expect(prompt, contains('Génère 3 courts messages'));
    });

    test('with note → eventContext combines eventType and eventNote', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
        eventNote: 'a perdu son père',
      );
      expect(
        prompt,
        contains('Anniversaire — a perdu son père'),
      );
    });

    test('without note → eventContext equals eventType only', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Anniversaire',
      );
      expect(prompt, contains("l'occasion de : Anniversaire."));
      expect(
        prompt,
        isNot(contains(' — ')),
      );
    });
  });
}
