// DraftMessage — Story 10.2 (AC7)
//
// Pure in-memory data class — NEVER persisted to SQLite.
// No Drift annotations, no toJson/fromMap helpers.

/// In-memory representation of a draft message suggestion session.
///
/// Created by [LlmMessageRepository.generateSuggestions] and held by
/// [DraftMessageNotifier] for the duration of the bottom sheet. Discarded
/// via [DraftMessageNotifier.clear] — never written to the database.
class DraftMessage {
  const DraftMessage({
    required this.friendId,
    required this.friendName,
    required this.eventContext,
    required this.channel,
    required this.variants,
    this.editedText,
    this.selectedIndex,
    this.isStreaming = false,
  });

  /// ID of the friend for whom the message is being drafted.
  final String friendId;

  /// Decrypted display name of the friend.
  final String friendName;

  /// Human-readable event context string shown in the sheet header,
  /// e.g. "Anniversaire dans 3 jours".
  final String eventContext;

  /// Messaging channel: `'whatsapp'` or `'sms'`.
  final String channel;

  /// ≥ 1 LLM-generated message phrasings (empty list → error state, AC6).
  final List<String> variants;

  /// User's edited version of the selected variant. `null` means the
  /// unmodified [selectedIndex] variant is used.
  final String? editedText;

  /// Index of the highlighted variant card (defaults to 0 in the UI).
  final int? selectedIndex;

  /// True while the LLM is still generating tokens (streaming in progress).
  /// The sheet keeps the progress indicator visible and merges new variants
  /// without overwriting any user selection or edit.
  final bool isStreaming;

  DraftMessage copyWith({
    String? friendId,
    String? friendName,
    String? eventContext,
    String? channel,
    List<String>? variants,
    Object? editedText = _keep,
    Object? selectedIndex = _keep,
    bool? isStreaming,
  }) {
    return DraftMessage(
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      eventContext: eventContext ?? this.eventContext,
      channel: channel ?? this.channel,
      variants: variants ?? this.variants,
      editedText: editedText == _keep ? this.editedText : editedText as String?,
      selectedIndex:
          selectedIndex == _keep ? this.selectedIndex : selectedIndex as int?,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  // Sentinel for "keep existing value" in copyWith so callers can pass null
  // to explicitly clear optional fields.
  static const Object _keep = Object();
}
