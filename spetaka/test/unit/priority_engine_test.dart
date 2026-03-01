// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/features/daily/domain/priority_engine.dart';

void main() {
  const engine = PriorityEngine();

  // Reference date used throughout tests.
  final today = DateTime(2026, 3, 1);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FriendScoringInput friend({
    String id = 'f1',
    List<EventScoringInput> events = const [],
    double careScore = 0.0,
    bool hasConcern = false,
    List<String> tags = const [],
    bool isDemo = false,
  }) {
    return FriendScoringInput(
      id: id,
      events: events,
      careScore: careScore,
      hasConcern: hasConcern,
      tags: tags,
      isDemo: isDemo,
    );
  }

  EventScoringInput event(DateTime date, {bool isAcknowledged = false}) =>
      EventScoringInput(date: date, isAcknowledged: isAcknowledged);

  // ---------------------------------------------------------------------------
  // Urgency tier tests
  // ---------------------------------------------------------------------------

  group('Urgency tiers', () {
    test('overdue event → urgent tier', () {
      final f = friend(events: [event(today.subtract(const Duration(days: 2)))]);
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.urgent);
      expect(result.daysUntilNextEvent, -2);
    });

    test('today event → urgent tier', () {
      final f = friend(events: [event(today)]);
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.urgent);
      expect(result.daysUntilNextEvent, 0);
    });

    test('event in 1 day → important tier', () {
      final f = friend(events: [event(today.add(const Duration(days: 1)))]);
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.important);
    });

    test('event in 3 days → important tier', () {
      final f = friend(events: [event(today.add(const Duration(days: 3)))]);
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.important);
    });

    test('event in 4 days → normal tier', () {
      final f = friend(events: [event(today.add(const Duration(days: 4)))]);
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.normal);
    });

    test('no events → normal tier', () {
      final f = friend();
      final result = engine.scoreOne(f, now: today);
      expect(result.tier, UrgencyTier.normal);
      expect(result.daysUntilNextEvent, isNull);
    });

    test('acknowledged event is ignored for tier', () {
      final f = friend(
        events: [
          event(today, isAcknowledged: true),
          event(today.add(const Duration(days: 10))),
        ],
      );
      final result = engine.scoreOne(f, now: today);
      // today's event acknowledged → nearest unacknowledged is +10 days
      expect(result.tier, UrgencyTier.normal);
    });
  });

  // ---------------------------------------------------------------------------
  // Score formula components
  // ---------------------------------------------------------------------------

  group('Score formula', () {
    test('concern doubles baseScore contribution', () {
      final fNoConcern = friend();
      final fConcern = friend(hasConcern: true);

      final scoreNoConcern = engine.scoreOne(fNoConcern, now: today).score;
      final scoreConcern = engine.scoreOne(fConcern, now: today).score;

      // concern adds 2*kBaseScore = 20.0
      expect(scoreConcern - scoreNoConcern, closeTo(2 * kBaseScore, 0.001));
    });

    test('careScore boost scales linearly', () {
      final f0 = friend(careScore: 0.0);
      final f1 = friend(careScore: 1.0);

      final s0 = engine.scoreOne(f0, now: today).score;
      final s1 = engine.scoreOne(f1, now: today).score;

      expect(s1 - s0, closeTo(kCareScoreMultiplier, 0.001));
    });

    test('Family tag yields highest category weight', () {
      final fFamily = friend(tags: ['Family']);
      final fAcq = friend(tags: ['Acquaintance']);

      final sFamily = engine.scoreOne(fFamily, now: today).score;
      final sAcq = engine.scoreOne(fAcq, now: today).score;

      expect(sFamily, greaterThan(sAcq));
    });

    test('overdue bonus increases with days', () {
      final f2 = friend(events: [event(today.subtract(const Duration(days: 2)))]);
      final f5 = friend(events: [event(today.subtract(const Duration(days: 5)))]);

      final s2 = engine.scoreOne(f2, now: today).score;
      final s5 = engine.scoreOne(f5, now: today).score;

      expect(s5, greaterThan(s2));
    });
  });

  // ---------------------------------------------------------------------------
  // Sort determinism
  // ---------------------------------------------------------------------------

  group('Sort determinism', () {
    test('urgent friends rank above important', () {
      final urgentFriend = friend(
        id: 'urgent',
        events: [event(today.subtract(const Duration(days: 1)))],
      );
      final importantFriend = friend(
        id: 'important',
        events: [event(today.add(const Duration(days: 2)))],
      );

      final result = engine.sort([importantFriend, urgentFriend], now: today);

      expect(result.first.friendId, 'urgent');
    });

    test('higher care score wins when same tier', () {
      final f1 = friend(
        id: 'low',
        careScore: 0.2,
        events: [event(today.add(const Duration(days: 1)))],
      );
      final f2 = friend(
        id: 'high',
        careScore: 0.9,
        events: [event(today.add(const Duration(days: 1)))],
      );

      final result = engine.sort([f1, f2], now: today);

      expect(result.first.friendId, 'high');
    });

    test('same inputs produce same output order', () {
      final friends = List.generate(
        10,
        (i) => friend(
          id: 'f$i',
          careScore: i * 0.1,
          events: [event(today.add(Duration(days: i)))],
        ),
      );
      final r1 = engine.sort(friends, now: today);
      final r2 = engine.sort(friends, now: today);
      expect(
        r1.map((f) => f.friendId).toList(),
        r2.map((f) => f.friendId).toList(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // excludeDemo parameter (4-5 coupling)
  // ---------------------------------------------------------------------------

  group('excludeDemo', () {
    test('demo friends excluded when excludeDemo=true', () {
      final demo = friend(
        id: 'demo',
        isDemo: true,
        events: [event(today)],
      );
      final real = friend(
        id: 'real',
        events: [event(today.add(const Duration(days: 1)))],
      );

      final result = engine.sort([demo, real], now: today, excludeDemo: true);

      expect(result.map((f) => f.friendId), isNot(contains('demo')));
      expect(result.map((f) => f.friendId), contains('real'));
    });

    test('demo friends included when excludeDemo=false (default)', () {
      final demo = friend(id: 'demo', isDemo: true);
      final result = engine.sort([demo], now: today);
      expect(result.map((f) => f.friendId), contains('demo'));
    });
  });

  // ---------------------------------------------------------------------------
  // Performance benchmark (<500ms for 100 cards)
  // ---------------------------------------------------------------------------

  test('benchmark: <500ms for 100 cards', () {
    final friends = List.generate(100, (i) {
      return FriendScoringInput(
        id: 'bench_$i',
        careScore: (i % 10) * 0.1,
        hasConcern: i.isOdd,
        tags: i % 3 == 0 ? ['Family'] : (i % 3 == 1 ? ['Work'] : []),
        events: List.generate(
          (i % 5) + 1,
          (j) => EventScoringInput(
            date: today.add(Duration(days: (i + j) - 5)),
            isAcknowledged: j.isEven,
          ),
        ),
      );
    });

    final sw = Stopwatch()..start();
    engine.sort(friends, now: today);
    sw.stop();

    expect(
      sw.elapsedMilliseconds,
      lessThan(500),
      reason: 'Priority engine must sort 100 cards in <500ms '
          '(took ${sw.elapsedMilliseconds}ms)',
    );
  });
}
