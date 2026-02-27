# Story 5.1: 1-Tap Call, SMS & WhatsApp Actions

Status: ready-for-dev

## Story
As Laurus, I want one-tap contact actions so intention turns into action with minimal friction.

## Acceptance Criteria
1. Action buttons are available on expanded daily card and `FriendCardScreen`.
2. `ContactActionService` launches `tel:`, `sms:`, `wa.me` intents after E.164 normalization.
3. Launch target is <=500ms.
4. Missing WhatsApp or invalid numbers produce safe inline errors.
5. Action triggers store pending friend/action in lifecycle service.
6. Buttons meet accessibility/touch target constraints.

## Tasks
- [ ] Wire action buttons to service.
- [ ] Implement intent launch + error handling.
- [ ] Persist pending action context for return flow.
- [ ] Add behavior tests for success/failure branches.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.1)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
