import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's HuggingFace access token in the device's secure keystore.
///
/// Android: Android Keystore (API 23+ — our minSdk = 26, so always available).
/// iOS: Keychain.
///
/// The token is NEVER embedded in the binary. Each user provides their own.
class HfTokenService {
  const HfTokenService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'spetaka_hf_token';

  final FlutterSecureStorage _storage;

  Future<String?> getToken() => _storage.read(key: _key);

  Future<void> saveToken(String token) {
    if (token.isEmpty) throw ArgumentError.value(token, 'token', 'must not be empty');
    return _storage.write(key: _key, value: token);
  }

  Future<void> clearToken() => _storage.delete(key: _key);
}
