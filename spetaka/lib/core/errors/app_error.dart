sealed class AppError implements Exception {
  const AppError();

  String get code;
}

class DecryptionFailedAppError extends AppError {
  const DecryptionFailedAppError();

  @override
  String get code => 'decryption_failed';
}

class EncryptionNotInitializedAppError extends AppError {
  const EncryptionNotInitializedAppError();

  @override
  String get code => 'encryption_not_initialized';
}

class CiphertextFormatAppError extends AppError {
  const CiphertextFormatAppError();

  @override
  String get code => 'ciphertext_format_invalid';
}

class EncryptionInitializationFailedAppError extends AppError {
  const EncryptionInitializationFailedAppError([this.cause]);

  final Object? cause;

  @override
  String get code => 'encryption_initialization_failed';
}

/// Thrown when a raw phone number cannot be parsed or normalized to E.164.
class PhoneNormalizationAppError extends AppError {
  const PhoneNormalizationAppError(this.reason);

  /// Short description of why normalization failed.
  final String reason;

  @override
  String get code => 'phone_normalization_failed';
}

/// Thrown when a contact action (call/sms/whatsapp) cannot be launched.
class ContactActionFailedAppError extends AppError {
  const ContactActionFailedAppError(this.action);

  /// The action that failed: 'call', 'sms', or 'whatsapp'.
  final String action;

  @override
  String get code => 'contact_action_failed';
}

/// Thrown when the user denies contact permission during import.
class ContactPermissionDeniedAppError extends AppError {
  const ContactPermissionDeniedAppError();

  @override
  String get code => 'contact_permission_denied';
}

/// Thrown when contact details cannot be loaded after the picker returns.
class ContactDetailsLoadFailedAppError extends AppError {
  const ContactDetailsLoadFailedAppError();

  @override
  String get code => 'contact_details_load_failed';
}

/// Thrown when an imported contact has no usable phone number.
class ContactHasNoPhoneAppError extends AppError {
  const ContactHasNoPhoneAppError();

  @override
  String get code => 'contact_has_no_phone';
}

/// Thrown when friend creation is attempted without a name.
class FriendNameMissingAppError extends AppError {
  const FriendNameMissingAppError();

  @override
  String get code => 'friend_name_missing';
}

/// Thrown when friend creation is attempted without a mobile number.
class FriendMobileMissingAppError extends AppError {
  const FriendMobileMissingAppError();

  @override
  String get code => 'friend_mobile_missing';
}
