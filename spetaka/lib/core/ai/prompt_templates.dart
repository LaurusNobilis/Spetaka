// PromptTemplates — Story 10.1 (AC2)
//
// Central registry for ALL LLM prompt templates.
// No runtime prompt construction outside this file (architecture rule).
// Content will be filled in Stories 10.2 and 10.3.

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
  ///
  /// Content will be implemented in Story 10.2.
  static String messageSuggestion({
    required String friendName,
    required String eventType,
    String? eventNote,
    String language = 'fr',
  }) {
    final context = eventNote != null && eventNote.isNotEmpty
        ? '$eventType — $eventNote'
        : eventType;
    return '''Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.
Génère 3 courts messages $language chaleureux pour $friendName à l'occasion de : $context.
Les messages doivent être chaleureux, personnels, naturels, et adaptés à un envoi par $language.
Formate ta réponse comme une liste numérotée :
1. [premier message]
2. [deuxième message]
3. [troisième message]
Ne génère rien d'autre.''';
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
