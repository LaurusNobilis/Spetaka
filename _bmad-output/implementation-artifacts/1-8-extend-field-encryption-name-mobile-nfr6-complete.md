# Story 1.8: Extend Field Encryption to `name` and `mobile` (NFR6 Complete)

Status: done

## Context

Story 1.7 established field-level encryption at the repository layer for narrative
fields (`friends.notes`, `friends.concern_note`, `acquittements.note`).

NFR6 states: _"All on-device data is encrypted at rest using AES-256 with a key
derived from the user's passphrase."_

Structural fields `friends.name` and `friends.mobile` are currently stored as
plaintext in SQLite (see `spetaka/lib/features/friends/data/friend_repository.dart`
and `spetaka/lib/features/friends/domain/friend.dart`). An attacker with ADB
access or on a rooted device could read all friend names and phone numbers from
the database file without a passphrase. This story extends the existing
encryption boundary to cover these remaining sensitive structured fields,
completing NFR6 compliance for Phase 1.

## Story

As a developer,
I want `friends.name` and `friends.mobile` encrypted at the repository layer using
the existing `EncryptionService`,
So that NFR6 is fully satisfied — no plaintext personally identifiable data
(name or phone number) is ever written to the SQLite database file.

## Prerequisites / Dependencies

- Story 1.3 done (`EncryptionService` with AES-256-GCM + PBKDF2).
- Story 1.7 done (`FriendRepository` already handles encrypt/decrypt for narrative
  fields — this story follows the same pattern).
- `friends` Drift table exists with `name` and `mobile` columns.

## Acceptance Criteria

1. **Write path — name & mobile encrypted:**
   - **Given** `EncryptionService` has an active in-memory derived key
   - **When** `FriendRepository` calls DAO insert or update
   - **Then** `friends.name` and `friends.mobile` are encrypted via
     `EncryptionService.encrypt()` before reaching the DAO — the DAO only
     ever sees ciphertext for these columns.

2. **Read path — transparent decryption:**
   - **Given** name and mobile are stored as ciphertext in SQLite
   - **When** `FriendRepository` reads records from the DAO
   - **Then** both fields are decrypted via `EncryptionService.decrypt()` before
     returning `Friend` objects to providers or widgets.
   - **And** no widget, provider, or DAO ever receives ciphertext for `name` or
     `mobile`.

3. **Repository-level sort (post-decryption) to keep UX stable:**
   - **Given** `FriendDao.watchAll()` emits an unsorted list today and
     `FriendsListScreen` renders the list in stream order
   - **When** names are stored as ciphertext (so DB-level alphabetical order is
     meaningless)
   - **Then** `FriendRepository.watchAll()` MUST sort the decrypted `Friend`
     objects in-memory before emitting to the UI.
   - **And** `FriendRepository.findAll()` MUST return the list sorted the same
     way, so callers get consistent ordering.
   - **And** sorting is case-insensitive and stable (recommended):
     `list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))`.

4. **ContactActionService unaffected:**
   - **Given** `ContactActionService` calls `PhoneNormalizer` with the mobile number
   - **When** a friend's card provides the mobile value
   - **Then** `ContactActionService` always receives the decrypted plaintext mobile
     number (decrypted at repository layer, transparent to downstream callers).

5. **Manual entry & contact import remain correct (same repository boundary):**
   - **Given** the contact import flow lives in
     `spetaka/lib/features/friends/presentation/friend_form_screen.dart`
     (`_importFromContacts()` pre-fills, then `_saveFriend()` persists)
   - **When** the UI calls `FriendRepository.insert()` / `FriendRepository.update()`
   - **Then** `name` and `mobile` are encrypted inside the repository before any
     DAO write, regardless of whether the values originated from manual entry or
     `flutter_contacts`.

6. **Non-sensitive fields remain plaintext:**
   - `care_score`, `is_concern_active`, `created_at`, `updated_at`, `id`, `tags`,
     `is_demo` — all remain plaintext for query optimization and feature logic.

7. **Typed error propagation consistent with Story 1.7:**
   - Missing key → `EncryptionNotInitializedAppError`
   - Decrypt/auth failure → `DecryptionFailedAppError`
   - Corrupted ciphertext → `CiphertextFormatAppError`
   - Repositories do not swallow errors.

8. **Tests:**
   - `flutter test test/repositories/field_encryption_test.dart` passes with:
     - Write a Friend with `name` and `mobile` → read back via repository →
       plaintext values match originals.
     - Update the existing Story 1.7 test that currently asserts `name` and
       `mobile` are plaintext-at-rest; after Story 1.8, those assertions must
       flip to ciphertext-at-rest.
     - Inspect raw DAO-stored value → confirm stored value is NOT equal to
       original plaintext (ciphertext-at-rest verification).
     - `watchAll()` returns friends sorted alphabetically by decrypted name.
     - Attempt read/write without initialized `EncryptionService` → throws
       `EncryptionNotInitializedAppError`.
   - All existing tests remain green.

9. **Backward compatibility / data migration safety (critical):**
   - **Given** existing dev/test databases may contain legacy rows where
     `friends.name` / `friends.mobile` are still plaintext (pre-Story 1.8)
   - **When** `FriendRepository` reads such rows
   - **Then** the app must NOT brick the Friends list by blindly calling
     `decrypt()` on legacy plaintext.
   - **And** the implementation MUST choose one explicit strategy and test it:
     - **Preferred (safe, minimal schema impact):** detect whether a value is a
       valid ciphertext payload (Base64url + minimum length) before decrypting;
       if not ciphertext, treat as plaintext and (optionally) re-encrypt on the
       next write.
     - **Strict (security-first, breaking):** require a one-time migration step
       that rewrites all existing rows to ciphertext once the key is available;
       app must gate access until migration is complete.

## Tasks / Subtasks

- [x] **Extend `FriendRepository` write path (AC: 1, 5)**
  - [x] In `_toEncryptedCompanion()`, add `name` and `mobile` to the list of
        fields encrypted via `EncryptionService.encrypt()`.
  - [x] Confirm both manual entry and contact import persist via
    `FriendRepository.insert()` / `FriendRepository.update()` (see
    `friend_form_screen.dart`) so there is no plaintext bypass.

- [x] **Extend `FriendRepository` read path (AC: 2, 3)**
  - [x] In `_decryptRow()`, add decryption for `name` and `mobile`.
  - [x] Sort in-memory in `watchAll()` and `findAll()` after decryption.
  - [x] Implement and test the chosen legacy-plaintext strategy (AC: 9).

- [x] **Verify ContactActionService call chain (AC: 4)**
  - [x] Trace call path: `FriendCardScreen` → provider → repository →
        `Friend.mobile` (decrypted) → `ContactActionService` →
        `PhoneNormalizer`. Confirm no extra decryption step is needed
        downstream — it should already be transparent.

- [x] **Update and extend tests (AC: 8)**
  - [x] Extend `test/repositories/field_encryption_test.dart` with:
        - `name` and `mobile` roundtrip tests
        - Ciphertext-at-rest assertions for `name` and `mobile`
        - Alphabetical sort test on `watchAll()`
    - Legacy plaintext compatibility test (if using the preferred strategy)
  - [x] Run full suite: `flutter test` — confirm all green.

## Dev Notes

### Critical Architecture Guardrails

- **Same pattern as Story 1.7 — do not deviate.** Encryption boundary is
  exclusively in `FriendRepository`. DAOs remain encryption-agnostic.
- **Never encrypt `id`, `care_score`, `is_concern_active`, `created_at`,
  `updated_at`, `tags`, `is_demo`.** These fields must remain queryable/sortable
  at DB level for the priority engine and care score operations.
- **In-memory sort is acceptable at Spetaka scale.** The expected data volume is
  tens of friend cards — in-memory sort has zero performance impact.
- **Null handling:** `name` and `mobile` are non-nullable in the schema. No
  null-guard needed for these fields (unlike nullable narrative fields in 1.7).
- **Do not change the ciphertext format** established by Story 1.3:
  `Base64url(iv[12] + tag[16] + ciphertext)`. Changing it would break the
  export/import flow (Epic 6).
- **PhoneNormalizer already receives decrypted values** — the repository layer
  decrypts before returning `Friend` objects. No changes needed to
  `ContactActionService`, `PhoneNormalizer`, or any feature widget.

### Files to Modify (non-exhaustive)

- `spetaka/lib/features/friends/data/friend_repository.dart` — primary change
- `spetaka/test/repositories/field_encryption_test.dart` — extend tests

### Files NOT to Modify

All existing code from completed stories (1.1–1.7, 2.x, 3.x, 4.x) must remain
untouched. This story modifies only the `FriendRepository` encrypt/decrypt helpers
and the corresponding test file.

### References

- Epics: `_bmad-output/planning-artifacts/epics.md` — Story 1.8 acceptance
  criteria block ("Extend Field Encryption to `name` and `mobile`")
- Architecture: `_bmad-output/planning-artifacts/architecture.md` — "Security &
  Encryption" (field-level encryption covers `friends.name` + `friends.mobile`)
- PRD: `_bmad-output/planning-artifacts/prd.md` — NFR6
- Security review: R1 (name + mobile in plaintext identified as gap)
- Prior implementation: Story 1.7 (`friend_repository.dart` — `_toEncryptedCompanion`
  and `_decryptRow` patterns to replicate)

## Dev Agent Record

### Implementation Plan

- Followed the exact Story 1.7 pattern in `FriendRepository`.
- `_toEncryptedCompanion()`: added `encName` and `encMobile` via `EncryptionService.encrypt()` before building the `FriendsCompanion`. Both fields are non-nullable so no null guard is required.
- `_decryptRow()`: added `_decryptOrPlaintext()` for `name` and `mobile` to support AC-9 legacy compatibility; notes/concernNote remain on the existing direct `decrypt()` path (already always encrypted from Story 1.7).
- **Legacy detection strategy (AC-9, Preferred):** `_looksLikeCiphertext(value)` checks length ≥ 40 chars and attempts a `base64Url.decode`; if the decoded payload is ≥ 29 bytes (iv+tag+1) it is treated as ciphertext, otherwise the value is returned as-is. This prevents bricking the Friends list for pre-1.8 rows.
- **In-memory sort (AC-3):** both `watchAll()` and `findAll()` sort the decrypted list case-insensitively after decryption. Sort is stable and has negligible cost at Spetaka scale.
- `dart:convert` import added to `friend_repository.dart` for `base64Url`.
- `ContactActionService` requires no change — `_decryptRow` already returns a fully-decrypted `Friend` object; all downstream callers are unaffected (AC-4 confirmed).

### Completion Notes

- ✅ AC-1: `_toEncryptedCompanion()` encrypts `name` and `mobile` before every DAO insert/update. No plaintext bypass possible via `insert()` or `update()`.
- ✅ AC-2: `_decryptRow()` decrypts `name` and `mobile`; no widget/provider/DAO ever sees ciphertext for these fields.
- ✅ AC-3: `watchAll()` and `findAll()` sort decrypted friends case-insensitively by name. Non-sensitive fields (careScore, tags, id, …) remain plaintext.
- ✅ AC-4: `ContactActionService` is unaffected — receives decrypted mobile transparently.
- ✅ AC-5: All entry points for manual entry and contact import flow through `FriendRepository.insert()` / `FriendRepository.update()` — encryption is always applied.
- ✅ AC-6: Non-sensitive fields (careScore, isConcernActive, tags, id, createdAt, updatedAt, isDemo) remain plaintext.
- ✅ AC-7: Error propagation unchanged — `EncryptionNotInitializedAppError`, `DecryptionFailedAppError`, `CiphertextFormatAppError` propagate as before.
- ✅ AC-8: 10 new tests added in `field_encryption_test.dart` covering roundtrip, ciphertext-at-rest, sort, and legacy compatibility. All 266 tests pass.
- ✅ AC-9: `_looksLikeCiphertext()` / `_decryptOrPlaintext()` implement the preferred strategy; 2 legacy-compatibility tests added and passing.

## File List

- `spetaka/lib/features/friends/data/friend_repository.dart` — modified
- `spetaka/test/repositories/field_encryption_test.dart` — modified
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (status sync)
- `_bmad-output/implementation-artifacts/1-8-extend-field-encryption-name-mobile-nfr6-complete.md` — modified (senior review notes)

## Senior Developer Review (AI)

**Reviewer:** Laurus
**Date:** 2026-03-01
**Outcome:** Approved (after fixes)

### Git vs Story discrepancies

- `sprint-status.yaml` changed but was not listed in File List (now fixed)
- Story file itself changed for review notes (now listed)

### Findings

- **MEDIUM (fixed):** AC-3 recommends a stable, case-insensitive sort; Dart's `List.sort` is not stable. `FriendRepository` now sorts with an explicit stability tie-breaker to prevent re-ordering when names collide.
- **LOW:** Demo seed rows ("Sophie") are inserted directly at DB open time (bypasses repository encryption boundary). Because the seeded values are non-user demo data, this is not considered a PII-at-rest violation, but it is worth keeping in mind if demo seeding expands beyond fictional content.

### Verification

- `flutter analyze` — clean
- `flutter test test/repositories/field_encryption_test.dart` — passing

## Change Log

- 2026-03-01: Story 1.8 implemented — extended field encryption to `friends.name` and `friends.mobile` at repository layer; added in-memory sort in `watchAll()`/`findAll()`; implemented AC-9 legacy-plaintext compatibility strategy; 10 new tests added; all 266 tests green.
- 2026-03-01: Senior code review — made post-decryption sort explicitly stable; synced sprint status; marked story `done`.
