// Tests for Story 5-2: App Return Detection & Acquittement Trigger.
//
// Covers the new setActionState / pendingActionStream / clearActionState
// APIs added to AppLifecycleService.
//
// AC coverage:
//   AC1 / detect-and-route : setActionState + resume → emits on pendingActionStream
//   AC4 / expiry guard      : expired state silently dropped on resume
//   AC3 / clear-on-open     : clearActionState() removes state immediately

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/acquittement/domain/pending_action_state.dart';

// ---------------------------------------------------------------------------
// Minimal fake WidgetsBinding (reuse from core_utilities_test.dart pattern)
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
// Test helpers
// ---------------------------------------------------------------------------

PendingActionState _freshState({
  String friendId = 'f1',
  AcquittementOrigin origin = AcquittementOrigin.dailyView,
  String actionType = 'call',
  Duration age = Duration.zero,
}) {
  return PendingActionState(
    friendId: friendId,
    origin: origin,
    actionType: actionType,
    timestamp: DateTime.now().subtract(age),
  );
}

void main() {
  late _FakeBinding fakeBinding;
  late AppLifecycleService service;

  setUp(() {
    fakeBinding = _FakeBinding();
    service = AppLifecycleService(binding: fakeBinding);
  });

  tearDown(() => service.dispose());

  // ─────────────────────────────────────────────────────────────────────────
  // AC1: detect-and-route
  // ─────────────────────────────────────────────────────────────────────────
  group('detect-and-route', () {
    test('emits PendingActionState on resume when state is present and fresh',
        () async {
      final state = _freshState(friendId: 'f42', actionType: 'sms');
      service.setActionState(state);

      final emitted = <PendingActionState>[];
      final sub = service.pendingActionStream.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.length, 1);
      expect(emitted.first.friendId, 'f42');
      expect(emitted.first.actionType, 'sms');
      expect(emitted.first.origin, AcquittementOrigin.dailyView);
      await sub.cancel();
    });

    test('origin is preserved correctly', () async {
      final state = _freshState(
        friendId: 'f1',
        origin: AcquittementOrigin.friendCard,
        actionType: 'whatsapp',
      );
      service.setActionState(state);

      final emitted = <PendingActionState>[];
      final sub = service.pendingActionStream.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first.origin, AcquittementOrigin.friendCard);
      await sub.cancel();
    });

    test('nothing emitted when no state is set', () async {
      final emitted = <PendingActionState>[];
      final sub = service.pendingActionStream.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });

    test('state cleared automatically after resume', () async {
      service.setActionState(_freshState());

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentActionState, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AC4: expiry guard
  // ─────────────────────────────────────────────────────────────────────────
  group('expiry guard', () {
    test('expired state (>30 min) is silently dropped on resume', () async {
      final expiredState = _freshState(age: const Duration(minutes: 31));
      service.setActionState(expiredState);

      final emitted = <PendingActionState>[];
      final sub = service.pendingActionStream.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty,
          reason: 'Expired state must be silently discarded');
      await sub.cancel();
    });

    test('state exactly at 30 min boundary is expired', () async {
      final edgeState = _freshState(age: const Duration(minutes: 30));
      expect(edgeState.isExpired, isTrue);
    });

    test('state at 29 min 59 sec is NOT expired', () async {
      final freshish = _freshState(
        age: const Duration(minutes: 29, seconds: 59),
      );
      expect(freshish.isExpired, isFalse);
    });

    test('expired state is cleared even though not emitted', () async {
      service.setActionState(_freshState(age: const Duration(minutes: 45)));

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentActionState, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AC3: clear-on-open
  // ─────────────────────────────────────────────────────────────────────────
  group('clear-on-open', () {
    test('clearActionState() removes pending state immediately', () {
      service.setActionState(_freshState());
      expect(service.currentActionState, isNotNull);

      service.clearActionState();

      expect(service.currentActionState, isNull);
    });

    test('clearActionState() on already-null state is safe', () {
      expect(() => service.clearActionState(), returnsNormally);
      expect(service.currentActionState, isNull);
    });

    test('state not emitted after clearActionState() before resume', () async {
      service.setActionState(_freshState());
      service.clearActionState(); // simulates sheet opened pre-emptively

      final emitted = <PendingActionState>[];
      final sub = service.pendingActionStream.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy API backward-compat (must not be broken by story 5-2 changes)
  // ─────────────────────────────────────────────────────────────────────────
  group('legacy setPendingFriendId backward compatibility', () {
    test('setPendingFriendId still works independently of setActionState', () async {
      service.setPendingFriendId('legacy-friend');

      final emitted = <String?>[];
      final sub = service.pendingAcquittementFriendId.listen(emitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, ['legacy-friend']);
      await sub.cancel();
    });

    test('setActionState does not affect legacy stream', () async {
      service.setActionState(_freshState(friendId: 'f-new'));

      final legacyEmitted = <String?>[];
      final sub = service.pendingAcquittementFriendId.listen(legacyEmitted.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      // Legacy stream emits null (no legacy pending set)
      expect(legacyEmitted, [null]);
      await sub.cancel();
    });
  });
}
