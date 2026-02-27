# Story 5.3: Acquittement Sheet — Type, Note & One-Tap Confirm

Status: ready-for-dev

## Story
As Laurus, I want a warm one-tap acquittement sheet so contact logging is fast and humane.

## Acceptance Criteria
1. `acquittements` table schema exists with required fields and UUID ids.
2. Sheet pre-fills action type and current timestamp.
3. User can adjust action type; note field stays optional.
4. Confirm path is one-tap and saves acquittement.
5. Subtle warm confirmation and gentle next-action prompt are shown.

## Tasks
- [ ] Build bottom sheet UI + prefill behavior.
- [ ] Persist acquittement record.
- [ ] Add type selector + optional note behavior.
- [ ] Implement post-confirm micro-feedback.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.3)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
