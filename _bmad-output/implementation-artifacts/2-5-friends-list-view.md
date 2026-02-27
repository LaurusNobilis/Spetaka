# Story 2.5: Friends List View

Status: ready-for-dev

## Story

As Laurus,
I want to see all my friend cards in a browsable list,
so that I can quickly navigate my relational circle.

## Acceptance Criteria

1. `/friends` (`FriendsListScreen`) renders all `friends` entries in a scrollable `FriendCardTile` list.
2. Tile displays friend name, category tags, and concern indicator when active.
3. Data source is reactive Riverpod `StreamProvider` backed by Drift `watchAll()`.
4. Empty state prompts user to add first friend.
5. Open time target is within 300ms on primary device (NFR4).
6. TalkBack navigation is supported with meaningful tile descriptions (NFR17).

## Tasks / Subtasks

- [ ] Implement reactive friends list screen and tile composition (AC: 1, 2, 3)
- [ ] Add empty-state UX with add-first-friend CTA (AC: 4)
- [ ] Validate performance target and semantics labels (AC: 5, 6)

## Dev Notes

- Prioritize stream-driven updates; no manual refresh pattern.
- Keep tile semantics concise and informative for accessibility.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.5.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex
