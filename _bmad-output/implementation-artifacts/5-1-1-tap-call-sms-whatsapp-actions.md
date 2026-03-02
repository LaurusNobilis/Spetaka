# Story 5.1: 1-Tap Call, SMS & WhatsApp Actions

Status: done

> Tracking key in sprint status / filename: `5-1-1-tap-call-sms-whatsapp-actions`.

## Story

As Laurus,
I want to initiate a phone call, SMS, or WhatsApp message from a friend's card with a single tap,
so that the friction between “I should reach out” and actually doing it is eliminated entirely.

## Scope / Non-goals

### In scope

- Action buttons available from:
	- Daily view inline-expanded card (Story 4.6 implementation lives in `spetaka/lib/features/daily/presentation/daily_view_screen.dart`)
	- Friend card details screen (`spetaka/lib/features/friends/presentation/friend_card_screen.dart`)

### Explicit non-goals

- No app-return detection or acquittement auto-trigger (Story 5.2)
- No acquittement sheet (Story 5.3)
- No contact history rendering (Story 5.4)

## Acceptance Criteria

1. **Entry points (UI):** Call/SMS/WhatsApp action buttons are available on:
	 - the inline-expanded daily view card (already present as `_ExpandedContent` actions)
	 - `FriendCardScreen` action row (currently placeholders with `onPressed: null`)
2. **Single gateway:** Widgets do **not** call `url_launcher` directly. All actions go through `ContactActionService` in `spetaka/lib/core/actions/contact_action_service.dart`.
3. **Normalization:** `ContactActionService` normalizes phone numbers via `PhoneNormalizer.normalize()` to E.164 before launching.
4. **Intents:** The launched URIs are:
	 - call: `tel:+E164`
	 - SMS: `sms:+E164`
	 - WhatsApp: `https://wa.me/<digitsOnly>` (E.164 digits without `+`)
5. **Fast launch (NFR3):** On a typical device, tapping an action launches the target app within 500ms. (This is a performance constraint; verify manually with a real device + debug logging, not a brittle automated test.)
6. **Failure UX (safe + inline):** If launching fails (e.g., WhatsApp not installed) or the number is invalid, the UI shows a safe, user-readable message derived from `spetaka/lib/core/errors/error_messages.dart`:
	 - No crash
	 - No raw phone number echoed in UI/logs
	 - Message is shown inline near the action row (not a modal)
7. **Pending friend ID recorded:** When an external intent is launched successfully, `AppLifecycleService.setPendingFriendId(friendId)` is called so Story 5.2 can detect the return flow. If launch fails, pending state is cleared/rolled back.
	 - Note: action type capture is handled in Story 5.2+ (current `AppLifecycleService` stores friendId only).
8. **Accessibility (NFR15/NFR17):** Action buttons meet minimum 48×48dp touch targets and have TalkBack-readable semantics.

## Repo Reality Check (what already exists)

- `ContactActionService` already exists and already:
	- normalizes via `PhoneNormalizer`
	- launches via `url_launcher`
	- records pending friendId via `AppLifecycleService`
	- throws typed `AppError` variants on failure (`PhoneNormalizationAppError`, `ContactActionFailedAppError`)
- Daily view already renders action buttons and calls `actionService.call/sms/whatsapp(...)`, but it currently passes a synchronous callback and does not handle async failures. Without hardening, failures can surface as unhandled async errors.
- `FriendCardScreen` action row is still placeholder (`onPressed: null`) and must be wired.

## Tasks / Subtasks

- [x] Wire **FriendCardScreen** action row to `ContactActionService` (AC: 1, 2, 3, 4, 8)
	- [x] Replace placeholder `_ActionButtonRow` in `spetaka/lib/features/friends/presentation/friend_card_screen.dart` so buttons are enabled
	- [x] Fetch service via Riverpod (`ref.read(contactActionServiceProvider)`) and call `call/sms/whatsapp(friend.mobile, friendId: friend.id)`
	- [x] Add TalkBack semantics + ensure min tap size (48×48dp)

- [x] Add **inline error handling** for action failures in both entry points (AC: 6)
	- [x] Catch `AppError` and convert to message via `errorMessageFor(e)`
	- [x] Render the message inline near the action row (e.g., a small `Text` styled as secondary/error)
	- [x] Clear the message on next successful action tap, and/or when the card collapses/navigates
	- [x] Do not expose PII (no raw numbers)

- [x] Harden daily view callbacks so async errors are handled (AC: 6)
	- [x] Current `_ActionButton` takes a `VoidCallback`, so you cannot `await` directly.
	- [x] Choose one:
		- [x] Option A (preferred): change `_ActionButton` to accept `Future<void> Function()` and internally `await` with try/catch
		- [ ] Option B: keep `VoidCallback` but attach `.catchError(...)`/`then(...)` and route errors into local UI state
	- [x] Ensure no unhandled async exceptions occur on launch failures

- [x] Tests: add focused unit/widget coverage (AC: 2, 3, 4, 6, 7)
	- [x] Unit: `spetaka/test/unit/contact_action_service_test.dart`
		- [x] Call builds `tel:` URI and rolls back pending friend on failure
		- [x] SMS builds `sms:` URI
		- [x] WhatsApp builds `https://wa.me/` URI with digits-only
		- [x] Invalid number throws `PhoneNormalizationAppError` and does not set pending friendId
	- [x] Widget (minimal): verify tapping an action button shows an inline error message when `ContactActionService` throws `ContactActionFailedAppError`

## Dev Notes

### Architecture guardrails (must follow)

- Only `ContactActionService` may call `url_launcher` (see `spetaka/lib/core/core.dart` guardrail comment).
- Only `AppLifecycleService` may use `WidgetsBindingObserver`.
- Use typed `AppError` + `errorMessageFor(...)` for user-visible messaging.

### UX guardrails (do not expand scope)

- No new screens.
- No new navigation.
- Error feedback is inline and calm.

### Regression risks to explicitly avoid

- Daily view action taps throwing unhandled async errors (must be caught and surfaced safely).
- Any code path that logs raw phone numbers.
- Bypassing `ContactActionService` and calling `launchUrl` from a widget.

## References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5, Story 5.1
- Source: `_bmad-output/planning-artifacts/architecture.md` — sections “URL Launcher / Action Intents”, “Phone number normalization”, “AppLifecycle Detection Pattern”
- Implementation anchors:
	- `spetaka/lib/core/actions/contact_action_service.dart`
	- `spetaka/lib/core/actions/phone_normalizer.dart`
	- `spetaka/lib/core/lifecycle/app_lifecycle_service.dart`
	- `spetaka/lib/features/daily/presentation/daily_view_screen.dart`
	- `spetaka/lib/features/friends/presentation/friend_card_screen.dart`

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Implementation Plan

1. **FriendCardScreen** (`friend_card_screen.dart`): Converted `_ActionButtonRow` from `StatelessWidget` placeholder to `ConsumerStatefulWidget`. Added `mobile` parameter. Injected `contactActionServiceProvider` via `ref`. Each button calls `_handleCall/Sms/WhatsApp()` which awaits the service, catches `AppError`, and sets `_actionError` state. Error text rendered inline below the button row with `Key('action_error_text')`. The inner `_ActionButton` was converted to `StatefulWidget` with `Future<void> Function()` onPressed type and a `_busy` guard to avoid concurrent taps. Added `Semantics` wrapper and `ConstrainedBox(minHeight: 48)` for AC8.
2. **DailyViewScreen** (`daily_view_screen.dart`): Converted `_ExpandedContent` from `StatelessWidget` to `StatefulWidget` with `String? _actionError` state. Added `_handleCall/Sms/WhatsApp()` async handlers. Buttons now reference these handlers (Option A). Error text shown inline below the action row with `Key('action_error_text')`. `_ActionButton` converted to `StatefulWidget` with `Future<void> Function()` onPressed, `_busy` guarding against concurrent presses and properly awaiting to prevent unhandled async exceptions.
3. **Unit tests** (`contact_action_service_test.dart`): 12 tests covering URI construction for all three action types, pending-friendId lifecycle (set on success, rolled back on failure), and `PhoneNormalizationAppError` on invalid input. Uses `_FakeUrlLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform`.
4. **Widget tests** (`friend_card_screen_test.dart`): 5 new Story 5.1 tests: buttons enabled (not null), inline error for call/sms/whatsapp failures, and 48dp touch target.

### Completion Notes

- All 4 tasks and their subtasks implemented and verified
- All tests pass locally (unit + widget)
- No regressions
- All ACs satisfied: action buttons wired on both entry points (AC1), single `ContactActionService` gateway (AC2), E.164 normalization via `PhoneNormalizer` (AC3), correct URIs (AC4), async errors caught inline (AC6), pending friendId set/rolled back (AC7), 48dp touch targets + Semantics labels (AC8)
- AC5 (500ms launch performance) is a manual/device test — not automated per story guidance

## File List

- spetaka/lib/features/friends/presentation/friend_card_screen.dart (modified)
- spetaka/lib/features/daily/presentation/daily_view_screen.dart (modified)
- spetaka/lib/core/actions/contact_action_service.dart (modified)
- spetaka/test/unit/contact_action_service_test.dart (created)
- spetaka/test/widget/friend_card_screen_test.dart (modified)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)
- _bmad-output/implementation-artifacts/5-1-1-tap-call-sms-whatsapp-actions.md (modified)

## Change Log

- 2026-03-02: Implemented Story 5.1 — 1-Tap Call/SMS/WhatsApp actions. Wired FriendCardScreen action row to ContactActionService, hardened DailyView async callbacks, added inline error handling on both entry points, added unit + widget test coverage. All tests green.
- 2026-03-02: Senior code review fixes — ContactActionService now rolls back pending friend ID even if `url_launcher` throws; unit tests restore UrlLauncher platform singleton between tests; daily view and friend card show a safe inline fallback message on unexpected errors.

## Senior Developer Review (AI)

**Outcome:** Approved (changes applied)

### Findings (and fixes applied)

- **HIGH:** `ContactActionService` rollback only happened when `launchUrl` returned `false` (not when it threw). Fixed by making launch failure handling exception-safe and always rolling back pending friend state on any launch failure.
- **HIGH:** UI handlers only caught `AppError`; a platform exception could crash on tap. Fixed by adding a safe fallback catch to display an inline message without crashing.
- **MEDIUM:** Unit tests replaced `UrlLauncherPlatform.instance` without restoring it. Fixed by capturing/restoring the previous instance in `tearDown()` and adding a regression test for “launchUrl throws”.

### Notes

- No PII is echoed in user-visible error strings.
- Performance constraint (NFR3 / 500ms) remains a manual validation as specified.

### Handoff (5-1 → 5-2)

This story establishes the “leave app → return → acquittement” contract.

- Single gateway: All call/SMS/WhatsApp launches MUST go through `ContactActionService`.
- Pending state set on successful launch:
	- `ContactActionService` records legacy `AppLifecycleService.setPendingFriendId(friendId)`.
	- It also records rich state via `AppLifecycleService.setActionState(PendingActionState(...))`:
		- `friendId`: targeted friend
		- `origin`: `AcquittementOrigin.dailyView` or `AcquittementOrigin.friendCard`
		- `actionType`: one of `call` / `sms` / `whatsapp`
		- `timestamp`: `DateTime.now()` (drives 30-min expiry)
- Rollback on failure: if `url_launcher` fails/throws, `ContactActionService` clears both pending states (`setPendingFriendId(null)` + `setActionState(null)`).
- Consumer expectations (5-2/5-3): on app resume, `AppLifecycleService.pendingActionStream` emits the non-expired `PendingActionState`; the acquittement sheet should open and call `AppLifecycleService.clearActionState()` immediately on open.
