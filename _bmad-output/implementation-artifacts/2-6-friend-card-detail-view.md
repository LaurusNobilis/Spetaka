# Story 2.6: Friend Card Detail View

Status: ready-for-dev

## Story

As Laurus,
I want to open a friend card to see full details, events, and contact history,
so that I can act with complete context before reaching out.

## Acceptance Criteria

1. `/friends/:id` (`FriendCardScreen`) displays name, formatted mobile, tags, notes, active concern note, events section placeholder, contact history placeholder.
2. Prominent action buttons (Call/SMS/WhatsApp) are visible as placeholders for Epic 5 wiring.
3. Screen opens within 300ms (NFR4).
4. Edit button routes to `FriendFormScreen` in edit mode for current friend.
5. Screen reacts to SQLite updates without manual refresh.

## Tasks / Subtasks

- [ ] Implement `FriendCardScreen` data layout and sections (AC: 1)
- [ ] Add placeholder action row for future integration (AC: 2)
- [ ] Wire edit navigation and friend-id binding (AC: 4)
- [ ] Ensure reactive stream updates + perf check (AC: 3, 5)

## Dev Notes

- Keep placeholder sections explicit for Epic 3 and Epic 5 integration points.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.6.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex
