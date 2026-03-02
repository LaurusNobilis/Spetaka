import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_error.dart';
import '../lifecycle/app_lifecycle_service.dart';
import 'encryption_state_notifier.dart';

class EncryptionService {
  static const String saltPrefsKey = 'spetaka_pbkdf2_salt';
  static const String _verifierPrefsKey = 'spetaka_unlock_verifier';
  static const String _verifierPlaintext = 'spetaka_unlock_ok';

  static const int _pbkdf2Iterations = 100000;
  static const int _saltLengthBytes = 16;
  static const int _keyLengthBytes = 32;
  static const int _ivLengthBytes = 12;
  static const int _tagLengthBytes = 16;

  static final Random _secureRandom = Random.secure();

  final AppLifecycleService _lifecycleService;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;

  Uint8List? _keyBytes;

  /// `true` when a derived key is held in memory and encrypt/decrypt can proceed.
  bool get isInitialized => _keyBytes != null;

  EncryptionService({required AppLifecycleService lifecycleService})
      : _lifecycleService = lifecycleService {
    _lifecycleSub = _lifecycleService.lifecycleStates.listen(_onLifecycleState);
  }

  // ---------------------------------------------------------------------------
  // Passphrase verifier helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when a passphrase has already been set up on this
  /// installation (i.e. an encrypted verifier blob exists in prefs).
  Future<bool> hasPassphraseSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_verifierPrefsKey);
  }

  /// Encrypts [_verifierPlaintext] with the current in-memory key and persists
  /// it so future launches can verify the passphrase.
  ///
  /// Must only be called *after* [initialize].
  Future<void> setupVerifier() async {
    if (_keyBytes == null) throw const EncryptionNotInitializedAppError();
    final verifier = encrypt(_verifierPlaintext);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verifierPrefsKey, verifier);
  }

  /// Calls [initialize] then verifies the stored verifier blob.
  ///
  /// Throws [DecryptionFailedAppError] if the passphrase is wrong.
  /// Returns normally on success.
  Future<void> verifyAndInitialize(String passphrase) async {
    await initialize(passphrase);
    final prefs = await SharedPreferences.getInstance();
    final verifier = prefs.getString(_verifierPrefsKey);
    if (verifier == null) {
      // No verifier yet — should not happen after setup, ignore.
      return;
    }
    try {
      final result = decrypt(verifier);
      if (result != _verifierPlaintext) {
        clearKey();
        throw const DecryptionFailedAppError();
      }
    } catch (_) {
      clearKey();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------

  Future<void> initialize(String passphrase) async {
    final passwordBytes = Uint8List.fromList(utf8.encode(passphrase));
    Uint8List? derivedKey;
    try {
      final salt = await _loadOrCreateSalt();
      derivedKey = _pbkdf2HmacSha256(
        password: passwordBytes,
        salt: salt,
        iterations: _pbkdf2Iterations,
        derivedKeyLengthBytes: _keyLengthBytes,
      );

      _setKeyBytes(derivedKey);
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'spetaka/encryption',
          context: ErrorDescription('while initializing EncryptionService'),
        ),
      );
      throw EncryptionInitializationFailedAppError(e);
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
      derivedKey?.fillRange(0, derivedKey.length, 0);
    }
  }

  String encrypt(String plaintext) {
    final keyBytes = _keyBytes;
    if (keyBytes == null) {
      throw const EncryptionNotInitializedAppError();
    }

    final iv = _randomBytes(_ivLengthBytes);

    final aes = encrypt_pkg.AES(
      encrypt_pkg.Key(keyBytes),
      mode: encrypt_pkg.AESMode.gcm,
    );
    final encrypter = encrypt_pkg.Encrypter(aes);

    final encryptedBytes = encrypter
        .encryptBytes(
          Uint8List.fromList(utf8.encode(plaintext)),
          iv: encrypt_pkg.IV(iv),
        )
        .bytes;

    if (encryptedBytes.length < _tagLengthBytes) {
      throw const CiphertextFormatAppError();
    }

    // `encrypt` (PointyCastle GCM) returns ciphertext||tag.
    final cipherText = encryptedBytes.sublist(0, encryptedBytes.length - _tagLengthBytes);
    final tag = encryptedBytes.sublist(encryptedBytes.length - _tagLengthBytes);

    final payload = Uint8List(iv.length + tag.length + cipherText.length)
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, iv.length + tag.length, tag)
      ..setRange(iv.length + tag.length, iv.length + tag.length + cipherText.length, cipherText);

    return base64UrlEncode(payload);
  }

  String decrypt(String ciphertext) {
    final keyBytes = _keyBytes;
    if (keyBytes == null) {
      throw const EncryptionNotInitializedAppError();
    }

    Uint8List decoded;
    try {
      decoded = Uint8List.fromList(base64Url.decode(ciphertext));
    } on FormatException {
      throw const CiphertextFormatAppError();
    }

    if (decoded.length < _ivLengthBytes + _tagLengthBytes + 1) {
      throw const CiphertextFormatAppError();
    }

    final iv = decoded.sublist(0, _ivLengthBytes);
    final tag = decoded.sublist(_ivLengthBytes, _ivLengthBytes + _tagLengthBytes);
    final cipherText = decoded.sublist(_ivLengthBytes + _tagLengthBytes);

    final cipherPlusTag = Uint8List(cipherText.length + tag.length)
      ..setRange(0, cipherText.length, cipherText)
      ..setRange(cipherText.length, cipherText.length + tag.length, tag);

    final aes = encrypt_pkg.AES(
      encrypt_pkg.Key(keyBytes),
      mode: encrypt_pkg.AESMode.gcm,
    );
    final encrypter = encrypt_pkg.Encrypter(aes);

    try {
      final decryptedBytes = encrypter.decryptBytes(
        encrypt_pkg.Encrypted(cipherPlusTag),
        iv: encrypt_pkg.IV(iv),
      );
      return utf8.decode(decryptedBytes);
    } catch (_) {
      // Covers auth tag failure and other crypto errors.
      throw const DecryptionFailedAppError();
    }
  }

  void clearKey() {
    final keyBytes = _keyBytes;
    if (keyBytes != null) {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }
    _keyBytes = null;
    encryptionStateNotifier.setInitialized(false);
  }

  void dispose() {
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
    clearKey();
  }

  // ---------------------------------------------------------------------------
  // Public static helpers — used by BackupRepository for portable backup crypto
  // ---------------------------------------------------------------------------

  /// Returns [length] cryptographically random bytes.
  ///
  /// Exposed so [BackupRepository] can generate a per-backup PBKDF2 salt without
  /// duplicating the random-byte generation logic.
  static Uint8List generateRandomBytes(int length) => _randomBytes(length);

  /// Derives a 256-bit AES key from [password] + [salt] using PBKDF2-HMAC-SHA256
  /// (100k iterations), identical to the algorithm used in [initialize].
  ///
  /// Callers MUST zero-out [password] and the returned key after use.
  static Uint8List deriveKeyForBackup(Uint8List password, Uint8List salt) =>
      _pbkdf2HmacSha256(
        password: password,
        salt: salt,
        iterations: _pbkdf2Iterations,
        derivedKeyLengthBytes: _keyLengthBytes,
      );

  /// Encrypts [plaintext] using AES-256-GCM with explicit [keyBytes].
  ///
  /// Returns a base64url string in the same format as [encrypt]:
  ///   IV (12 bytes) || GCM auth-tag (16 bytes) || ciphertext
  ///
  /// Callers are responsible for zeroing [keyBytes] after use.
  static String encryptWithKeyBytes(Uint8List keyBytes, String plaintext) {
    final iv = _randomBytes(_ivLengthBytes);
    final aes = encrypt_pkg.AES(
      encrypt_pkg.Key(keyBytes),
      mode: encrypt_pkg.AESMode.gcm,
    );
    final encrypter = encrypt_pkg.Encrypter(aes);
    final encryptedBytes = encrypter
        .encryptBytes(
          Uint8List.fromList(utf8.encode(plaintext)),
          iv: encrypt_pkg.IV(iv),
        )
        .bytes;
    if (encryptedBytes.length < _tagLengthBytes) {
      throw const CiphertextFormatAppError();
    }
    final cipherText =
        encryptedBytes.sublist(0, encryptedBytes.length - _tagLengthBytes);
    final tag = encryptedBytes.sublist(encryptedBytes.length - _tagLengthBytes);
    final payload = Uint8List(iv.length + tag.length + cipherText.length)
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, iv.length + tag.length, tag)
      ..setRange(
        iv.length + tag.length,
        iv.length + tag.length + cipherText.length,
        cipherText,
      );
    return base64UrlEncode(payload);
  }

  /// Decrypts [ciphertext] (base64url, same format as [encrypt]) using [keyBytes].
  ///
  /// Throws [CiphertextFormatAppError] if the format is invalid.
  /// Throws [DecryptionFailedAppError] if the GCM auth tag does not match
  /// (wrong key / tampered ciphertext).
  ///
  /// Callers are responsible for zeroing [keyBytes] after use.
  static String decryptWithKeyBytes(Uint8List keyBytes, String ciphertext) {
    Uint8List decoded;
    try {
      decoded = Uint8List.fromList(base64Url.decode(ciphertext));
    } on FormatException {
      throw const CiphertextFormatAppError();
    }
    if (decoded.length < _ivLengthBytes + _tagLengthBytes + 1) {
      throw const CiphertextFormatAppError();
    }
    final iv = decoded.sublist(0, _ivLengthBytes);
    final tag =
        decoded.sublist(_ivLengthBytes, _ivLengthBytes + _tagLengthBytes);
    final cipherText = decoded.sublist(_ivLengthBytes + _tagLengthBytes);
    final cipherPlusTag = Uint8List(cipherText.length + tag.length)
      ..setRange(0, cipherText.length, cipherText)
      ..setRange(cipherText.length, cipherText.length + tag.length, tag);
    final aes = encrypt_pkg.AES(
      encrypt_pkg.Key(keyBytes),
      mode: encrypt_pkg.AESMode.gcm,
    );
    final encrypter = encrypt_pkg.Encrypter(aes);
    try {
      final decryptedBytes = encrypter.decryptBytes(
        encrypt_pkg.Encrypted(cipherPlusTag),
        iv: encrypt_pkg.IV(iv),
      );
      return utf8.decode(decryptedBytes);
    } catch (_) {
      throw const DecryptionFailedAppError();
    }
  }

  void _onLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      clearKey();
    }
  }

  Future<Uint8List> _loadOrCreateSalt() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(saltPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      try {
        final decoded = Uint8List.fromList(base64Url.decode(existing));
        if (decoded.length == _saltLengthBytes) {
          return decoded;
        }
        // If the stored value is corrupted, replace it.
      } on FormatException {
        // If the stored value is corrupted, replace it.
      }
    }

    final salt = _randomBytes(_saltLengthBytes);
    await prefs.setString(saltPrefsKey, base64UrlEncode(salt));
    return salt;
  }

  void _setKeyBytes(Uint8List newKey) {
    // Zero out and replace without calling clearKey() to avoid double-notify.
    final old = _keyBytes;
    if (old != null) old.fillRange(0, old.length, 0);
    _keyBytes = Uint8List.fromList(newKey);
    encryptionStateNotifier.setInitialized(true);
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  // RFC 2898 PBKDF2 (HMAC-SHA256)
  static Uint8List _pbkdf2HmacSha256({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int derivedKeyLengthBytes,
  }) {
    if (iterations <= 0) {
      throw ArgumentError.value(iterations, 'iterations', 'must be > 0');
    }
    if (derivedKeyLengthBytes <= 0) {
      throw ArgumentError.value(derivedKeyLengthBytes, 'derivedKeyLengthBytes', 'must be > 0');
    }

    final hLen = crypto.sha256.convert(const <int>[]).bytes.length; // 32
    final blocksNeeded = (derivedKeyLengthBytes / hLen).ceil();

    final output = BytesBuilder(copy: false);

    for (var blockIndex = 1; blockIndex <= blocksNeeded; blockIndex++) {
      final block = _pbkdf2Block(
        password: password,
        salt: salt,
        iterations: iterations,
        blockIndex: blockIndex,
      );
      output.add(block);
    }

    final full = output.toBytes();
    return Uint8List.fromList(full.sublist(0, derivedKeyLengthBytes));
  }

  static Uint8List _pbkdf2Block({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int blockIndex,
  }) {
    final hmac = crypto.Hmac(crypto.sha256, password);

    final initial = BytesBuilder(copy: false)
      ..add(salt)
      ..add(_int32be(blockIndex));

    var u = Uint8List.fromList(hmac.convert(initial.toBytes()).bytes);
    final t = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    return t;
  }

  static Uint8List _int32be(int value) {
    return Uint8List.fromList([
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ]);
  }
}
