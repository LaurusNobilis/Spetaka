# Story 9.1: Auto-Create Concern Follow-Up Cadence on Flag Activation

Status: done

## Story

As Laurus,
I want Spetaka to automatically create a recurring check-in cadence when I set a concern flag on a friend,
So that a friend going through a difficult time is automatically surfaced in my daily view without me needing to manually add a cadence.

## Acceptance Criteria

1. **Given** Laurus sets a concern flag on a friend (via `FriendCardScreen` "Set concern" flow from Story 2.9)
   **When** `FriendRepository.setConcern(friendId, note, cadenceDays)` is called
   **Then** `FriendRepository` automatically creates a new `Event` record for that friend with: `type = 'Prendre des nouvelles'`, `is_recurring = true`, `cadence_days` = cadenceDays (default: 7), `is_acknowledged = false`, and a `comment` of `'Auto-created — concern follow-up'`
   **And** the event creation and the concern flag update are performed atomically in a single Drift transaction — either both succeed or neither does
   **And** the new cadence event becomes immediately visible in the events list on `FriendCardScreen` (reactive stream update)
   **And** the cadence event appears in the priority engine's surface window on the next daily view load, subject to the standard overdue/window logic

2. **Given** Laurus clears the concern flag on a friend (via `FriendCardScreen` "Clear concern" flow from Story 2.9)
   **When** `FriendRepository.clearConcern(friendId)` is called
   **Then** the automatically-created cadence event (identified by its `comment = 'Auto-created — concern follow-up'` marker) is deleted from the `events` table in the same atomic transaction as the concern flag clear
   **And** only the auto-created concern cadence is deleted — any other manually-added cadences on the friend are untouched
   **And** if no auto-created concern cadence exists for this friend (e.g., it was manually deleted earlier), the clear operation succeeds without error

3. **Given** the concern cadence auto-creation
   **Then** it reads the interval from `ConcernCadenceSettingsProvider` (Story 9.2), not a hardcoded value — the default is 7 if no user setting has been saved

4. **Given** `flutter test test/repositories/friend_repository_test.dart`
   **Then** tests pass including: set concern → verify auto-cadence event created with `cadence_days = 7`; clear concern → verify auto-cadence event deleted and other events untouched; set concern with custom settings interval of 14 → verify `cadence_days = 14`

## Tasks / Subtasks

- [x] Task 1: Add `EventDao.findConcernCadenceByFriendId` method (AC: 2)
  - [x] 1.1 Add `findConcernCadenceByFriendId(String friendId)` method to `lib/core/database/daos/event_dao.dart`
  - [x] 1.2 Method queries events by friendId AND comment = 'Auto-created — concern follow-up', returns single or null

- [x] Task 2: Update `FriendRepository.setConcern` to auto-create cadence event (AC: 1, 3)
  - [x] 2.1 Add `int cadenceDays = 7` named parameter to `setConcern`
  - [x] 2.2 Import `package:uuid/uuid.dart` in `friend_repository.dart`
  - [x] 2.3 Wrap friend update + event insert in `db.transaction()` for atomicity
  - [x] 2.4 Insert event with: type='Prendre des nouvelles', is_recurring=true, cadence_days=cadenceDays, comment='Auto-created — concern follow-up', is_acknowledged=false, date=now, createdAt=now

- [x] Task 3: Update `FriendRepository.clearConcern` to delete auto-cadence atomically (AC: 2)
  - [x] 3.1 Before transaction, find auto-created cadence via `db.eventDao.findConcernCadenceByFriendId(id)`
  - [x] 3.2 Wrap friend update + optional event delete in `db.transaction()`
  - [x] 3.3 Delete the concern cadence event only if it exists (no error if absent)

- [x] Task 4: Update `FriendCardScreen._handleSetConcern` to pass cadenceDays (AC: 1, 3)
  - [x] 4.1 Read `ref.read(concernCadenceProvider)` in `_handleSetConcern`
  - [x] 4.2 Pass `cadenceDays: cadenceDays` to `repo.setConcern()`
  - [x] 4.3 Import `concern_cadence_provider.dart` in `friend_card_screen.dart`

- [x] Task 5: Write Story 9.1 tests in `friend_repository_test.dart` (AC: 4)
  - [x] 5.1 Add test group 'FriendRepository — Story 9.1 concern auto-cadence'
  - [x] 5.2 Test: setConcern creates auto-cadence event with cadence_days=7 (default)
  - [x] 5.3 Test: setConcern with cadenceDays:14 creates event with cadence_days=14
  - [x] 5.4 Test: clearConcern deletes the auto-created cadence event
  - [x] 5.5 Test: clearConcern leaves other events untouched
  - [x] 5.6 Test: clearConcern is safe when no auto-cadence exists

## Dev Notes

### Architecture / Guardrails

- **Atomicity via Drift transaction**: Both the friend flag update and the event insert/delete MUST be wrapped in `db.transaction(() async { ... })`. Drift's `GeneratedDatabase.transaction()` method ensures either both operations succeed or neither does.
- **Event type string**: Use `'Prendre des nouvelles'` — the current French stored name for "Regular check-in" as seeded in `app_database.dart` v9. This is consistent with events created via the UI.
- **Auto-cadence marker constant**: The comment `'Auto-created — concern follow-up'` is the ONLY identifier for the auto-created event. No separate DB column is needed.
- **cadenceDays parameter**: `setConcern` receives `cadenceDays` from the caller (FriendCardScreen reads from `concernCadenceProvider`). Default=7 ensures backward compatibility and testability.
- **No duplicate detection**: Per AC, a new cadence is always created on `setConcern`. The previous one is deleted by `clearConcern`. Re-activation after clear creates a fresh cadence.
- **Offline-first**: No network calls.

### Provider Contract (from Story 9.2)

```dart
// In friend_card_screen.dart _handleSetConcern:
final cadenceDays = ref.read(concernCadenceProvider); // always int, default 7
await ref.read(friendRepositoryProvider).setConcern(friend.id, note: note, cadenceDays: cadenceDays);
```

### EventDao change

```dart
// New method in EventDao (lib/core/database/daos/event_dao.dart):
Future<Event?> findConcernCadenceByFriendId(String friendId) =>
    (select(events)
          ..where((e) =>
              e.friendId.equals(friendId) &
              e.comment.equals('Auto-created — concern follow-up')))
        .getSingleOrNull();
```

### FriendRepository.setConcern change

```dart
Future<void> setConcern(String id, {String? note, int cadenceDays = 7}) async {
  final friend = await findById(id);
  if (friend == null) return;
  final trimmed = note?.trim();
  final now = DateTime.now().millisecondsSinceEpoch;
  final eventId = const Uuid().v4();
  await db.transaction(() async {
    await db.friendDao.updateFriend(_toEncryptedCompanion(friend.copyWith(
      isConcernActive: true,
      concernNote: Value(trimmed?.isEmpty == true ? null : trimmed),
      updatedAt: now,
    )));
    await db.eventDao.insertEvent(EventsCompanion.insert(
      id: eventId,
      friendId: id,
      type: 'Prendre des nouvelles',
      date: now,
      isRecurring: const Value(true),
      comment: const Value('Auto-created — concern follow-up'),
      isAcknowledged: const Value(false),
      createdAt: now,
      cadenceDays: Value(cadenceDays),
    ));
  });
}
```

### FriendRepository.clearConcern change

```dart
Future<void> clearConcern(String id) async {
  final friend = await findById(id);
  if (friend == null) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  final concernEvent = await db.eventDao.findConcernCadenceByFriendId(id);
  await db.transaction(() async {
    await db.friendDao.updateFriend(_toEncryptedCompanion(friend.copyWith(
      isConcernActive: false,
      concernNote: const Value(null),
      updatedAt: now,
    )));
    if (concernEvent != null) {
      await db.eventDao.deleteEvent(concernEvent.id);
    }
  });
}
```

### Existing Tests Compatibility

The Story 2.9 tests in `friend_repository_test.dart` call `setConcern` without `cadenceDays`. They will still pass since:
1. `cadenceDays` defaults to 7 — old calls are backward compatible
2. The 2.9 tests only check friend state (isConcernActive, concernNote), not events
3. `clearConcern` test sets then clears — now also deletes the auto-cadence, but test doesn't check events

### Existing Files to Modify

| File | Change |
|------|--------|
| `spetaka/lib/core/database/daos/event_dao.dart` | Add `findConcernCadenceByFriendId` method |
| `spetaka/lib/features/friends/data/friend_repository.dart` | Modify `setConcern`/`clearConcern` for atomicity + auto-cadence |
| `spetaka/lib/features/friends/presentation/friend_card_screen.dart` | Read `concernCadenceProvider` in `_handleSetConcern`, pass to `setConcern` |
| `spetaka/test/repositories/friend_repository_test.dart` | Add Story 9.1 test group |

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 9, Story 9.1 acceptance criteria]
- [Source: _bmad-output/planning-artifacts/prd.md — FR21: auto concern follow-up cadence]
- [Source: _bmad-output/implementation-artifacts/9-2-configurable-concern-cadence-interval-in-settings.md — provider contract]
- [Source: spetaka/lib/features/friends/data/friend_repository.dart — existing setConcern/clearConcern]
- [Source: spetaka/lib/core/database/daos/event_dao.dart — EventDao methods]
- [Source: spetaka/lib/core/database/app_database.dart — Drift transaction API + event type seeds]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- 2026-03-27: `flutter analyze --no-pub lib/core/database/daos/event_dao.dart lib/features/friends/data/friend_repository.dart lib/features/friends/presentation/friend_card_screen.dart` → clean (0 issues after fixing trailing comma and import ordering).
- 2026-03-27: `flutter test test/repositories/friend_repository_test.dart` → 25/25 passed (19 pre-existing + 6 new Story 9.1 tests).
- 2026-03-27: `flutter test test/unit/ test/repositories/` → 320 passed, 3 pre-existing failures in `app_shell_theme_test.dart` (router routes) and 1 in `model_manager_test.dart` (cancel token) — unrelated to this story.

### Completion Notes List

- Added `EventDao.findConcernCadenceByFriendId(String friendId)` — Drift query filtering by `friendId` AND `comment = 'Auto-created — concern follow-up'`, returns `Event?`.
- Modified `FriendRepository.setConcern()` — added `int cadenceDays = 7` parameter; now wraps friend flag update + event insert in `db.transaction()` for atomicity. Event: type='Prendre des nouvelles', is_recurring=true, cadence_days=cadenceDays, comment='Auto-created — concern follow-up'.
- Modified `FriendRepository.clearConcern()` — now wraps friend flag clear + optional event deletion in `db.transaction()`. Finds and deletes the auto-cadence via `findConcernCadenceByFriendId`; safe no-op if none exists.
- Updated `FriendCardScreen._handleSetConcern()` — reads `concernCadenceProvider` via `ref.read()` and passes cadenceDays to `setConcern()`. Import added: `concern_cadence_provider.dart`.
- Added 6 new tests to `friend_repository_test.dart` (Story 9.1 group): default cadenceDays=7, custom cadenceDays=14, atomicity check, clearConcern deletes cadence, clearConcern leaves other events, clearConcern safe with no auto-cadence.

## File List

- `spetaka/lib/core/database/daos/event_dao.dart` — added `findConcernCadenceByFriendId`
- `spetaka/lib/features/friends/data/friend_repository.dart` — modified `setConcern`/`clearConcern`; added constants + uuid import
- `spetaka/lib/features/friends/presentation/friend_card_screen.dart` — updated `_handleSetConcern` to read/pass cadenceDays; added import
- `spetaka/test/repositories/friend_repository_test.dart` — added Story 9.1 test group (6 tests)

## Change Log

| Date | Change |
|------|--------|
| 2026-03-27 | Story file created; status set to in-progress |
| 2026-03-27 | Implementation complete; all 6 Story 9.1 tests pass; status set to done |
