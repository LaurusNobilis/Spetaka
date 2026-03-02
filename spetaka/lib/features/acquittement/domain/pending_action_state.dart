/// Where the contact action was triggered from.
///
/// Used by the resume handler to decide which screen should respond:
/// - [dailyView]: the user tapped call/sms/whatsapp from the daily view card.
/// - [friendCard]: the user tapped from the full friend-card detail screen.
/// - [unknown]: legacy or manually-initiated acquittement (fallback button).
enum AcquittementOrigin { dailyView, friendCard, unknown }

/// Snapshot of a pending contact action that has not yet been acknowledged.
///
/// Created by [ContactActionService] immediately before leaving the app.
/// Stored in [AppLifecycleService] and consumed when the app resumes:
/// - If not expired → triggers the acquittement sheet.
/// - If expired (>30 min) → silently discarded; manual fallback remains.
///
/// **Immutable value object** — copy semantics via constructor.
class PendingActionState {
  const PendingActionState({
    required this.friendId,
    required this.origin,
    required this.actionType,
    required this.timestamp,
  });

  /// Id of the friend the action was performed for.
  final String friendId;

  /// Where the action was launched from (for routing on return).
  final AcquittementOrigin origin;

  /// Action that was performed: 'call', 'sms', 'whatsapp'.
  /// Pre-fills the type selector in [AcquittementSheet].
  final String actionType;

  /// Wall-clock time when the action was launched.
  final DateTime timestamp;

  static const _expiryDuration = Duration(minutes: 30);

  /// Returns true if more than 30 minutes have elapsed since [timestamp].
  bool get isExpired =>
      DateTime.now().difference(timestamp) >= _expiryDuration;

  @override
  String toString() =>
      'PendingActionState(friendId: $friendId, origin: $origin, '
      'actionType: $actionType, timestamp: $timestamp)';
}
