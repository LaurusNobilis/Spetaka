# Story 3.1: Add a Dated Event to a Friend Card

Status: ready-for-dev

## Story
As Laurus, I want to add a dated event to a friend card so Spetaka can surface important dates at the right time.

## Acceptance Criteria
1. `events` table supports required columns for dated events (`id`, `friend_id`, `type`, `date`, `is_recurring`, `comment`, `is_acknowledged`, `acknowledged_at`, `created_at`).
2. Add-event flow from `FriendCardScreen` saves with UUID v4 and `is_recurring=false`.
3. Event list shows type, formatted date, optional comment.
4. Event type selector includes the 5 default types.
5. Date picker respects 48x48dp touch targets.

## Tasks
- [ ] Create/verify `events` schema and repository mapping.
- [ ] Build add-dated-event UI flow.
- [ ] Render event list row with formatted fields.
- [ ] Add tests for create/persist/read event path.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.1)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
