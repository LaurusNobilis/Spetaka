// Story 4.2 — Unit tests for buildDailyView() logic.
//
// Tests the surface-window filtering and PriorityEngine integration
// without requiring a database or Riverpod container.

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Friend _friend({
  required String id,
  String name = 'Test',
  bool isConcernActive = false,
  bool isDemo = false,
  double careScore = 0.0,
  String? tags,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: '+33600000001',
    tags: tags,
    notes: null,
    careScore: careScore,
    isConcernActive: isConcernActive,
    concernNote: null,
    isDemo: isDemo,
    createdAt: now,
    updatedAt: now,
  );
}

Event _event({
  required String id,
  required String friendId,
  required DateTime date,
  bool isAcknowledged = false,
  bool isRecurring = false,
}) {
  return Event(
    id: id,
    friendId: friendId,
    type: 'Check-in',
    date: date.millisecondsSinceEpoch,
    isRecurring: isRecurring,
    comment: null,
    isAcknowledged: isAcknowledged,
    acknowledgedAt: null,
    createdAt: DateTime.now().millisecondsSinceEpoch,
    cadenceDays: null,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  group('buildDailyView — Story 4.2 surface window', () {
    test('AC1 — returns friends with overdue events', () {
      final alice = _friend(id: 'a', name: 'Alice');
      final events = [
        _event(
          id: 'e1',
          friendId: 'a',
          date: today.subtract(const Duration(days: 2)),
        ),
      ];
      final result = buildDailyView([alice], events);
      expect(result.length, 1);
      expect(result.first.friend.id, 'a');
      expect(result.first.prioritized.tier, UrgencyTier.urgent);
    });

    test('AC1 — returns friends with today events', () {
      final bob = _friend(id: 'b', name: 'Bob');
      final events = [
        _event(id: 'e2', friendId: 'b', date: today),
      ];
      final result = buildDailyView([bob], events);
      expect(result.length, 1);
      expect(result.first.prioritized.tier, UrgencyTier.urgent);
    });

    test('AC1 — returns friends with +3d events', () {
      final carol = _friend(id: 'c', name: 'Carol');
      final events = [
        _event(
          id: 'e3',
          friendId: 'c',
          date: today.add(const Duration(days: 3)),
        ),
      ];
      final result = buildDailyView([carol], events);
      expect(result.length, 1);
      expect(result.first.prioritized.tier, UrgencyTier.important);
    });

    test('AC4 — friends with event at +4d do NOT appear', () {
      final dave = _friend(id: 'd', name: 'Dave');
      final events = [
        _event(
          id: 'e4',
          friendId: 'd',
          date: today.add(const Duration(days: 4)),
        ),
      ];
      final result = buildDailyView([dave], events);
      expect(result, isEmpty, reason: '+4d is outside the surface window');
    });

    test('AC4 — friends with no events at all do NOT appear', () {
      final eve = _friend(id: 'e', name: 'Eve');
      final result = buildDailyView([eve], []);
      expect(result, isEmpty);
    });

    test('AC2 — result is sorted: urgent before important', () {
      final alice = _friend(id: 'a', name: 'Alice');
      final bob = _friend(id: 'b', name: 'Bob');
      final events = [
        // Bob has an important event (+2d)
        _event(
          id: 'e1',
          friendId: 'b',
          date: today.add(const Duration(days: 2)),
        ),
        // Alice has an urgent event (overdue)
        _event(
          id: 'e2',
          friendId: 'a',
          date: today.subtract(const Duration(days: 1)),
        ),
      ];
      final result = buildDailyView([alice, bob], events);
      expect(result.length, 2);
      expect(result[0].friend.id, 'a', reason: 'Urgent Alice should be first');
      expect(result[1].friend.id, 'b', reason: 'Important Bob should be second');
    });

    test('Story 4.5 coupling — demo friends ARE excluded (excludeDemo=true)', () {
      final sophie = _friend(id: 'sophie', name: 'Sophie', isDemo: true);
      final events = [
        _event(id: 'e1', friendId: 'sophie', date: today),
      ];
      final result = buildDailyView([sophie], events);
      expect(result, isEmpty, reason: 'Demo friend Sophie must not appear in daily view');
    });

    test('acknowledged one-time events do NOT surface (upstream filter)', () {
      // The events list passed to buildDailyView should already exclude
      // acknowledged one-time events (handled by watchPriorityInputEvents).
      // Simulate: pass acknowledged event directly — should still be filtered
      // by the engine since isAcknowledged=true means it has no unack event.
      final alice = _friend(id: 'a', name: 'Alice');
      final events = [
        _event(
          id: 'e1',
          friendId: 'a',
          date: today,
          isAcknowledged: true,
        ),
      ];
      // buildDailyView puts the event into the scoring input, but the engine
      // finds no UNACKNOWLEDGED event → tier = normal → still in list but no
      // urgency. For story 4.2 we only care about the surfacing.
      // Note: the real upstream filter (watchPriorityInputEvents) already
      // strips acknowledged one-time events before reaching buildDailyView.
      final result = buildDailyView([alice], events);
      // Friend appears (event is in window) but as normal tier since all events
      // are acknowledged — engine treats this as "no urgent/important event".
      expect(result.length, 1);
      expect(result.first.prioritized.tier, UrgencyTier.normal);
    });

    test('nextEventLabel — populated from nearest unacknowledged event type', () {
      final alice = _friend(id: 'a', name: 'Alice');
      final events = [
        Event(
          id: 'e1',
          friendId: 'a',
          type: 'Anniversaire',
          date: today.millisecondsSinceEpoch,
          isRecurring: false,
          comment: null,
          isAcknowledged: false,
          acknowledgedAt: null,
          createdAt: today.millisecondsSinceEpoch,
          cadenceDays: null,
        ),
      ];
      final result = buildDailyView([alice], events);
      expect(result.first.nextEventLabel, 'Anniversaire');
    });

    test('nextEventLabel — null when all events are acknowledged', () {
      final alice = _friend(id: 'a', name: 'Alice');
      final events = [
        Event(
          id: 'e1',
          friendId: 'a',
          type: 'Anniversaire',
          date: today.millisecondsSinceEpoch,
          isRecurring: false,
          comment: null,
          isAcknowledged: true,
          acknowledgedAt: today.millisecondsSinceEpoch,
          createdAt: today.millisecondsSinceEpoch,
          cadenceDays: null,
        ),
      ];
      // All acknowledged events → friend does not surface at all (filtered out
      // by the provider before reaching buildDailyView normally, but even if
      // passed explicitly the friend appears with tier=normal and null label).
      final result = buildDailyView([alice], events);
      // If the friend appears, its label should be null.
      if (result.isNotEmpty) {
        expect(result.first.nextEventLabel, isNull);
      }
    });

    test('nextEventLabel — nearest of multiple events selected', () {
      final alice = _friend(id: 'a', name: 'Alice');
      final farDate = today.add(const Duration(days: 3));
      final nearDate = today.add(const Duration(days: 1));
      final events = [
        Event(
          id: 'e1',
          friendId: 'a',
          type: 'Rendez-vous',
          date: farDate.millisecondsSinceEpoch,
          isRecurring: false,
          comment: null,
          isAcknowledged: false,
          acknowledgedAt: null,
          createdAt: today.millisecondsSinceEpoch,
          cadenceDays: null,
        ),
        Event(
          id: 'e2',
          friendId: 'a',
          type: 'Anniversaire',
          date: nearDate.millisecondsSinceEpoch,
          isRecurring: false,
          comment: null,
          isAcknowledged: false,
          acknowledgedAt: null,
          createdAt: today.millisecondsSinceEpoch,
          cadenceDays: null,
        ),
      ];
      final result = buildDailyView([alice], events);
      // e2 is nearer → 'Anniversaire'
      expect(result.first.nextEventLabel, 'Anniversaire');
    });

    test('multiple friends — mixed window', () {
      final friends = [
        _friend(id: 'a', name: 'Alice'),
        _friend(id: 'b', name: 'Bob'),
        _friend(id: 'c', name: 'Carol'),
      ];
      final events = [
        // Alice: urgent (overdue)
        _event(
          id: 'e1',
          friendId: 'a',
          date: today.subtract(const Duration(days: 1)),
        ),
        // Bob: important (+2d)
        _event(
          id: 'e2',
          friendId: 'b',
          date: today.add(const Duration(days: 2)),
        ),
        // Carol: outside window (+5d) — must not appear
        _event(
          id: 'e3',
          friendId: 'c',
          date: today.add(const Duration(days: 5)),
        ),
      ];
      final result = buildDailyView(friends, events);
      expect(result.length, 2);
      expect(result.map((e) => e.friend.id), containsAll(['a', 'b']));
      expect(result.map((e) => e.friend.id), isNot(contains('c')));
    });
  });
}
