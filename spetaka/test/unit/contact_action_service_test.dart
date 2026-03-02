// ignore_for_file: avoid_implementing_value_types

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/actions/contact_action_service.dart';
import 'package:spetaka/core/actions/phone_normalizer.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// ---------------------------------------------------------------------------
// Minimal fake WidgetsBinding (reuse pattern from core_utilities_test.dart)
// ---------------------------------------------------------------------------

class _FakeBinding extends Fake implements WidgetsBinding {
  final List<WidgetsBindingObserver> observers = [];

  @override
  void addObserver(WidgetsBindingObserver observer) =>
      observers.add(observer);

  @override
  bool removeObserver(WidgetsBindingObserver observer) =>
      observers.remove(observer);
}

// ---------------------------------------------------------------------------
// Controllable fake URL launcher
// ---------------------------------------------------------------------------

class _FakeUrlLauncher extends UrlLauncherPlatform {
  /// Set to false to simulate a failed launch.
  bool returnValue = true;

  /// When set, [launchUrl] throws this object.
  Object? throwOnLaunch;

  /// Stores the last URI string passed to [launchUrl].
  String? lastUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => returnValue;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    if (throwOnLaunch != null) {
      throw throwOnLaunch!;
    }
    lastUrl = url;
    return returnValue;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (throwOnLaunch != null) {
      throw throwOnLaunch!;
    }
    lastUrl = url;
    return returnValue;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ContactActionService _makeService({
  required AppLifecycleService lifecycle,
}) {
  return ContactActionService(
    normalizer: const PhoneNormalizer(),
    lifecycleService: lifecycle,
  );
}

void main() {
  late _FakeBinding fakeBinding;
  late AppLifecycleService lifecycle;
  late _FakeUrlLauncher fakeUrlLauncher;
  late ContactActionService service;
  late UrlLauncherPlatform previousUrlLauncher;

  setUp(() {
    fakeBinding = _FakeBinding();
    lifecycle = AppLifecycleService(binding: fakeBinding);
    fakeUrlLauncher = _FakeUrlLauncher();
    previousUrlLauncher = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = fakeUrlLauncher;
    service = _makeService(lifecycle: lifecycle);
  });

  tearDown(() {
    UrlLauncherPlatform.instance = previousUrlLauncher;
    lifecycle.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // call()
  // ─────────────────────────────────────────────────────────────────────────
  group('ContactActionService.call()', () {
    test('builds tel: URI from E.164 number', () async {
      await service.call('+33612345678', friendId: 'f1');

      expect(fakeUrlLauncher.lastUrl, 'tel:+33612345678');
    });

    test('normalizes French local number before building URI', () async {
      await service.call('0612345678', friendId: 'f1');

      expect(fakeUrlLauncher.lastUrl, 'tel:+33612345678');
    });

    test('records pending friend ID before launching', () async {
      await service.call('+33612345678', friendId: 'friend-42');

      // After a successful launch, the ID stays set (Story 5.2 will consume it
      // on app-resume; we only verify it was recorded).
      expect(lifecycle.currentPendingFriendId, 'friend-42');
    });

    test('rolls back pending friend ID on launch failure', () async {
      fakeUrlLauncher.returnValue = false;

      await expectLater(
        () => service.call('+33612345678', friendId: 'friend-42'),
        throwsA(isA<ContactActionFailedAppError>()),
      );

      expect(lifecycle.currentPendingFriendId, isNull);
    });

    test('rolls back pending friend ID when url_launcher throws', () async {
      fakeUrlLauncher.throwOnLaunch = Exception('boom');

      await expectLater(
        () => service.call('+33612345678', friendId: 'friend-42'),
        throwsA(isA<ContactActionFailedAppError>()),
      );

      expect(lifecycle.currentPendingFriendId, isNull);
    });

    test('invalid number throws PhoneNormalizationAppError before setting pendingId', () async {
      await expectLater(
        () => service.call('not-a-number', friendId: 'friend-99'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );

      // pendingId must never have been set.
      expect(lifecycle.currentPendingFriendId, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // sms()
  // ─────────────────────────────────────────────────────────────────────────
  group('ContactActionService.sms()', () {
    test('builds sms: URI', () async {
      await service.sms('+33612345678', friendId: 'f1');

      expect(fakeUrlLauncher.lastUrl, 'sms:+33612345678');
    });

    test('rolls back pending friend ID on SMS launch failure', () async {
      fakeUrlLauncher.returnValue = false;

      await expectLater(
        () => service.sms('+33612345678', friendId: 'f1'),
        throwsA(isA<ContactActionFailedAppError>()),
      );

      expect(lifecycle.currentPendingFriendId, isNull);
    });

    test('invalid number throws PhoneNormalizationAppError', () async {
      await expectLater(
        () => service.sms('', friendId: 'f1'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // whatsapp()
  // ─────────────────────────────────────────────────────────────────────────
  group('ContactActionService.whatsapp()', () {
    test('builds https://wa.me/ URI with digits-only (no leading +)', () async {
      await service.whatsapp('+33612345678', friendId: 'f1');

      expect(fakeUrlLauncher.lastUrl, 'https://wa.me/33612345678');
    });

    test('normalizes French local number for WhatsApp URI', () async {
      await service.whatsapp('0612345678', friendId: 'f1');

      expect(fakeUrlLauncher.lastUrl, 'https://wa.me/33612345678');
    });

    test('rolls back pending friend ID on WhatsApp launch failure', () async {
      fakeUrlLauncher.returnValue = false;

      await expectLater(
        () => service.whatsapp('+33612345678', friendId: 'f1'),
        throwsA(isA<ContactActionFailedAppError>()),
      );

      expect(lifecycle.currentPendingFriendId, isNull);
    });

    test('invalid number throws PhoneNormalizationAppError', () async {
      await expectLater(
        () => service.whatsapp('abc', friendId: 'f1'),
        throwsA(isA<PhoneNormalizationAppError>()),
      );
    });
  });
}
