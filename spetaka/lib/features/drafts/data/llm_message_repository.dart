// LlmMessageRepository — Story 10.2 (AC2)
//
// Builds LLM prompts via PromptTemplates, calls LlmInferenceService,
// and parses the numbered-list response into a DraftMessage.
// No network calls — inference is on-device (NFR18, NFR19).

import 'dart:developer' as dev;

import '../../../core/ai/llm_inference_service.dart';
import '../../../core/ai/prompt_templates.dart';
import '../../../core/database/app_database.dart';
import '../../../features/friends/data/friend_repository.dart';
import '../domain/draft_message.dart';

/// Generates on-device LLM message suggestions for a given friend + event.
///
/// This class is the ONLY place where prompt construction and response
/// parsing take place for draft messages (architecture rule).
class LlmMessageRepository {
  LlmMessageRepository({
    required FriendRepository friendRepository,
    required LlmInferenceService llmInferenceService,
  })  : _friendRepository = friendRepository,
        _llmInferenceService = llmInferenceService;

  final FriendRepository _friendRepository;
  final LlmInferenceService _llmInferenceService;

  /// Generates ≥ 1 message suggestions for [friendId] based on [event].
  ///
  /// Returns a [DraftMessage] whose [DraftMessage.variants] list may be empty
  /// if inference times out or returns unrecognisable output (AC6 — caller
  /// shows error state).
  ///
  /// Never throws; errors are surfaced via the empty-variants convention.
  Future<DraftMessage> generateSuggestions({
    required String friendId,
    required Event event,
    required String channel,
  }) async {
    // AC2: read friend name via existing findById — do NOT add a new query.
    final friend = await _friendRepository.findById(friendId);
    final friendName = friend?.name ?? '';

    // AC2: build prompt via PromptTemplates — never inline prompt construction.
    final prompt = PromptTemplates.messageSuggestion(
      friendName: friendName,
      eventType: event.type,
      eventNote: event.comment,
      language: 'fr',
    );

    dev.log(
      'LlmMessageRepository: requesting suggestions for friend=$friendId, event=${event.type}',
      name: 'drafts.repository',
    );

    // AC2: call inference service (already serialized + timeout inside service).
    final raw = await _llmInferenceService.infer(prompt);

    final variants = _parseVariants(raw);

    dev.log(
      'LlmMessageRepository: parsed ${variants.length} variants',
      name: 'drafts.repository',
    );

    return DraftMessage(
      friendId: friendId,
      friendName: friendName,
      eventContext: event.type,
      channel: channel,
      variants: variants,
    );
  }

  /// Parses a numbered list from raw LLM output.
  ///
  /// Handles both `1.` and `1)` bullet styles. Returns an empty list if the
  /// model response does not follow the numbered format (AC6 — error state).
  static List<String> parseVariants(List<String> raw) => _parseVariants(raw);

  static List<String> _parseVariants(List<String> raw) {
    final joined = raw.join('\n');
    // Matches "1. text" or "1) text" — captures only the text portion.
    // [^\S\n]* = horizontal whitespace only (avoids crossing line boundaries).
    // ([^\n]+) = capture up to (but not including) the next newline.
    final numberedLine = RegExp(r'^\d+[\.\)][^\S\n]*([^\n]+)', multiLine: true);
    final matches = numberedLine.allMatches(joined);
    return matches
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
