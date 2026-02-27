# Story 4.4: Coach-Tone Greeting Line & Density Control

Status: ready-for-dev

## Story
As Laurus, I want a warm greeting and one-tap density toggle so daily ritual stays human and adjustable.

## Acceptance Criteria
1. Greeting line in Lora adapts to context (0/1/2+ surfaced, concern present, time of day, user name).
2. Tone is always encouraging and non-punitive.
3. Density toggle supports compact vs expanded daily list.
4. Density preference persists via `shared_preferences`.
5. Widget tests validate greeting rendering and toggle effect.

## Tasks
- [ ] Implement greeting copy generator with context variants.
- [ ] Build density toggle and list-size behavior.
- [ ] Persist/restore density preference.
- [ ] Add widget tests.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.4)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
