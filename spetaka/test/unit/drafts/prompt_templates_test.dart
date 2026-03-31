// test/unit/drafts/prompt_templates_test.dart
//
// Tests PromptTemplates — couches 1-4 refactor
//
// Coverage:
//   Couche 1  — eventContext (type + note) toujours présent
//   Couche 2  — instruction bienveillant/compatissant toujours présente
//   Couche 3  — longueur basée sur le compte de mots-clés (≠ mots bruts)
//   Couche 4  — style injection (keywords, emojis, expressions) si ≥3 obs.
//   BC        — pas de "Style de l'utilisateur" si observations < 3

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/prompt_templates.dart';
import 'package:spetaka/core/database/app_database.dart';

// Helper to create a UserVoiceProfile test instance.
UserVoiceProfile _profile({
  String frequentKeywords = '[]',
  String frequentEmoji = '[]',
  String frequentExpression = '[]',
  int observationCount = 0,
}) =>
    UserVoiceProfile(
      id: 'user',
      frequentKeywords: frequentKeywords,
      frequentEmoji: frequentEmoji,
      frequentExpression: frequentExpression,
      observationCount: observationCount,
      updatedAt: 0,
    );

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  group('Couche 1 — base context', () {
    test('always contains "Génère 3 courts messages"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, contains('Génère 3 courts messages'));
    });

    test('includes friendName in prompt', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'René',
        eventType: 'check-in',
      );
      expect(prompt, contains('René'));
    });

    test('eventNote is included in eventContext when present', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'a perdu son père récemment',
      );
      expect(prompt, contains('anniversaire — a perdu son père récemment'));
    });

    test('no eventNote → only eventType in context', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, contains('anniversaire'));
      expect(prompt, isNot(contains('—')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('Couche 2 — tone instruction toujours bienveillant', () {
    test('prompt always contains "bienveillant et compatissant"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, contains('bienveillant et compatissant'));
    });

    test('with note → prompt references comment in tone instruction', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'sa situation est difficile',
      );
      expect(prompt, contains('bienveillant et compatissant'));
      expect(prompt, contains('sa situation est difficile'));
    });

    test('no emotion override — anxiety marker does NOT produce "Rassure"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'check-in',
        eventNote: 'il est très anxieux à ce sujet',
      );
      expect(prompt, isNot(contains('Rassure')));
      expect(prompt, contains('bienveillant et compatissant'));
    });

    test('no emotion override — grief marker does NOT produce "doux et sobre"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'check-in',
        eventNote: 'a perdu son père récemment, il traverse une période de deuil',
      );
      expect(prompt, isNot(contains('doux et sobre')));
      expect(prompt, contains('bienveillant et compatissant'));
    });

    test('no emotion override — joy marker does NOT produce "Célèbre"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'mariage',
        eventNote: 'super content de son mariage !',
      );
      expect(prompt, isNot(contains('Célèbre')));
      expect(prompt, contains('bienveillant et compatissant'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('Couche 3 — length instruction (keyword count)', () {
    test('null eventNote (0 keywords) → "maximum 15 mots"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, contains('maximum 15 mots'));
    });

    test('empty eventNote (0 keywords) → "maximum 15 mots"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: '',
      );
      expect(prompt, contains('maximum 15 mots'));
    });

    test('eventNote with only stop-words/short words (≤1 keyword) → "maximum 15 mots"', () {
      // "il est très bien" → no word ≥4 chars outside stop-words
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'il est très bien',
      );
      expect(prompt, contains('maximum 15 mots'));
    });

    test('eventNote with 2 keywords → "maximum 40 mots"', () {
      // "famille courage" → 2 keywords (≥4 chars, not stop words)
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'famille courage',
      );
      expect(prompt, contains('maximum 40 mots'));
    });

    test('eventNote with 4 keywords → "maximum 40 mots"', () {
      // "famille courage santé bonheur" → exactly 4 keywords
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'famille courage santé bonheur',
      );
      expect(prompt, contains('maximum 40 mots'));
    });

    test('eventNote with 5+ keywords → "plus de 40 mots"', () {
      // 5 keywords minimum: famille, courage, santé, bonheur, réussite
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'famille courage santé bonheur réussite',
      );
      expect(prompt, contains('plus de 40 mots'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('Couche 4 — style injection (≥3 obs.)', () {
    test('null voiceProfile → no "Style de l\'utilisateur"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, isNot(contains("Style de l'utilisateur")));
    });

    test('observationCount = 2 → no style injection (below threshold)', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(observationCount: 2, frequentKeywords: '{"famille":3}'),
      );
      expect(prompt, isNot(contains("Style de l'utilisateur")));
    });

    test('observationCount = 3 + keywords → "mots-clés récurrents" injected', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 3,
          frequentKeywords: '{"famille":3,"courage":2,"santé":1}',
        ),
      );
      expect(prompt, contains('mots-clés récurrents'));
      expect(prompt, contains('famille'));
      expect(prompt, contains('courage'));
    });

    test('observationCount = 3 + emojis → "emojis fréquents" injected', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 3,
          frequentEmoji: '{"🎉":5,"💪":3}',
        ),
      );
      expect(prompt, contains('emojis fréquents'));
      expect(prompt, contains('🎉'));
    });

    test('observationCount = 3 + expressions → "expressions fréquentes" injected', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 3,
          frequentExpression: '{"bonne continuation":4,"prends soin":2}',
        ),
      );
      expect(prompt, contains('expressions fréquentes'));
      expect(prompt, contains('bonne continuation'));
    });

    test('no legacy "niveau de formalité" in prompt', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 5,
          frequentKeywords: '{"famille":3}',
        ),
      );
      expect(prompt, isNot(contains('niveau de formalité')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('Concern note injection', () {
    test('concernNote present → "Préoccupation active" injected in prompt', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Prendre des nouvelles',
        concernNote: 'Elle traverse un divorce difficile',
      );
      expect(prompt, contains('Préoccupation active pour Sophie'));
      expect(prompt, contains('Elle traverse un divorce difficile'));
      expect(prompt, contains('délicatesse'));
    });

    test('null concernNote → no "Préoccupation active"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Prendre des nouvelles',
      );
      expect(prompt, isNot(contains('Préoccupation active')));
    });

    test('empty concernNote → no "Préoccupation active"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Prendre des nouvelles',
        concernNote: '',
      );
      expect(prompt, isNot(contains('Préoccupation active')));
    });

    test('whitespace-only concernNote → no "Préoccupation active"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Prendre des nouvelles',
        concernNote: '   ',
      );
      expect(prompt, isNot(contains('Préoccupation active')));
    });

    test('concernNote works alongside voiceProfile', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Sophie',
        eventType: 'Prendre des nouvelles',
        concernNote: 'Problèmes de santé',
        voiceProfile: _profile(
          observationCount: 5,
          frequentKeywords: '{"courage":3}',
        ),
      );
      expect(prompt, contains('Préoccupation active'));
      expect(prompt, contains("Style de l'utilisateur"));
    });
  });
}
