import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../errors/app_error.dart';
import '../lifecycle/app_lifecycle_service.dart';
import '../../features/acquittement/domain/pending_action_state.dart';
import 'phone_normalizer.dart';

part 'contact_action_service.g.dart';

/// Single gateway for external contact actions (call, SMS, WhatsApp).
///
/// Widgets and features MUST NOT call `url_launcher` directly — all launches
/// are routed through this service so that:
/// - Phone numbers are always normalized to E.164 via [PhoneNormalizer].
/// - The pending acquittement state is recorded before leaving the app.
/// - Launch failures are converted to typed [ContactActionFailedAppError].
///
/// ### Signature design note
/// [friendId] and [origin] are accepted alongside [rawNumber] on every method
/// so that Story 5.2 (acquittement trigger) routes the return flow correctly.
class ContactActionService {
  ContactActionService({
    required PhoneNormalizer normalizer,
    required AppLifecycleService lifecycleService,
  })  : _normalizer = normalizer,
        _lifecycleService = lifecycleService;

  final PhoneNormalizer _normalizer;
  final AppLifecycleService _lifecycleService;

  Future<void> _launchExternal(
    Uri uri, {
    required String action,
    required String? friendId,
    required AcquittementOrigin origin,
  }) async {
    if (friendId != null) {
      // Legacy compat stream
      _lifecycleService.setPendingFriendId(friendId);
      // Story 5-2: rich pending state with expiry + origin
      _lifecycleService.setActionState(
        PendingActionState(
          friendId: friendId,
          origin: origin,
          actionType: action,
          timestamp: DateTime.now(),
        ),
      );
    }

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      if (friendId != null) {
        _lifecycleService.setPendingFriendId(null);
        _lifecycleService.setActionState(null);
      }
      throw ContactActionFailedAppError(action);
    }
  }

  /// Launches a phone call to [rawNumber].
  ///
  /// Records [friendId] and [origin] as the pending acquittement candidate so
  /// the acquittement sheet can appear when the user returns.
  Future<void> call(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    final e164 = _normalizer.normalize(rawNumber);
    final uri = Uri.parse('tel:$e164');
    await _launchExternal(uri, action: 'call', friendId: friendId, origin: origin);
  }

  /// Launches the default SMS app pre-filled with [rawNumber].
  Future<void> sms(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    final e164 = _normalizer.normalize(rawNumber);
    final uri = Uri.parse('sms:$e164');
    await _launchExternal(uri, action: 'sms', friendId: friendId, origin: origin);
  }

  /// Opens WhatsApp with a new conversation to [rawNumber].
  ///
  /// WhatsApp deep-links require digits only (no leading `+`).
  Future<void> whatsapp(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    final e164 = _normalizer.normalize(rawNumber);
    final digitsOnly = e164.substring(1); // strip leading '+'
    final uri = Uri.parse('https://wa.me/$digitsOnly');
    await _launchExternal(uri, action: 'whatsapp', friendId: friendId, origin: origin);
  }
}

@riverpod
ContactActionService contactActionService(Ref ref) {
  return ContactActionService(
    normalizer: const PhoneNormalizer(),
    lifecycleService: ref.watch(appLifecycleServiceProvider),
  );
}
