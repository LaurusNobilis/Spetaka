import 'app_error.dart';

String errorMessageFor(AppError error) {
  return switch (error) {
    DecryptionFailedAppError() => 'Decryption failed. Please re-enter your passphrase.',
    EncryptionNotInitializedAppError() => 'Encryption is not initialized. Please enter your passphrase.',
    CiphertextFormatAppError() => 'Encrypted data is corrupted or has an unknown format.',
    EncryptionInitializationFailedAppError() => 'Encryption initialization failed. Please try again.',
    PhoneNormalizationAppError() => 'Invalid phone number. Please check and try again.',
    ContactActionFailedAppError(action: final a) =>
        'Could not launch $a. Please verify the app is available on this device.',
  ContactPermissionDeniedAppError() =>
    'Contact permission denied. Please enter the details manually.',
  ContactDetailsLoadFailedAppError() =>
    'Could not load contact details. Please try again or enter them manually.',
  ContactHasNoPhoneAppError() =>
    'This contact has no phone number. Please enter it manually.',
  FriendNameMissingAppError() => 'Please enter a name.',
  FriendMobileMissingAppError() => 'Please enter a mobile number.',
  };
}
