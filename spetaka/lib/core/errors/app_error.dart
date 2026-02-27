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
