// Priority Engine — pure Dart, zero Flutter / Drift imports.
//
// Story 4.1: computes a priorityScore for each friend card and returns them
// sorted by descending score, grouped into UrgencyTiers.
//
// Formula (Story 4.1 AC2):
//   score = eventWeight + overdueBonus + categoryWeight
//           + (hasConcern ? 2 * kBaseScore : 0)
//           + careScoreBoost
//
// Story 4.5 coupling note:
//   sort() accepts an optional excludeDemo parameter so demo entities can
//   be excluded from the real-friend pipeline without the engine reading
//   Drift-generated fields directly. Tests written for 4.1 remain valid
//   because excludeDemo defaults to false.

// ---------------------------------------------------------------------------
// Value objects (pure Dart DTOs — no Drift / Flutter dependency)
// ---------------------------------------------------------------------------

/// Summary of one event used exclusively by the scoring engine.
class EventScoringInput {
  const EventScoringInput({
    required this.date,
    this.isAcknowledged = false,
    this.isRecurring = false,
  });

  /// The event date (local midnight typically).
  final DateTime date;

  /// Whether the user has already acknowledged this event.
  final bool isAcknowledged;

  /// Whether this is a recurring cadence event.
  final bool isRecurring;
}

/// Summary of one friend card used exclusively by the scoring engine.
class FriendScoringInput {
  const FriendScoringInput({
    required this.id,
    required this.events,
    this.careScore = 0.0,
    this.hasConcern = false,
    this.tags = const [],
    this.isDemo = false,
  });

  /// Unique friend identifier (passed through without modification).
  final String id;

  /// All events attached to this friend (acknowledged or not).
  final List<EventScoringInput> events;

  /// Care score in the range [0.0, 1.0].
  final double careScore;

  /// Whether the concern / préoccupation flag is active.
  final bool hasConcern;

  /// Category tags (e.g. ["Family", "Work"]).
  final List<String> tags;

  /// True for demo-seeded friends (Story 4.5). Engine ignores this unless
  /// [PriorityEngine.sort] is called with [excludeDemo] = true.
  final bool isDemo;
}

// ---------------------------------------------------------------------------
// Output types
// ---------------------------------------------------------------------------

/// Urgency classification returned alongside the computed score.
enum UrgencyTier {
  /// Today or overdue (unacknowledged).
  urgent,

  /// Within the next 3 days (unacknowledged).
  important,

  /// No imminent event.
  normal,
}

/// Result entry produced by [PriorityEngine.sort].
class PrioritizedFriend {
  const PrioritizedFriend({
    required this.friendId,
    required this.score,
    required this.tier,
    required this.daysUntilNextEvent,
  });

  /// The friend's unique identifier (mirrors [FriendScoringInput.id]).
  final String friendId;

  /// Computed priority score (higher = more pressing).
  final double score;

  /// Urgency classification derived from the nearest unacknowledged event.
  final UrgencyTier tier;

  /// Days until the nearest unacknowledged event.
  /// Negative means overdue, null means no events.
  final int? daysUntilNextEvent;

  @override
  String toString() =>
      'PrioritizedFriend(id: $friendId, score: ${score.toStringAsFixed(2)}, '
      'tier: $tier, days: $daysUntilNextEvent)';
}

// ---------------------------------------------------------------------------
// Engine constants
// ---------------------------------------------------------------------------

/// Base score constant used in the concern multiplier formula.
const double kBaseScore = 10.0;

/// Weights assigned to individual category tags.
/// Unknown tags resolve to [kDefaultCategoryWeight].
const Map<String, double> kCategoryWeights = {
  'Family': 3.0,
  'Close Friend': 2.5,
  'Friend': 2.0,
  'Colleague': 1.5,
  'Acquaintance': 1.0,
  'Work': 1.5,
};

const double kDefaultCategoryWeight = 1.0;

/// Max care-score boost contribution +5.0 (for careScore = 1.0).
const double kCareScoreMultiplier = 5.0;

/// Overdue bonus rate: +0.3 per day overdue, capped at 5.0.
const double kOverdueBonusRate = 0.3;
const double kMaxOverdueBonus = 5.0;

/// Default expected contact interval in days when no recurring event defines one.
///
/// Story 5.5: used by [computeCareScore] when a friend has no check-in cadence.
const int kDefaultExpectedIntervalDays = 30;

/// Maximum category weight value — equals the 'Family' entry in [kCategoryWeights].
///
/// Story 5.5: used to normalise the care weight to [0..1] so that [computeCareScore]
/// always returns a value within the persisted REAL column range [0.0, 1.0].
const double kMaxCareWeight = 3.0;

// ---------------------------------------------------------------------------
// Care-score formula (Story 5.5)
// ---------------------------------------------------------------------------

/// Computes a care score in the range [0.0, 1.0] for a friend card.
///
/// Formula (Story 5.5):
///   rawCare    = (expectedIntervalDays − daysSinceLastContact) / expectedIntervalDays
///   careWeight = maxTagWeight / [kMaxCareWeight]
///   careScore  = clamp(rawCare × careWeight, 0.0, 1.0)
///
/// Properties:
/// - Immediately after an acquittement (daysSince = 0) the score equals careWeight.
/// - Score decreases as [daysSinceLastContact] grows toward [expectedIntervalDays].
/// - Score is clamped to 0.0 once days ≥ expectedIntervalDays.
/// - A 'Family' friend scores higher than an 'Acquaintance' when all else equal.
///
/// [expectedIntervalDays] defaults to [kDefaultExpectedIntervalDays] when null or ≤ 0.
double computeCareScore({
  required int daysSinceLastContact,
  int? expectedIntervalDays,
  List<String> tags = const [],
}) {
  final interval = (expectedIntervalDays == null || expectedIntervalDays <= 0)
      ? kDefaultExpectedIntervalDays
      : expectedIntervalDays;

  final rawCare = (interval - daysSinceLastContact) / interval;

  // Determine the maximum tag weight for this friend (same map as scoring engine).
  var maxTagWeight = kDefaultCategoryWeight;
  for (final tag in tags) {
    final w = kCategoryWeights[tag] ?? kDefaultCategoryWeight;
    if (w > maxTagWeight) maxTagWeight = w;
  }
  final careWeight = maxTagWeight / kMaxCareWeight;

  return (rawCare * careWeight).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// PriorityEngine
// ---------------------------------------------------------------------------

/// Stateless scoring engine. Instantiate once and reuse.
///
/// All public methods are pure functions: given the same inputs they always
/// produce the same outputs, with no side effects.
class PriorityEngine {
  const PriorityEngine();

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Sorts [friends] by descending [PrioritizedFriend.score].
  ///
  /// [now] defaults to [DateTime.now()]; inject for deterministic tests.
  ///
  /// [excludeDemo] — when true, all [FriendScoringInput] with [isDemo]=true
  /// are removed before scoring. This is the only place `isDemo` influences
  /// the engine, keeping 4.1 unit tests independent of Drift migrations.
  List<PrioritizedFriend> sort(
    List<FriendScoringInput> friends, {
    DateTime? now,
    bool excludeDemo = false,
  }) {
    final today = _toDateOnly(now ?? DateTime.now());

    var inputs = friends;
    if (excludeDemo) {
      inputs = friends.where((f) => !f.isDemo).toList();
    }

    final scored = inputs.map((f) => _score(f, today)).toList()
      ..sort((a, b) {
        // Primary: tier (urgent > important > normal)
        final tierCmp = a.tier.index.compareTo(b.tier.index);
        if (tierCmp != 0) return tierCmp;
        // Secondary: score descending
        return b.score.compareTo(a.score);
      });

    return scored;
  }

  /// Scores a single friend without sorting (useful for unit tests).
  PrioritizedFriend scoreOne(FriendScoringInput friend, {DateTime? now}) {
    final today = _toDateOnly(now ?? DateTime.now());
    return _score(friend, today);
  }

  // -------------------------------------------------------------------------
  // Scoring internals
  // -------------------------------------------------------------------------

  PrioritizedFriend _score(FriendScoringInput f, DateTime today) {
    // Nearest unacknowledged event relative to today.
    final nearest = _nearestUnacknowledged(f.events, today);

    final int? daysUntil = nearest != null
        ? _toDateOnly(nearest.date).difference(today).inDays
        : null;

    final tier = _urgencyTier(daysUntil);
    final eventWeight = _eventWeight(daysUntil);
    final overdueBonus = _overdueBonus(daysUntil);
    final categoryWeight = _categoryWeight(f.tags);
    final concernContrib = f.hasConcern ? 2.0 * kBaseScore : 0.0;
    final careBoost = f.careScore.clamp(0.0, 1.0) * kCareScoreMultiplier;

    final score =
        eventWeight + overdueBonus + categoryWeight + concernContrib + careBoost;

    return PrioritizedFriend(
      friendId: f.id,
      score: score,
      tier: tier,
      daysUntilNextEvent: daysUntil,
    );
  }

  // -------------------------------------------------------------------------
  // Component functions (package-private for tests)
  // -------------------------------------------------------------------------

  EventScoringInput? _nearestUnacknowledged(
    List<EventScoringInput> events,
    DateTime today,
  ) {
    final unack = events.where((e) => !e.isAcknowledged).toList();
    if (unack.isEmpty) return null;

    // Prefer future / today events by closest date, then fallback to most
    // recently overdue.
    unack.sort((a, b) {
      final dA = _toDateOnly(a.date).difference(today).inDays;
      final dB = _toDateOnly(b.date).difference(today).inDays;
      // Overdue first (most negative = oldest overdue comes after less negative)
      // We want the "most pressing": today first, then smallest positive, then
      // least negative (i.e. most recently overdue).
      // Strategy: abs(days) ascending; ties broken by future > past.
      final absCmp = dA.abs().compareTo(dB.abs());
      if (absCmp != 0) return absCmp;
      return dA.compareTo(dB); // future wins
    });
    return unack.first;
  }

  /// Maps daysUntil to a weight contribution.
  double _eventWeight(int? daysUntil) {
    if (daysUntil == null) return 0.0;
    if (daysUntil <= 0) return 5.0; // today or overdue
    if (daysUntil <= 3) return 3.0; // important window
    if (daysUntil <= 7) return 1.5;
    if (daysUntil <= 30) return 0.75;
    return 0.25;
  }

  double _overdueBonus(int? daysUntil) {
    if (daysUntil == null || daysUntil >= 0) return 0.0;
    return ((-daysUntil) * kOverdueBonusRate).clamp(0.0, kMaxOverdueBonus);
  }

  double _categoryWeight(List<String> tags) {
    if (tags.isEmpty) return kDefaultCategoryWeight;
    var maxWeight = kDefaultCategoryWeight;
    for (final tag in tags) {
      final w = kCategoryWeights[tag] ?? kDefaultCategoryWeight;
      if (w > maxWeight) maxWeight = w;
    }
    return maxWeight;
  }

  UrgencyTier _urgencyTier(int? daysUntil) {
    if (daysUntil == null) return UrgencyTier.normal;
    if (daysUntil <= 0) return UrgencyTier.urgent;
    if (daysUntil <= 3) return UrgencyTier.important;
    return UrgencyTier.normal;
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  /// Strips time-of-day so all comparisons are date-only.
  DateTime _toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
