# Story 2.3: Category Tags Assignment

Status: ready-for-dev

## Story

As Laurus,
I want to assign one or more category tags to a friend card (e.g., Family, Work),
so that relationships are organized and later weighted by category.

## Acceptance Criteria

1. Tag selector exposes at least: Family, Close friends, Friends, Work, Other.
2. Multi-select is supported and each tag control meets 48×48dp minimum target (NFR15).

- **Storage:** `friends.tags` is plaintext (NOT encrypted). Narrative fields only are encrypted at repository layer (Story 1.7).
- **Serialization (recommended for v1):** JSON array string (deterministic ordering).
- **Predefined tags only** in this story. No add/rename/reorder UI.

## Scope note
- “Edit friend” wiring (opening the form in edit mode, prefill, update) is owned by Story 2.7, but the tag selector implementation here should be reusable in edit mode.

## Tasks / Subtasks

### A) Drift schema + migration (AC: 3)

- [ ] Add `tags` column to Drift table `Friends`
	- File: `spetaka/lib/features/friends/domain/friend.dart`
	- Suggested column: `TextColumn get tags => text().nullable()();`

- [ ] Migrate database for the new column
	- File: `spetaka/lib/core/database/app_database.dart`
	- Increment `schemaVersion` (currently `2`).
	- Add an `onUpgrade` step that runs when upgrading from older versions.
		- Example intent: if `from < 3` then `m.addColumn(friends, friends.tags)`.
	- Files (tests):
		- `spetaka/test/repositories/friend_repository_test.dart`
		- `spetaka/test/repositories/field_encryption_test.dart`
		- `spetaka/test/widget/friend_form_screen_test.dart`
	- Default: `tags: null` unless the test is explicitly about tags.

### B) Repository updates (AC: 3)

- [ ] Update `FriendRepository` to round-trip tags
	- File: `spetaka/lib/features/friends/data/friend_repository.dart`
	- Ensure `_toEncryptedCompanion(...)` passes `tags` through unchanged.
	- Ensure `_decryptRow(...)` only decrypts `notes` and `concernNote`.
	- Add a small encode/decode helper (single source of truth) so UI never parses ad-hoc.
		- Suggested location: `spetaka/lib/features/friends/domain/friend_tags_codec.dart`
		- Suggested API:
			- `const predefinedFriendTags = <String>[...]` (canonical order)
			- `String? encodeFriendTags(Set<String> tags)` (returns `null` when empty)
			- `List<String> decodeFriendTags(String? raw)` (empty list when `null`)
		- Robustness guardrail: `decodeFriendTags` must not throw on invalid/corrupted stored values; treat as empty list and optionally report via `FlutterError.reportError`.

- [ ] Export the codec from the feature barrel (optional but keeps imports consistent)
	- File: `spetaka/lib/features/features.dart`
	- Add: `export 'friends/domain/friend_tags_codec.dart';`

### C) Friend form: tag selector UI (AC: 1, 2)

- [ ] Extend `FriendFormScreen` to select tags during creation
	- File: `spetaka/lib/features/friends/presentation/friend_form_screen.dart`
	- Use multi-select chips (e.g. `FilterChip`) laid out with `Wrap`.
	- Store selection as a `Set<String>` in widget state.
	- On Save, encode the selected tags using the shared codec helper and pass the encoded value into the new `Friend(tags: ...)` field.
	- Enforce NFR15:
		- Avoid `MaterialTapTargetSize.shrinkWrap`.
		- Ensure chips have enough padding/constraints to reach 48dp minimum.
	- Accessibility:
		- Wrap the chip group with `Semantics(label: 'Category tags')`.
		- Provide per-chip semantics labels like `Tag: Family, selected`.

### D) Display: chips in list + detail (AC: 4)

- [ ] Friends list: render selected tags as chips
	- File: `spetaka/lib/features/friends/presentation/friends_list_screen.dart`
	- Keep PII safe: never show phone numbers here.
	- If a dedicated `FriendCardTile` widget exists later (Story 2.5), the chips rendering can move there.

- [ ] Friend detail: render a tags section
	- Current placeholder screen lives in: `spetaka/lib/core/router/app_router.dart` (will be owned by Story 2.6).
	- Minimal requirement for this story: show a “Tags” section with chips for the current friend record.
	- Keep this forward-compatible (Story 2.6 will flesh out the full detail view).
	- Data-loading (pick the simplest that fits current codebase):
		- Option A (minimal): use `ref.read(friendRepositoryProvider).findById(id)` and a `FutureBuilder`/`Consumer` to render tags once loaded.
		- Option B (cleaner): add `friendByIdProvider` as a `FutureProvider.autoDispose.family<Friend?, String>` and use it in `FriendCardScreen`.

### E) Tests (AC: 2–4)

- [ ] Repository test: tags persist correctly
	- File: `spetaka/test/repositories/friend_repository_test.dart`
	- Insert a friend with two tags → read back → tags decode matches.
	- (Optional) Assert the raw DAO value is plaintext JSON.

- [ ] Widget test: tags UI and chips rendering
	- Location: `spetaka/test/widget/`
	- Select multiple chips → Save → verify chips appear for the friend in `/friends` list.
	- (Optional) Also assert tags chips render on `/friends/:id` (placeholder detail) to cover AC4 end-to-end.

## Dev Notes

### Guardrails (prevent common LLM/dev mistakes)

- Reuse existing layering: Drift DAO → Repository → Riverpod providers → Widgets.
- Do NOT introduce a second “friend model” unless absolutely necessary; the codebase currently uses Drift’s generated `Friend` data class end-to-end.
- Centralize encode/decode for tags; do not duplicate parsing in multiple widgets.
- Tags must remain plaintext (search/sort/category weighting later depends on it).

### Non-goals

- No custom tag creation or management UI.
- No tag-based filtering/search.
- No new screens beyond minimal tags UI in existing friend flows.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.3.
- Source: `_bmad-output/planning-artifacts/architecture.md` — Drift migrations (`schemaVersion` + `MigrationStrategy`), repository→DAO layering, NFR15 touch targets.

## Dev Agent Record

### Agent Model Used

GPT-5.2

### Debug Log References

### Completion Notes List

### File List

<!-- validated: 2026-02-27 -->

- `spetaka/lib/features/friends/domain/friend.dart`
- `spetaka/lib/core/database/app_database.dart`
- `spetaka/lib/features/friends/data/friend_repository.dart`
- `spetaka/lib/features/friends/domain/friend_tags_codec.dart`
- `spetaka/lib/features/friends/presentation/friend_form_screen.dart`
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart`
- `spetaka/lib/core/router/app_router.dart`
- `spetaka/lib/features/features.dart`
- `spetaka/test/repositories/friend_repository_test.dart`
- `spetaka/test/repositories/field_encryption_test.dart`
- `spetaka/test/widget/friend_form_screen_test.dart`
