import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('encrypt then decrypt returns original plaintext', () async {
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    addTearDown(() {
      service.dispose();
      lifecycle.dispose();
    });
    await service.initialize('correct horse battery staple');

    final ciphertext = service.encrypt('hello');
    final plaintext = service.decrypt(ciphertext);

    expect(plaintext, 'hello');
  });

  test('two encryptions of same plaintext produce different ciphertext', () async {
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    addTearDown(() {
      service.dispose();
      lifecycle.dispose();
    });
    await service.initialize('correct horse battery staple');

    final c1 = service.encrypt('x');
    final c2 = service.encrypt('x');

    expect(c1, isNot(equals(c2)));
  });

  test('decrypt with wrong passphrase throws typed AppError', () async {
    final lifecycle1 = AppLifecycleService(binding: WidgetsBinding.instance);
    final service1 = EncryptionService(lifecycleService: lifecycle1);
    addTearDown(() {
      service1.dispose();
      lifecycle1.dispose();
    });
    await service1.initialize('passphrase-A');

    final ciphertext = service1.encrypt('secret');

    final lifecycle2 = AppLifecycleService(binding: WidgetsBinding.instance);
    final service2 = EncryptionService(lifecycleService: lifecycle2);
    addTearDown(() {
      service2.dispose();
      lifecycle2.dispose();
    });
    await service2.initialize('passphrase-B');

    expect(
      () => service2.decrypt(ciphertext),
      throwsA(isA<DecryptionFailedAppError>()),
    );
  });

  test('encrypt without initialize throws typed AppError', () {
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    addTearDown(() {
      service.dispose();
      lifecycle.dispose();
    });

    expect(
      () => service.encrypt('hello'),
      throwsA(isA<EncryptionNotInitializedAppError>()),
    );
  });

  test('decrypt invalid ciphertext format throws typed AppError', () async {
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final service = EncryptionService(lifecycleService: lifecycle);
    addTearDown(() {
      service.dispose();
      lifecycle.dispose();
    });
    await service.initialize('correct horse battery staple');

    expect(
      () => service.decrypt('not-base64url'),
      throwsA(isA<CiphertextFormatAppError>()),
    );
  });
}
