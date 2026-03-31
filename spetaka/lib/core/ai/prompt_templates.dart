// PromptTemplates — Story 10.1 (AC2)
//
// Central registry for ALL LLM prompt templates.
// No runtime prompt construction outside this file (architecture rule).

import '../../core/database/app_database.dart';
import '../../features/voice_profile/data/user_voice_profile_repository.dart';

/// Static constants for all LLM prompt templates.
///
/// Every prompt string used by the app lives here.
/// Prompt construction must ONLY happen in this file.
abstract final class PromptTemplates {
  static const _stopWords = {
    'cette', 'avec', 'pour', 'dans', 'bien', 'mais', 'aussi', 'comme',
    'plus', 'tout', 'très', 'votre', 'notre', 'leur', 'vous', 'nous',
    'même', 'être', 'avoir', 'faire',
  };

  /// Message suggestion prompt template.
  ///
  /// Parameters:
  /// - [friendName]: Name of the friend.
  /// - [eventType]: Type of event (e.g., birthday, check-in).
  /// - [eventNote]: Optional note/context about the event.
  /// - [language]: Target language for the suggestion.
  /// - [voiceProfile]: Optional on-device learned style profile (Story 10.6).
  /// - [concernNote]: Optional concern note from the friend's active concern.
  static String messageSuggestion({
    required String friendName,
    required String eventType,
    String? eventNote,
    String language = 'fr',
    UserVoiceProfile? voiceProfile,
    String? concernNote,
  }) {
    // Couche 1 — Base context: event type and comment combined
    final eventContext = eventNote != null && eventNote.isNotEmpty
        ? '$eventType — $eventNote'
        : eventType;

    // Couche 2 — Always-on: bienveillant + compatissant, tone adapted to
    // event type and comment (when present).
    // Format when note present: "Contexte important : {note}. Adapte le ton..." (Story 10.5 AC1)
    final toneInstruction = eventNote != null && eventNote.isNotEmpty
        ? '\nContexte important : $eventNote. Adapte le ton au type d\'événement "$eventType".\nReste toujours bienveillant et compatissant.'
        : '\nReste toujours bienveillant et compatissant. Adapte le ton au type d\'événement "$eventType".';

    // Couche 3 — Length instruction based on keyword count in event note
    final lengthInstruction = _buildLengthInstruction(eventNote);

    // Couche 4 — Style instruction from UserVoiceProfile (≥3 observations)
    final styleInstruction = _buildStyleInstruction(voiceProfile);

    // Concern context — inject the friend's concern note when present
    final concernInstruction = concernNote != null && concernNote.trim().isNotEmpty
        ? '\nPréoccupation active pour $friendName : $concernNote. Prends cela en compte avec délicatesse dans tes suggestions.'
        : '';

    return '''Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.$toneInstruction$lengthInstruction$styleInstruction$concernInstruction
Génère 3 courts messages pour $friendName à l'occasion de : $eventContext.
Les messages doivent être chaleureux, personnels et naturels.
Formate ta réponse comme une liste numérotée :
1. [premier message]
2. [deuxième message]
3. [troisième message]
Ne génère rien d'autre.''';
  }

  // ---------------------------------------------------------------------------
  // Private helpers — Couche 3
  // ---------------------------------------------------------------------------

  /// Counts meaningful keywords (words ≥ 4 chars, not stop words) in [eventNote].
  static int _countKeywordsInNote(String? eventNote) {
    if (eventNote == null || eventNote.trim().isEmpty) return 0;
    return eventNote
        .toLowerCase()
        .split(RegExp(r"[^a-zA-ZÀ-ÿ']+"))
        .where((w) => w.length >= 4 && !_stopWords.contains(w))
        .length;
  }

  /// Returns a length constraint instruction based on keyword count of [eventNote].
  static String _buildLengthInstruction(String? eventNote) {
    final count = _countKeywordsInNote(eventNote);
    if (count <= 1) return '\nÉcris un message court, maximum 15 mots.';
    if (count <= 4) return '\nÉcris un message de longueur modérée, maximum 40 mots.';
    return '\nÉcris un message riche et personnalisé, plus de 40 mots.';
  }

  // ---------------------------------------------------------------------------
  // Private helpers — Couche 4
  // ---------------------------------------------------------------------------

  /// Returns a style constraint instruction from the [voiceProfile], or an
  /// empty string if the profile is null or below the minimum observation
  /// threshold.
  static String _buildStyleInstruction(UserVoiceProfile? profile) {
    if (profile == null || profile.observationCount < 3) return '';
    final topKeywords = UserVoiceProfileRepository.topKeywordsFromJson(
      profile.frequentKeywords,
    );
    final topEmojis = UserVoiceProfileRepository.topItemsFromJson(
      profile.frequentEmoji,
      limit: 3,
    );
    final topExpressions = UserVoiceProfileRepository.topItemsFromJson(
      profile.frequentExpression,
      limit: 2,
    );
    final parts = <String>[];
    if (topKeywords.isNotEmpty) {
      parts.add('mots-clés récurrents : ${topKeywords.join(', ')}');
    }
    if (topEmojis.isNotEmpty) {
      parts.add('emojis fréquents : ${topEmojis.join(' ')}');
    }
    if (topExpressions.isNotEmpty) {
      parts.add('expressions fréquentes : ${topExpressions.join(', ')}');
    }
    if (parts.isEmpty) return '';
    return '\nStyle de l\'utilisateur : ${parts.join(' ; ')}.';
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
