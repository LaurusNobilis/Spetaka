// Scaffold structure unit tests.
// Validates directory organization and file existence assumptions that
// are verifiable without a running Flutter engine.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Feature-first directory structure (AC: 3)', () {
    test('lib/core/ directory exists', () {
      expect(Directory('lib/core').existsSync(), isTrue);
    });

    test('lib/features/ directory exists', () {
      expect(Directory('lib/features').existsSync(), isTrue);
    });

    test('lib/shared/ directory exists', () {
      expect(Directory('lib/shared').existsSync(), isTrue);
    });

    test('lib/core/core.dart barrel file exists', () {
      expect(File('lib/core/core.dart').existsSync(), isTrue);
    });

    test('lib/features/features.dart barrel file exists', () {
      expect(File('lib/features/features.dart').existsSync(), isTrue);
    });

    test('lib/shared/shared.dart barrel file exists', () {
      expect(File('lib/shared/shared.dart').existsSync(), isTrue);
    });
  });

  group('Android configuration (AC: 5, 6)', () {
    test('android/app/build.gradle contains minSdk 26', () {
      final buildGradle = File('android/app/build.gradle').readAsStringSync();
      // Flutter templates and AGP DSL have evolved over time.
      // Accept both the legacy `minSdkVersion 26` and modern `minSdk = 26`.
      expect(
        buildGradle,
        anyOf(
          contains('minSdkVersion 26'),
          contains('minSdk = 26'),
        ),
      );
    });

    test('AndroidManifest.xml does NOT contain FCM or notification permissions',
        () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, isNot(contains('RECEIVE_BOOT_COMPLETED')));
      expect(manifest, isNot(contains('VIBRATE')));
      expect(manifest, isNot(contains('POST_NOTIFICATIONS')));
      expect(manifest, isNot(contains('com.google.firebase')));
      expect(manifest, isNot(contains('FirebaseMessaging')));
    });

    test('AndroidManifest.xml declares INTERNET permission', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android.permission.INTERNET'));
    });

    test('AndroidManifest.xml declares READ_CONTACTS permission', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android.permission.READ_CONTACTS'));
    });

    test('AndroidManifest.xml contains exactly 2 uses-permission entries', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final matches = RegExp(r'<uses-permission').allMatches(manifest);
      expect(matches.length, equals(2));
    });
  });

  group('pubspec.yaml dependency baseline (AC: 2)', () {
    late String pubspec;

    setUpAll(() {
      pubspec = File('pubspec.yaml').readAsStringSync();
    });

    test('riverpod_annotation is declared', () {
      expect(pubspec, contains('riverpod_annotation'));
    });

    test('drift is declared', () {
      expect(pubspec, contains('drift:'));
    });

    test('go_router is declared', () {
      expect(pubspec, contains('go_router:'));
    });

    test('encrypt is declared', () {
      expect(pubspec, contains('encrypt:'));
    });

    test('webdav_client is declared', () {
      expect(pubspec, contains('webdav_client:'));
    });

    test('flutter_contacts is declared', () {
      expect(pubspec, contains('flutter_contacts:'));
    });

    test('url_launcher is declared', () {
      expect(pubspec, contains('url_launcher:'));
    });

    test('uuid is declared', () {
      expect(pubspec, contains('uuid:'));
    });

    test('shared_preferences is declared', () {
      expect(pubspec, contains('shared_preferences:'));
    });

    test('intl is declared', () {
      expect(pubspec, contains('intl'));
    });

    test('riverpod_generator dev dependency is declared', () {
      expect(pubspec, contains('riverpod_generator'));
    });

    test('drift_dev dev dependency is declared', () {
      expect(pubspec, contains('drift_dev'));
    });

    test('build_runner dev dependency is declared', () {
      expect(pubspec, contains('build_runner'));
    });

    test('flutter_lints dev dependency is declared', () {
      expect(pubspec, contains('flutter_lints'));
    });
  });

  group('analysis_options.yaml (AC: 4)', () {
    test('includes flutter_lints package', () {
      final opts = File('analysis_options.yaml').readAsStringSync();
      expect(opts, contains('package:flutter_lints/flutter.yaml'));
    });
  });
}
