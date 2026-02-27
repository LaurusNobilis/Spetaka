import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/core/errors/error_messages.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';

// ---------------------------------------------------------------------------
// Minimal fake WidgetsBinding that captures added/removed observers.
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

void main() {
  group('AppLifecycleService', () {
    late _FakeBinding fakeBinding;
    late AppLifecycleService service;

    setUp(() {
      fakeBinding = _FakeBinding();
      service = AppLifecycleService(binding: fakeBinding);
    });

    tearDown(() => service.dispose());

    test('registers as observer on construction', () {
      expect(fakeBinding.observers, contains(service));
    });

    test('deregisters as observer on dispose', () {
      // Use an isolated instance so tearDown does not double-dispose.
      final isolated = AppLifecycleService(binding: fakeBinding);
      expect(fakeBinding.observers, contains(isolated));
      isolated.dispose();
      expect(fakeBinding.observers, isNot(contains(isolated)));
    });

    test('emits pending friend ID on resumed lifecycle event', () async {
      service.setPendingFriendId('friend-42');

      final emitted = <String?>[];
      final sub = service.pendingAcquittementFriendId.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, ['friend-42']);
      await sub.cancel();
    });

    test('clears pending friend ID after resume', () async {
      service.setPendingFriendId('friend-42');
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentPendingFriendId, isNull);
    });

    test('emits null when no friend ID is set and app resumes', () async {
      final emitted = <String?>[];
      final sub = service.pendingAcquittementFriendId.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [null]);
      await sub.cancel();
    });

    test('does NOT emit on paused or inactive lifecycle states', () async {
      final emitted = <String?>[];
      final sub = service.pendingAcquittementFriendId.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });

    test('setPendingFriendId(null) clears previous value', () {
      service.setPendingFriendId('friend-1');
      service.setPendingFriendId(null);
      expect(service.currentPendingFriendId, isNull);
    });

    test('currentPendingFriendId returns set value before resume', () {
      service.setPendingFriendId('x');
      expect(service.currentPendingFriendId, 'x');
    });

    test('stream is broadcast — multiple listeners allowed', () async {
      final a = <String?>[];
      final b = <String?>[];

      final sub1 = service.pendingAcquittementFriendId.listen(a.add);
      final sub2 = service.pendingAcquittementFriendId.listen(b.add);

      service.setPendingFriendId('z');
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(a, ['z']);
      expect(b, ['z']);
      await sub1.cancel();
      await sub2.cancel();
    });
  });

  // ── Riverpod provider ────────────────────────────────────────────────────

  group('appLifecycleServiceProvider', () {
    testWidgets('provider creates AppLifecycleService', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final service = ref.watch(appLifecycleServiceProvider);
              expect(service, isA<AppLifecycleService>());
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  // ── Error message integration ─────────────────────────────────────────────

  group('error_messages.dart — new entries', () {
    test('PhoneNormalizationAppError has user-facing message', () {
      final msg = errorMessageFor(const PhoneNormalizationAppError('bad'));
      expect(msg, isNotEmpty);
    });

    test('ContactActionFailedAppError has user-facing message', () {
      final msg = errorMessageFor(const ContactActionFailedAppError('call'));
      expect(msg, contains('call'));
    });

    test('ContactPermissionDeniedAppError has user-facing message', () {
      final msg = errorMessageFor(const ContactPermissionDeniedAppError());
      expect(msg, isNotEmpty);
    });

    test('ContactHasNoPhoneAppError has user-facing message', () {
      final msg = errorMessageFor(const ContactHasNoPhoneAppError());
      expect(msg, isNotEmpty);
    });

    test('FriendNameMissingAppError has user-facing message', () {
      final msg = errorMessageFor(const FriendNameMissingAppError());
      expect(msg, isNotEmpty);
    });

    test('FriendMobileMissingAppError has user-facing message', () {
      final msg = errorMessageFor(const FriendMobileMissingAppError());
      expect(msg, isNotEmpty);
    });
  });
}
