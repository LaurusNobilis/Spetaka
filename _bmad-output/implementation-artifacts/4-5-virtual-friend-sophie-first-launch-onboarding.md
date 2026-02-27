# Story 4.5: Virtual Friend "Sophie" — First Launch Onboarding

Status: ready-for-dev

## Story
As a new user, I want a demo friend on first launch so I can understand the full loop before adding real contacts.

## Acceptance Criteria
1. First launch with no friends seeds demo friend `Sophie` with upcoming important event.
2. Demo friend is marked with `is_demo=true` and visible indicator.
3. Welcome greeting references Sophie flow.
4. Sophie persists until explicit removal after first real friend creation.
5. Drift migration adds `is_demo` column safely.
6. Demo data is excluded from priority scoring for real friends.

## Tasks
- [ ] Add `is_demo` migration and model updates.
- [ ] Implement first-launch seed logic for Sophie.
- [ ] Add remove-Sophie control and lifecycle behavior.
- [ ] Exclude demo entities from ranking pipeline.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.5)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
