// test/unit/drafts/prompt_templates_test.dart
//
// Tests Story 10.6 — PromptTemplates voice-profile + emotion-tone injection
//
// Coverage:
//   AC3  — style instruction injected when observationCount ≥ 3
//   AC9  — emotion tone override (anxiety → Rassure, grief → doux, joy → Célèbre)
//   AC9  — length instruction driven by eventNote word count
//   BC   — no regression on Story 10.5: null voiceProfile / low observations
//          produce no "Style requis" injection

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/prompt_templates.dart';
import 'package:spetaka/core/database/app_database.dart';

// Helper to create a UserVoiceProfile test instance.
UserVoiceProfile _profile({
  int formalityScore = 5,
  double avgWordCount = 0.0,
  String frequentKeywords = '[]',
  int observationCount = 0,
}) =>
    UserVoiceProfile(
      id: 'user',
      formalityScore: formalityScore,
      avgWordCount: avgWordCount,
      frequentKeywords: frequentKeywords,
      observationCount: observationCount,
      updatedAt: 0,
    );

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  group('messageSuggestion() — base structure', () {
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
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('Story 10.5 regression — voiceProfile integration', () {
    test('null voiceProfile → no "Style requis" in prompt', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, isNot(contains('Style requis')));
    });

    test('observationCount = 2 → no "Style requis" (below threshold)', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(observationCount: 2, formalityScore: 3),
      );
      expect(prompt, isNot(contains('Style requis')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('AC3 — style instruction (≥3 observations)', () {
    test('observationCount = 3 → "Style requis" injected', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 3,
          formalityScore: 5,
          avgWordCount: 10.0,
          frequentKeywords: '[]',
        ),
      );
      expect(prompt, contains('Style requis'));
    });

    test('formalityScore shown in style instruction', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 5,
          formalityScore: 3,
          avgWordCount: 15.5,
          frequentKeywords: '["famille","courage","santé"]',
        ),
      );
      expect(prompt, contains('niveau de formalité 3/10'));
    });

    test('top keywords appear in style instruction', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        voiceProfile: _profile(
          observationCount: 5,
          formalityScore: 7,
          avgWordCount: 10.0,
          frequentKeywords: '["famille","courage","santé"]',
        ),
      );
      expect(prompt, contains('famille'));
      expect(prompt, contains('courage'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('AC9 — length instruction', () {
    test('null eventNote → "maximum 8 mots"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, contains('maximum 8 mots'));
    });

    test('eventNote = "" → "maximum 8 mots"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: '',
      );
      expect(prompt, contains('maximum 8 mots'));
    });

    test('eventNote 3 words (≤3) → "maximum 8 mots"', () {
      // Neutral text — no emotion markers
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'petite surprise organisée',
      );
      expect(prompt, contains('maximum 8 mots'));
    });

    test('eventNote 8 words (4–15) → "maximum 20 mots"', () {
      // Neutral text — no emotion markers
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'il aimerait avoir de tes nouvelles cette semaine',
      );
      expect(prompt, contains('maximum 20 mots'));
    });

    test('eventNote 17 words (>15) → "maximum 40 mots"', () {
      // Neutral text — no emotion markers, 17 tokens
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'check-in',
        eventNote:
            'sa situation a beaucoup évolué cette année avec de nombreux changements dans sa vie personnelle et professionnelle',
      );
      expect(prompt, contains('maximum 40 mots'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('AC9 — emotion tone override', () {
    test('anxiety marker → contains "Rassure"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'check-in',
        eventNote: 'il est très anxieux à ce sujet',
      );
      expect(prompt, contains('Rassure'));
    });

    test('grief marker → contains "doux" (no anxiety markers present)', () {
      // Uses only grief markers: "perdu", "deuil" — no anxiety markers
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'check-in',
        eventNote: 'a perdu son père récemment, il traverse une période de deuil',
      );
      expect(prompt, contains('doux'));
    });

    test('joy marker → contains "Célèbre"', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'mariage',
        eventNote: 'super content de son mariage !',
      );
      expect(prompt, contains('Célèbre'));
    });

    test('no emotion marker → no override (Story 10.5 toneInstruction active)', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
        eventNote: 'pense à lui offrir quelque chose',
      );
      // No emotion override → Story 10.5 toneInstruction: "Contexte important"
      expect(prompt, contains('Contexte important'));
    });

    test('null eventNote → no emotion override, no toneInstruction', () {
      final prompt = PromptTemplates.messageSuggestion(
        friendName: 'Alice',
        eventType: 'anniversaire',
      );
      expect(prompt, isNot(contains('Rassure')));
      expect(prompt, isNot(contains('doux et sobre')));
      expect(prompt, isNot(contains('Célèbre')));
    });
  });
}
