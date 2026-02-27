import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/errors/app_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('encrypt then decrypt returns original plaintext', () async {
    final service = EncryptionService();
    await service.initialize('correct horse battery staple');

    final ciphertext = service.encrypt('hello');
    final plaintext = service.decrypt(ciphertext);

    expect(plaintext, 'hello');
  });

  test('two encryptions of same plaintext produce different ciphertext', () async {
    final service = EncryptionService();
    await service.initialize('correct horse battery staple');

    final c1 = service.encrypt('x');
    final c2 = service.encrypt('x');

    expect(c1, isNot(equals(c2)));
  });

  test('decrypt with wrong passphrase throws typed AppError', () async {
    final service1 = EncryptionService();
    await service1.initialize('passphrase-A');

    final ciphertext = service1.encrypt('secret');

    final service2 = EncryptionService();
    await service2.initialize('passphrase-B');

    expect(
      () => service2.decrypt(ciphertext),
      throwsA(isA<DecryptionFailedAppError>()),
    );
  });

  test('encrypt without initialize throws typed AppError', () {
    final service = EncryptionService();

    expect(
      () => service.encrypt('hello'),
      throwsA(isA<EncryptionNotInitializedAppError>()),
    );
  });

  test('decrypt invalid ciphertext format throws typed AppError', () async {
    final service = EncryptionService();
    await service.initialize('correct horse battery staple');

    expect(
      () => service.decrypt('not-base64url'),
      throwsA(isA<CiphertextFormatAppError>()),
    );
  });
}
