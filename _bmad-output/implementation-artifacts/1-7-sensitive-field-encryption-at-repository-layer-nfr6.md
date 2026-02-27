# Story 1.7: Sensitive Field Encryption at Repository Layer (NFR6)

Status: ready-for-dev

## Story

As a developer,
I want sensitive narrative fields encrypted before writing to SQLite and transparently decrypted on read,
so that NFR6 (data encrypted at rest) is satisfied without SQLCipher by relying on `EncryptionService` at repository layer.

## Acceptance Criteria

1. With active in-memory key from Story 1.3, repository writes encrypt `friends.notes`, `friends.concern_note`, and `acquittements.note` before DAO persistence.
2. Repository reads decrypt these fields before returning to providers/widgets.
3. Non-sensitive fields remain plaintext (`friends.name`, `friends.mobile`, `friends.tags`, and other non-narrative fields).
4. Encryption logic is centralized in repositories; DAOs remain storage-focused and encryption-agnostic.
5. Decryption failure (e.g., missing session key) raises typed `AppError.sessionExpired`.
6. `flutter test test/repositories/field_encryption_test.dart` passes with roundtrip checks, ciphertext-at-rest checks, and session-expired behavior.

## Tasks / Subtasks

- [ ] Wire repository-level encryption on write (AC: 1, 3, 4)
  - [ ] Update friend repository mapping for narrative fields
  - [ ] Update acquittement repository mapping for note field
- [ ] Wire repository-level decryption on read (AC: 2, 4)
  - [ ] Decrypt before returning domain entities/UI models
- [ ] Implement failure handling (AC: 5)
  - [ ] Raise `AppError.sessionExpired` when key not available or decrypt fails
- [ ] Add repository tests (AC: 6)
  - [ ] Validate encrypted persistence (not plaintext)
  - [ ] Validate successful decrypt roundtrip
  - [ ] Validate session-expired path

## Dev Notes

- Do not move encryption logic into Drift DAOs.
- Preserve search/sort behavior by keeping designated fields plaintext.
- Keep conversion boundaries explicit to avoid accidental plaintext exposure.

### Project Structure Notes

- Repository implementations own encryption/decryption orchestration.
- Database layer remains unchanged except for receiving stored values.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.7.
- Source: `_bmad-output/planning-artifacts/architecture.md` — repository layering requirements.
- Source: `_bmad-output/planning-artifacts/prd.md` — NFR6 data-at-rest requirements.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- Story generated in yolo batch progression for Epic 1.

### Completion Notes List

- Story 1.7 prepared with explicit NFR6 guardrails and tests.

### File List

- _bmad-output/implementation-artifacts/1-7-sensitive-field-encryption-at-repository-layer-nfr6.md
