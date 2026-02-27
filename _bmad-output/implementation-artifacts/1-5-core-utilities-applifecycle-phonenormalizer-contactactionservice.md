# Story 1.5: Core Utilities — AppLifecycle, PhoneNormalizer & ContactActionService

Status: ready-for-dev

## Story

As a developer,
I want the three critical cross-cutting utilities built and tested as isolated services,
so that actions, acquittement, and friend features can rely on proven, consistent behavior without duplicating logic.

## Acceptance Criteria

1. `lib/core/lifecycle/app_lifecycle_service.dart` observes `AppLifecycleState.resumed` and exposes `Stream<String?> pendingAcquittementFriendId` via provider.
2. `lib/core/actions/phone_normalizer.dart` provides `normalize(String raw) -> String` to E.164 and returns typed `AppError` for invalid inputs.
3. `lib/core/actions/contact_action_service.dart` exposes `call`, `sms`, `whatsapp`; each normalizes and triggers proper `url_launcher` intents.
4. `lib/core/errors/app_error.dart` defines typed error hierarchy and `lib/core/errors/error_messages.dart` stores user-facing messages.
5. `flutter test test/unit/phone_normalizer_test.dart` passes with expected samples (`0612345678` -> `+33612345678`, unchanged E.164, invalid letters-only).

## Tasks / Subtasks

- [ ] Implement lifecycle service (AC: 1)
  - [ ] Create lifecycle observer abstraction and provider
  - [ ] Expose pending acquittement stream
- [ ] Implement phone normalization utility (AC: 2, 5)
  - [ ] Build E.164 normalization logic
  - [ ] Add typed errors for invalid inputs
  - [ ] Add unit tests
- [ ] Implement contact action service (AC: 3)
  - [ ] Add call/sms/whatsapp methods
  - [ ] Route all launches through centralized service
- [ ] Standardize error model/messages (AC: 4)
  - [ ] Define app error hierarchy
  - [ ] Map user-visible messages centrally

## Dev Notes

- Keep `url_launcher` usage out of widgets; only service layer may call it.
- `PhoneNormalizer` must be reused by future contact import and WhatsApp flows.
- Lifecycle hooks here unblock post-action acquittement automation later.

### Project Structure Notes

- Utilities under `lib/core/actions/` and `lib/core/lifecycle/`.
- Error contracts under `lib/core/errors/`.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.5.
- Source: `_bmad-output/planning-artifacts/architecture.md` — lifecycle/action service constraints.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- Story generated in yolo batch progression for Epic 1.

### Completion Notes List

- Story 1.5 prepared with explicit service boundaries and test targets.

### File List

- _bmad-output/implementation-artifacts/1-5-core-utilities-applifecycle-phonenormalizer-contactactionservice.md
