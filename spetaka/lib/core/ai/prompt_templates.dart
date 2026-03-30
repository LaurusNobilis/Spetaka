// PromptTemplates — Story 10.1 (AC2)
//
// Central registry for ALL LLM prompt templates.
// No runtime prompt construction outside this file (architecture rule).
// Content will be filled in Stories 10.2 and 10.3.

import '../../core/database/app_database.dart';
import '../../features/voice_profile/data/user_voice_profile_repository.dart';

/// Static constants for all LLM prompt templates.
///
/// Every prompt string used by the app lives here.
/// Prompt construction must ONLY happen in this file.
abstract final class PromptTemplates {
  /// Message suggestion prompt template.
  ///
  /// Parameters:
  /// - [friendName]: Name of the friend.
  /// - [eventType]: Type of event (e.g., birthday, check-in).
  /// - [eventNote]: Optional note/context about the event.
  /// - [language]: Target language for the suggestion.
  /// - [voiceProfile]: Optional on-device learned style profile (Story 10.6).
  ///
  /// Content will be implemented in Story 10.2.
  static String messageSuggestion({
    required String friendName,
    required String eventType,
    String? eventNote,
    String language = 'fr',
    UserVoiceProfile? voiceProfile, // Story 10.6 — on-device style injection
  }) {
    final eventContext = eventNote != null && eventNote.isNotEmpty
        ? '$eventType — $eventNote'
        : eventType;

    // Story 10.5 — base tone instruction from event note context
    final baseToneInstruction = eventNote != null && eventNote.isNotEmpty
        ? '\nContexte important : $eventNote. Adapte le ton de tes messages en conséquence.'
        : '';

    // Story 10.6 AC9 — emotion tone override (Option A, deterministic, offline)
    final emotionOverride = _detectEmotionTone(eventNote);
    // If emotionOverride is detected it replaces the Story 10.5 toneInstruction
    final activeToneInstruction = emotionOverride ?? baseToneInstruction;

    // Story 10.6 AC9 — length instruction driven by commentDepth
    final lengthInstruction = _buildLengthInstruction(eventNote);

    // Story 10.6 AC3 — style instruction from UserVoiceProfile (≥3 observations)
    final styleInstruction = _buildStyleInstruction(voiceProfile);

    return '''Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.$activeToneInstruction$lengthInstruction$styleInstruction
Génère 3 courts messages $language chaleureux pour $friendName à l'occasion de : $eventContext.
Les messages doivent être chaleureux, personnels, naturels, et adaptés à un envoi par $language.
Formate ta réponse comme une liste numérotée :
1. [premier message]
2. [deuxième message]
3. [troisième message]
Ne génère rien d'autre.''';
  }

  // ---------------------------------------------------------------------------
  // Private helpers — Story 10.6 AC9
  // ---------------------------------------------------------------------------

  // Option A — keyword-based emotion detection, deterministic, offline (AC9)
  static const _anxietyMarkers = [
    'anxieux', 'stressé', 'peur', 'kiné', 'douleur', 'difficile', 'inquiet',
  ];
  static const _griefMarkers = [
    'perdu', 'décédé', 'deuil', 'séparation', 'rupture', 'triste',
  ];
  static const _joyMarkers = [
    'heureux', 'fier', 'excité', 'content', 'réussi', 'diplôme', 'bébé',
    'mariage',
  ];

  /// Returns an emotion-specific tone override string, or null if no marker
  /// is detected. When non-null, replaces the Story 10.5 toneInstruction.
  static String? _detectEmotionTone(String? eventNote) {
    if (eventNote == null || eventNote.trim().isEmpty) return null;
    final lower = eventNote.toLowerCase();
    if (_anxietyMarkers.any(lower.contains)) {
      return '\nRassure-le/la chaleureusement — il/elle est anxieux/anxieuse à ce sujet.';
    }
    if (_griefMarkers.any(lower.contains)) {
      return "\nAdopte un ton doux et sobre. Pas d'humour. Montre que tu es présent(e).";
    }
    if (_joyMarkers.any(lower.contains)) {
      return "\nCélèbre avec lui/elle — c'est un moment de joie !";
    }
    return null;
  }

  /// Returns a length constraint instruction based on word count of [eventNote].
  static String _buildLengthInstruction(String? eventNote) {
    final wordCount = eventNote == null
        ? 0
        : eventNote.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount <= 3) return '\nÉcris un message très court, maximum 8 mots.';
    if (wordCount <= 15) return '\nÉcris un message court, maximum 20 mots.';
    return '\nÉcris un message personnalisé, maximum 40 mots.';
  }

  // ---------------------------------------------------------------------------
  // Private helpers — Story 10.6 AC3
  // ---------------------------------------------------------------------------

  /// Returns a style constraint instruction from the [voiceProfile], or an
  /// empty string if the profile is null or below the minimum observation
  /// threshold.
  static String _buildStyleInstruction(UserVoiceProfile? profile) {
    if (profile == null || profile.observationCount < 3) return '';
    final avgWords = profile.avgWordCount.round();
    final topKeywords = UserVoiceProfileRepository.topKeywordsFromJson(
      profile.frequentKeywords,
    );
    final wordsPart = avgWords > 0 ? ', ~$avgWords mots par message' : '';
    final keywordsPart = topKeywords.isNotEmpty
        ? ', inclure si pertinent : ${topKeywords.join(', ')}'
        : '';
    return '\nStyle requis : niveau de formalité ${profile.formalityScore}/10$wordsPart$keywordsPart.';
  }

  /// Greeting line prompt template.
  ///
  /// Parameters:
  /// - [userName]: The user's name.
  /// - [urgentCount]: Number of friends at urgent priority tier today.
  /// - [concernCount]: Number of friends with an active concern flag.
  ///
  /// Generates a single warm coach-tone line (≤15 words) in French.
  /// Implemented in Story 10.3.
  static String greetingLine({
    required String userName,
    required int urgentCount,
    required int concernCount,
  }) {
    final contextHint = concernCount > 0
        ? "Certains de ses proches méritent une attention particulière aujourd'hui."
        : urgentCount == 0
            ? "Tout est calme dans ses relations aujourd'hui."
            : urgentCount == 1
                ? "Un de ses proches a besoin d'un signe aujourd'hui."
                : "Plusieurs de ses proches méritent un geste aujourd'hui.";

    return '''Tu es un coach relationnel bienveillant. Génère UNE SEULE ligne de salutation chaleureuse pour accueillir $userName.
$contextHint
Règles strictes :
- Maximum 15 mots au total
- Ton encourageant, jamais culpabilisant
- Langue : français uniquement
- Aucun chiffre ni métrique
- Aucun guillemet autour de ta réponse
- Une seule phrase courte, directe''';
  }
}
