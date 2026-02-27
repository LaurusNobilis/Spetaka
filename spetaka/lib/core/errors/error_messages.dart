import 'app_error.dart';

String errorMessageFor(AppError error) {
  return switch (error) {
    DecryptionFailedAppError() => 'Decryption failed. Please re-enter your passphrase.',
    EncryptionNotInitializedAppError() => 'Encryption is not initialized. Please enter your passphrase.',
    CiphertextFormatAppError() => 'Encrypted data is corrupted or has an unknown format.',
    EncryptionInitializationFailedAppError() => 'Encryption initialization failed. Please try again.',
  };
}
