# Story 1.8: Extend Field Encryption to `name` and `mobile` (NFR6 Complete)

Status: ready-for-dev

## Context

Story 1.7 established field-level encryption at the repository layer for narrative
fields (`friends.notes`, `friends.concern_note`, `acquittements.note`).

NFR6 states: _"All on-device data is encrypted at rest using AES-256 with a key
derived from the user's passphrase."_

Structural fields `friends.name` and `friends.mobile` are currently stored as
plaintext in SQLite. An attacker with ADB access or on a rooted device could read
all friend names and phone numbers from the database file without a passphrase.
This story extends the existing encryption boundary to cover these remaining
sensitive structured fields, completing NFR6 compliance for Phase 1.

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

3. **In-memory sort replaces SQL ORDER BY name:**
   - **Given** `FriendRepository.watchAll()` previously sorted by `name` in the
     Drift query
   - **When** names are stored as ciphertext
   - **Then** the sort is performed in-memory in the repository after decryption,
     using `list.sort((a, b) => a.name.compareTo(b.name))`.
   - **And** the sorted list is returned correctly to the `watchAll()` stream
     subscriber.

4. **ContactActionService unaffected:**
   - **Given** `ContactActionService` calls `PhoneNormalizer` with the mobile number
   - **When** a friend's card provides the mobile value
   - **Then** `ContactActionService` always receives the decrypted plaintext mobile
     number (decrypted at repository layer, transparent to downstream callers).

5. **Search / contact import unaffected:**
   - **Given** contact import stores the mobile as received from
     `flutter_contacts` (plaintext at point of entry)
   - **When** `FriendRepository.importFromContact()` is called
   - **Then** the mobile is encrypted by the repository before DAO write — same
     path as manual entry.

6. **Non-sensitive fields remain plaintext:**
   - `care_score`, `is_concern_active`, `created_at`, `updated_at`, `id`,
     `category_tags` — all remain plaintext for query optimization and sort
     operations.

7. **Typed error propagation consistent with Story 1.7:**
   - Missing key → `EncryptionNotInitializedAppError`
   - Decrypt/auth failure → `DecryptionFailedAppError`
   - Corrupted ciphertext → `CiphertextFormatAppError`
   - Repositories do not swallow errors.

8. **Tests:**
   - `flutter test test/repositories/field_encryption_test.dart` passes with:
     - Write a Friend with `name` and `mobile` → read back via repository →
       plaintext values match originals.
     - Inspect raw DAO-stored value → confirm stored value is NOT equal to
       original plaintext (ciphertext-at-rest verification).
     - `watchAll()` returns friends sorted alphabetically by decrypted name.
     - Attempt read/write without initialized `EncryptionService` → throws
       `EncryptionNotInitializedAppError`.
   - All existing tests remain green.

## Tasks / Subtasks

- [ ] **Extend `FriendRepository` write path (AC: 1, 5)**
  - [ ] In `_toEncryptedCompanion()`, add `name` and `mobile` to the list of
        fields encrypted via `EncryptionService.encrypt()`.
  - [ ] Ensure contact import path (`importFromContact()`) also passes through
        `_toEncryptedCompanion()` — confirm no plaintext bypass.

- [ ] **Extend `FriendRepository` read path (AC: 2, 3)**
  - [ ] In `_decryptRow()`, add decryption for `name` and `mobile`.
  - [ ] Replace Drift-level `ORDER BY name` with in-memory sort in
        `watchAll()` / `getAll()` after mapping rows to `Friend` objects.

- [ ] **Verify ContactActionService call chain (AC: 4)**
  - [ ] Trace call path: `FriendCardScreen` → provider → repository →
        `Friend.mobile` (decrypted) → `ContactActionService` →
        `PhoneNormalizer`. Confirm no extra decryption step is needed
        downstream — it should already be transparent.

- [ ] **Update and extend tests (AC: 8)**
  - [ ] Extend `test/repositories/field_encryption_test.dart` with:
        - `name` and `mobile` roundtrip tests
        - Ciphertext-at-rest assertions for `name` and `mobile`
        - Alphabetical sort test on `watchAll()`
  - [ ] Run full suite: `flutter test` — confirm all green.

## Dev Notes

### Critical Architecture Guardrails

- **Same pattern as Story 1.7 — do not deviate.** Encryption boundary is
  exclusively in `FriendRepository`. DAOs remain encryption-agnostic.
- **Never encrypt `id`, `care_score`, `is_concern_active`, `created_at`,
  `updated_at`, `category_tags`.** These fields must remain queryable/sortable
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

- Architecture: `_bmad-output/planning-artifacts/architecture.md` — "Repository
  Pattern", "Test Patterns", "Enforcement Guidelines"
- PRD: NFR6 — "All on-device data is encrypted at rest"
- Security review: R1 (name + mobile in plaintext identified as gap)
- Prior implementation: Story 1.7 (`friend_repository.dart` — `_toEncryptedCompanion`
  and `_decryptRow` patterns to replicate)
