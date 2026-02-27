import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../errors/app_error.dart';
import '../lifecycle/app_lifecycle_service.dart';
import 'phone_normalizer.dart';

part 'contact_action_service.g.dart';

/// Single gateway for external contact actions (call, SMS, WhatsApp).
///
/// Widgets and features MUST NOT call `url_launcher` directly — all launches
/// are routed through this service so that:
/// - Phone numbers are always normalized to E.164 via [PhoneNormalizer].
/// - The pending acquittement friend ID is recorded before leaving the app.
/// - Launch failures are converted to typed [ContactActionFailedAppError].
///
/// ### Signature design note
/// [friendId] is accepted alongside [rawNumber] on every method from day 1
/// so that Story 5.2 (acquittement trigger) can wire the return flow without
/// a service-layer refactor.
class ContactActionService {
  ContactActionService({
    required PhoneNormalizer normalizer,
    required AppLifecycleService lifecycleService,
  })  : _normalizer = normalizer,
        _lifecycleService = lifecycleService;

  final PhoneNormalizer _normalizer;
  final AppLifecycleService _lifecycleService;

  /// Launches a phone call to [rawNumber].
  ///
  /// Records [friendId] as the pending acquittement candidate so the
  /// acquittement sheet can appear when the user returns.
  Future<void> call(String rawNumber, {String? friendId}) async {
    final e164 = _normalizer.normalize(rawNumber);
    if (friendId != null) {
      _lifecycleService.setPendingFriendId(friendId);
    }
    final uri = Uri.parse('tel:$e164');
    if (!await launchUrl(uri)) {
      // Rollback pending state — launch failed so the user never left the app.
      if (friendId != null) {
        _lifecycleService.setPendingFriendId(null);
      }
      throw const ContactActionFailedAppError('call');
    }
  }

  /// Launches the default SMS app pre-filled with [rawNumber].
  Future<void> sms(String rawNumber, {String? friendId}) async {
    final e164 = _normalizer.normalize(rawNumber);
    if (friendId != null) {
      _lifecycleService.setPendingFriendId(friendId);
    }
    final uri = Uri.parse('sms:$e164');
    if (!await launchUrl(uri)) {
      if (friendId != null) {
        _lifecycleService.setPendingFriendId(null);
      }
      throw const ContactActionFailedAppError('sms');
    }
  }

  /// Opens WhatsApp with a new conversation to [rawNumber].
  ///
  /// WhatsApp deep-links require digits only (no leading `+`).
  Future<void> whatsapp(String rawNumber, {String? friendId}) async {
    final e164 = _normalizer.normalize(rawNumber);
    final digitsOnly = e164.substring(1); // strip leading '+'
    if (friendId != null) {
      _lifecycleService.setPendingFriendId(friendId);
    }
    final uri = Uri.parse('https://wa.me/$digitsOnly');
    if (!await launchUrl(uri)) {
      if (friendId != null) {
        _lifecycleService.setPendingFriendId(null);
      }
      throw const ContactActionFailedAppError('whatsapp');
    }
  }
}

@riverpod
ContactActionService contactActionService(Ref ref) {
  return ContactActionService(
    normalizer: const PhoneNormalizer(),
    lifecycleService: ref.watch(appLifecycleServiceProvider),
  );
}
