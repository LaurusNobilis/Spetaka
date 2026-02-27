# Story 1.7: Sensitive Field Encryption at Repository Layer (NFR6)

Status: done

## Story

As a developer,
I want sensitive narrative fields encrypted before writing to SQLite and transparently decrypted on read,
so that NFR6 (data encrypted at rest) is satisfied without SQLCipher by relying on `EncryptionService` at repository layer.

## Prerequisites / Dependencies

- Story 1.3 is implemented (AES-256-GCM + PBKDF2) and `EncryptionService` is available via Riverpod.
- The Drift tables/DAOs that contain the sensitive fields exist:
  - `friends.notes` + `friends.concern_note` (introduced in Epic 2 Story 2.1)
  - `acquittements.note` (introduced in Epic 5 Story 5.3)

This story is repository-scoped in *behavior* (encryption boundary lives in repositories, not DAOs). To make the behavior testable immediately, this implementation introduces the minimal Drift table definitions + migration needed to persist and assert ciphertext-at-rest. Those tables will be extended by Epic 2 / Epic 5 stories.

## Acceptance Criteria

1. **Write path (encryption):**
   - **Given** `EncryptionService` has an active in-memory derived key
   - **When** a repository persists a record containing sensitive narrative text
   - **Then** the repository encrypts `friends.notes`, `friends.concern_note`, and `acquittements.note` via `EncryptionService.encrypt()` before calling the Drift DAO.

2. **Read path (decryption):**
   - **Given** ciphertext is stored in SQLite for the fields above
   - **When** a repository loads records from the DAO
   - **Then** the repository decrypts those fields via `EncryptionService.decrypt()` before returning objects to providers/widgets.
   - **And** no widget/provider ever receives ciphertext for these fields.

3. **Plaintext fields remain plaintext:**
   - **Given** the friend model includes both narrative and non-narrative fields
   - **When** repositories write to SQLite
  - **Then** non-sensitive fields remain plaintext (at minimum in the current schema: `friends.name`, `friends.mobile`, `friends.care_score`, `friends.is_concern_active`, timestamps), preserving search/sort/phone number operations.
  - **And** any future non-sensitive columns (e.g. tags) must remain plaintext for search/sort.

4. **Strict layering:**
   - **Given** the architecture repository pattern
   - **When** encryption is implemented
   - **Then** encryption/decryption logic lives in repositories only.
   - **And** Drift DAOs remain encryption-agnostic and only deal with stored values.

5. **Failure behavior is typed and consistent with current error system:**
   - **Given** `EncryptionService` has no key (not initialized, or key cleared on background)
   - **When** a repository attempts to encrypt/decrypt a sensitive field
   - **Then** a typed `AppError` is thrown:
     - missing key → `EncryptionNotInitializedAppError`
     - decrypt/auth failure → `DecryptionFailedAppError`
     - corrupted/invalid ciphertext format → `CiphertextFormatAppError`
   - **And** repositories do not swallow these errors; UI messaging comes from `error_messages.dart`.

6. **Repository tests cover roundtrip + ciphertext-at-rest:**
   - `flutter test test/repositories/field_encryption_test.dart` passes and includes:
     - Write a Friend with non-empty `notes` and/or `concernNote` → read back via repository → plaintext matches original
     - Inspect the raw value as stored by the DAO → confirms stored value is NOT equal to the original plaintext
     - Write an Acquittement with non-empty `note` → read back via repository → plaintext matches original
     - Attempt read/write without initializing `EncryptionService` → throws `EncryptionNotInitializedAppError`

## Tasks / Subtasks

- [x] Add repository-level encryption on write (AC: 1, 3, 4)
  - [x] `FriendRepository`: encrypt narrative fields before calling DAO insert/update
  - [x] `AcquittementRepository`: encrypt `note` before calling DAO insert

- [x] Add repository-level decryption on read (AC: 2, 4)
  - [x] `FriendRepository`: decrypt narrative fields before returning entities to providers
  - [x] `AcquittementRepository`: decrypt `note` before returning entities/rows

- [x] Implement typed failure handling (AC: 5)
  - [x] Ensure missing-key errors propagate as `EncryptionNotInitializedAppError`
  - [x] Ensure invalid ciphertext propagates as `CiphertextFormatAppError`
  - [x] Ensure decrypt/auth errors propagate as `DecryptionFailedAppError`

- [x] Add repository tests (AC: 6)
  - [x] Use Drift in-memory database fixture (`NativeDatabase.memory()`)
  - [x] Use the same `EncryptionService` test patterns as `test/unit/encryption_service_test.dart` (SharedPreferences mock + real `AppLifecycleService`)
  - [x] Assert ciphertext-at-rest by querying DAO-stored values (not repository-mapped values)

## Dev Notes

- Do not move encryption logic into Drift DAOs.
- Follow the architecture pathing: repositories live under `lib/features/{feature}/` and DAOs under `lib/core/database/daos/`.
- Keep ciphertext format opaque to callers (treat as `String`); do not parse or re-encode it outside `EncryptionService`.
- Preserve search/sort behavior by keeping designated fields plaintext.
- Keep conversion boundaries explicit to avoid accidental plaintext exposure.

### Expected File Targets (non-exhaustive)

- `lib/features/friends/friend_repository.dart`
- `lib/features/acquittement/acquittement_repository.dart`
- `test/repositories/field_encryption_test.dart`

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.7.
- Source: `_bmad-output/planning-artifacts/architecture.md` — “Repository Pattern”, “Error Handling Patterns”, “Test Patterns”.
- Source: `_bmad-output/planning-artifacts/prd.md` — NFR6.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- Story executed 2026-02-27 in YOLO mode.
- `schemaVersion` bumped from 1 → 2; existing `database_foundation_test.dart` test updated accordingly.
- `Insertable<T>` used in DAO signatures (vs hardcoded companion class names) to avoid Drift companion name ambiguity.
- Drift requires tables listed in both `@DriftAccessor(tables: [...])` AND `@DriftDatabase(tables: [...])` — warning triggered on first build_runner run; resolved by adding `Friends` and `Acquittements` to `@DriftDatabase`.
- Companion class for `Acquittements` table is `AcquittementsCompanion` (confirmed from generated code).

### Completion Notes List

- `lib/features/friends/domain/friend.dart` — `Friends` Drift table class; schema aligned with Epic 2 Story 2.1 spec; `notes` and `concernNote` columns annotated as ENCRYPTED.
- `lib/features/acquittement/domain/acquittement.dart` — `Acquittements` Drift table class; minimal schema for Story 1.7 encryption infrastructure; `note` column annotated as ENCRYPTED.
- `lib/core/database/daos/friend_dao.dart` — updated with `Friends` table reference, CRUD queries (`insertFriend`, `findById`, `watchAll`, `updateFriend`, `deleteFriend`, `selectAll`); encryption-agnostic.
- `lib/core/database/daos/acquittement_dao.dart` — updated with `Acquittements` table reference, CRUD queries (`insertAcquittement`, `findById`, `selectByFriendId`, `watchAll`); encryption-agnostic.
- `lib/core/database/app_database.dart` — `@DriftDatabase(tables: [Friends, Acquittements], daos: [...])` added; `schemaVersion` bumped to 2; v1→v2 migration creates both tables.
- `lib/features/friends/data/friend_repository.dart` — `FriendRepository`: encrypts `notes`+`concernNote` on write via `_toEncryptedCompanion`; decrypts on read via `_decryptRow`; propagates typed `AppError` on key/crypto failures (AC1–5).
- `lib/features/acquittement/data/acquittement_repository.dart` — `AcquittementRepository`: encrypts `note` on write; decrypts on read; plaintext fields `friendId`, `type`, `createdAt` pass through unchanged (AC1–5).
- `test/repositories/field_encryption_test.dart` — 21 tests across 4 groups: Friend roundtrip, Friend ciphertext-at-rest, Acquittement roundtrip, typed error propagation (expanded with negative-case decrypt/format checks in review); all 21 pass.
- `test/unit/database_foundation_test.dart` — updated `schemaVersion` assertion from 1 → 2.
- Codegen: `lib/core/database/daos/friend_dao.g.dart`, `lib/core/database/daos/acquittement_dao.g.dart`, `lib/core/database/app_database.g.dart` regenerated.
- 112/112 tests green; `flutter analyze` clean.

### Implementation Plan

- **Drift Domain Tables**: Defined `Friends` and `Acquittements` Dart table classes in feature domain directories per architecture spec (`lib/features/{name}/domain/`). Tables are imported by `AppDatabase` for `@DriftDatabase` and by DAOs for `@DriftAccessor`.
- **Encryption boundary**: Encryption/decryption logic lives exclusively in `FriendRepository._toEncryptedCompanion()` / `_decryptRow()` and `AcquittementRepository._toEncryptedCompanion()` / `_decryptRow()`. DAOs receive raw values and are encryption-agnostic (AC4).
- **Error propagation**: `EncryptionService.encrypt()` throws `EncryptionNotInitializedAppError` if key is null; `decrypt()` throws `DecryptionFailedAppError` on GCM auth failure and `CiphertextFormatAppError` on format corruption. Repositories let these propagate unwrapped (AC5).
- **Null-safe handling**: `null` narrative fields are stored as SQL NULL (not encrypted); repository skips encryption/decryption for null values, preserving round-trip nullability.
- **Non-sensitive fields**: `name`, `mobile`, `careScore`, `isConcernActive`, `friendId`, `type`, timestamps — all stored as plaintext (AC3). Verified by direct DAO reads in test group 2.

### File List

- `spetaka/lib/features/friends/domain/friend.dart` (new)
- `spetaka/lib/features/acquittement/domain/acquittement.dart` (new)
- `spetaka/lib/core/database/daos/friend_dao.dart` (modified)
- `spetaka/lib/core/database/daos/acquittement_dao.dart` (modified)
- `spetaka/lib/core/database/app_database.dart` (modified)
- `spetaka/lib/features/friends/data/friend_repository.dart` (new)
- `spetaka/lib/features/acquittement/data/acquittement_repository.dart` (new)
- `spetaka/lib/core/database/daos/friend_dao.g.dart` (regenerated)
- `spetaka/lib/core/database/daos/acquittement_dao.g.dart` (regenerated)
- `spetaka/lib/core/database/app_database.g.dart` (regenerated)
- `spetaka/test/repositories/field_encryption_test.dart` (new)
- `spetaka/test/unit/database_foundation_test.dart` (modified — schema version assertion)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — story status sync)
- `_bmad-output/implementation-artifacts/1-7-sensitive-field-encryption-at-repository-layer-nfr6.md` (this file)

### Change Log

- 2026-02-27: Story 1.7 implemented — repository-layer field encryption (NFR6). Created `Friends` + `Acquittements` Drift tables, updated DAOs + AppDatabase (schemaVersion 2), implemented `FriendRepository` + `AcquittementRepository` with AES-256-GCM encryption at boundary, 18 new tests all passing, 112/112 total green.
- 2026-02-27: Senior Developer Review (AI) — fixed story/doc inconsistencies, expanded negative-case crypto tests (field_encryption: 18 → 21), synced sprint status, marked story done (115/115 tests green).

## Senior Developer Review (AI)

Date: 2026-02-27

### Context

- Architecture + epics docs loaded from `_bmad-output/planning-artifacts/`.
- No MCP/web doc search performed for this review.

### Findings

- **HIGH**: Story text claimed “does not define SQL schema”, but implementation bumps `schemaVersion` and introduces tables/migrations. Fixed by updating this story’s wording to reflect the actual scope and rationale.
- **MEDIUM**: AC5 error propagation was only partially stress-tested. Added negative-case repository tests for invalid ciphertext format and wrong-key decryption failures.
- **LOW**: Story File List did not mention the `sprint-status.yaml` sync change. Fixed by adding it to the File List.

### Outcome

- **Approved (changes applied)** — story status set to `done` and sprint tracking synced.

### Review Follow-ups (AI)

- [ ] [AI-Review][LOW] Consider adding Drift FK constraint for `acquittements.friend_id → friends.id` when the full schema stabilizes (will require a versioned migration).
- [ ] [AI-Review][LOW] Consider adding a ciphertext format version prefix (e.g. `v1:`) to support future format evolution without ambiguity.
