# Story 1.5: Core Utilities — AppLifecycle, PhoneNormalizer & ContactActionService

Status: done

## Story

As a developer,
I want the three critical cross-cutting utilities built and tested as isolated services,
so that actions, acquittement, and friend features can rely on proven, consistent behavior without duplicating logic.

## Acceptance Criteria

1. **AppLifecycleService (core lifecycle, no widget observers):**
   - `lib/core/lifecycle/app_lifecycle_service.dart` exists and is the *only* place where `WidgetsBindingObserver` is used for app lifecycle.
   - The service observes `AppLifecycleState.resumed` and exposes a Riverpod-provided `Stream<String?> pendingAcquittementFriendId`.
   - A Riverpod provider exists for the service and must be annotated with `@Riverpod(keepAlive: true)` to avoid losing pending state.

2. **PhoneNormalizer (single source of truth):**
   - `lib/core/actions/phone_normalizer.dart` exposes `String normalize(String raw)`.
   - The output is E.164 formatted (starts with `+` and contains digits only after the plus).
   - For invalid/unparseable input, it throws a typed `AppError` (extend existing `lib/core/errors/app_error.dart`; do not create a second error system).

3. **ContactActionService (single url_launcher gateway):**
   - `lib/core/actions/contact_action_service.dart` exposes `call`, `sms`, `whatsapp` methods.
   - Each method normalizes via `PhoneNormalizer` and triggers the correct `url_launcher` intent:
     - Call: `tel:+XXXXXXXXXXX`
     - SMS: `sms:+XXXXXXXXXXX`
     - WhatsApp: `https://wa.me/XXXXXXXXXXX` (digits only, no leading `+`)
   - Widgets/features must not call `url_launcher` directly; only this service may.

4. **Errors & user-facing messages are centralized:**
   - Typed domain errors remain in `lib/core/errors/app_error.dart`.
   - User-facing strings remain in `lib/core/errors/error_messages.dart` (update mapping for any new error types).
   - No raw exception messages are surfaced to the UI layer.

5. **Tests are executable and deterministic:**
   - `flutter test test/unit/phone_normalizer_test.dart` passes with at least:
     - `0612345678` → `+33612345678`
     - `+33612345678` unchanged
     - Letters-only input throws a typed `AppError`

## Tasks / Subtasks

- [x] Implement AppLifecycleService (AC: 1)
  - [x] Create `lib/core/lifecycle/app_lifecycle_service.dart` implementing `WidgetsBindingObserver` internally
  - [x] Expose `Stream<String?> pendingAcquittementFriendId`
  - [x] Add Riverpod provider `appLifecycleServiceProvider` with `@Riverpod(keepAlive: true)` and proper `ref.onDispose` cleanup

- [x] Implement PhoneNormalizer (AC: 2, 5)
  - [x] Create `lib/core/actions/phone_normalizer.dart` with `normalize(String raw)`
  - [x] Define validation rules and throw typed `AppError` on invalid input (extend existing error hierarchy)
  - [x] Add unit tests in `test/unit/phone_normalizer_test.dart`

- [x] Implement ContactActionService (AC: 3)
  - [x] Create `lib/core/actions/contact_action_service.dart`
  - [x] Expose `call`, `sms`, `whatsapp` and route all launches through `url_launcher.launchUrl`
  - [x] Normalize via `PhoneNormalizer` and map launch failures to typed `AppError`

- [x] Wire barrels and exports
  - [x] Update `spetaka/lib/core/core.dart` to export the new services/utilities as appropriate

## Dev Notes

### Critical guardrails (disaster prevention)

- Do **not** reinvent errors: `lib/core/errors/app_error.dart` and `lib/core/errors/error_messages.dart` already exist (Story 1.3). Extend them.
- Keep `url_launcher` usage out of widgets; only `ContactActionService` may call it.
- `PhoneNormalizer` is the *only* normalization entrypoint. No per-feature formatting/parsing.
- Only `AppLifecycleService` may use `WidgetsBindingObserver`. Feature widgets must subscribe via provider.

### Implementation clarifications (to avoid future refactors)

- This story is a hard dependency for Epic 5 (actions + acquittement loop):
  - `ContactActionService` will be called from friend-context UI (daily view expanded card / friend card screen).
  - `AppLifecycleService` is expected to support a “pending acquittement” concept that is emitted on resume.
- Prefer keeping `ContactActionService` signatures friend-aware from day 1 (e.g. accept `friendId` alongside `rawNumber`) so Story 5.2 can wire the return-trigger without retrofitting.

### Phone normalization scope (v1)

- Tests indicate France-local input (`06...`) must normalize to `+33...`.
- Keep behavior deterministic and explicit. If true multi-region support is desired later, introduce it as a dedicated story + dependency (avoid silent heuristics).

### Project Structure Notes

- Utilities under `lib/core/actions/` and `lib/core/lifecycle/`.
- Error contracts under `lib/core/errors/`.

### Library Notes

- `url_launcher: ^6.3.1` is already present in `pubspec.yaml`.
- Avoid adding new phone parsing dependencies unless absolutely required; if you do, update this story explicitly with package + rationale.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.5.
- Source: `_bmad-output/planning-artifacts/architecture.md` — lifecycle/action service constraints.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- Story 1.5 validated against `_bmad-output/planning-artifacts/epics.md`, `_bmad-output/planning-artifacts/architecture.md`, and current repo state (existing core errors, Riverpod annotation style).
- Extended sealed `AppError` hierarchy: `PhoneNormalizationAppError`, `ContactActionFailedAppError` — no new error system created.
- `dispose()` made idempotent (guards `_controller.isClosed`) to prevent double-close in test lifecycle.
- `dart:async` import removed from test (re-exported by `flutter_test`); `directives_ordering` fixed in `core.dart` by sorting exports alphabetically in a single block.

### Completion Notes List

- **AC1 ✅** `AppLifecycleService` with `WidgetsBindingObserver`, broadcast stream, `setPendingFriendId`/`currentPendingFriendId`, `@Riverpod(keepAlive: true)` provider with `ref.onDispose`.
- **AC2 ✅** `PhoneNormalizer.normalize()`: strips visual separators, rejects illegal chars, normalises FR local (`06...` → `+33...`), passes through existing E.164, throws `PhoneNormalizationAppError`.
- **AC3 ✅** `ContactActionService`: `call`/`sms`/`whatsapp` methods, `url_launcher` gateway, pending-friend-ID rollback on launch failure, friend-aware signatures (Story 5.2 ready).
- **AC4 ✅** `PhoneNormalizationAppError` + `ContactActionFailedAppError` added to `app_error.dart`; `error_messages.dart` exhaustive switch extended; no second error system.
- **AC5 ✅** 14 `phone_normalizer_test.dart` tests including all 3 mandatory AC5 cases; 11 `core_utilities_test.dart` tests (AppLifecycleService + provider + error messages).
- 94/94 tests green; `flutter analyze` clean.

### File List

- spetaka/lib/core/actions/contact_action_service.dart (new)
- spetaka/lib/core/actions/contact_action_service.g.dart (generated)
- spetaka/lib/core/actions/phone_normalizer.dart (new)
- spetaka/lib/core/errors/app_error.dart (modified — added PhoneNormalizationAppError, ContactActionFailedAppError)
- spetaka/lib/core/errors/error_messages.dart (modified — extended switch with new error types)
- spetaka/lib/core/lifecycle/app_lifecycle_service.dart (new)
- spetaka/lib/core/lifecycle/app_lifecycle_service.g.dart (generated)
- spetaka/lib/core/core.dart (modified — alphabetically sorted exports, added actions + lifecycle)
- spetaka/lib/core/encryption/encryption_service.dart (modified — lifecycle observer centralized via AppLifecycleService)
- spetaka/lib/core/encryption/encryption_service_provider.dart (modified — inject AppLifecycleService)
- spetaka/test/unit/phone_normalizer_test.dart (new)
- spetaka/test/unit/core_utilities_test.dart (new)
- spetaka/test/unit/encryption_service_test.dart (modified — inject AppLifecycleService)
- _bmad-output/implementation-artifacts/1-5-core-utilities-applifecycle-phonenormalizer-contactactionservice.md (this file)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)

## Senior Developer Review (AI)

Date: 2026-02-27
Outcome: Approved (changes applied)

### Findings

**HIGH** — Architecture/AC violation: `WidgetsBindingObserver` was used outside `AppLifecycleService`.
- Evidence: `lib/core/encryption/encryption_service.dart` implemented `WidgetsBindingObserver` (Story 1.3 legacy TODO).
- Risk: Violates AC1 / architecture guardrail (single lifecycle observer), increases lifecycle side-effects and makes reasoning harder.
- Fix applied: Centralized lifecycle events in `AppLifecycleService` (`lifecycleStates` stream) and refactored `EncryptionService` to subscribe instead of observing.

**MEDIUM** — Potential PII leak in error reasons.
- Evidence: `PhoneNormalizer` embedded raw digits in `PhoneNormalizationAppError.reason` for some cases.
- Risk: Error reasons may end up in logs/debug output; phone numbers are sensitive.
- Fix applied: Replaced reasons with non-PII stable codes (`invalid_characters`, `misplaced_plus`, `unrecognized_format`).

**MEDIUM** — External action launch mode not forced.
- Evidence: `launchUrl(uri)` used with default mode; `https://wa.me/...` may open in a webview/browser rather than the target app.
- Fix applied: Use `LaunchMode.externalApplication` for `tel:`, `sms:`, and `wa.me` launches.

### Verification

- `flutter analyze` clean.
- `flutter test` green (94/94).

## Change Log

- 2026-02-27: Story 1.5 implemented — AppLifecycleService, PhoneNormalizer, ContactActionService; 25 new tests; 94/94 green; flutter analyze clean → review
- 2026-02-27: Code review fixes applied — centralize lifecycle observer; prevent PII in phone errors; force external launch mode; tests updated → done
