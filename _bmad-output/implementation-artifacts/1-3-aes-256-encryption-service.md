# Story 1.3: AES-256 Encryption Service

Status: ready-for-dev

## Story

As a developer,
I want a tested, reusable encryption service implementing AES-256-GCM with PBKDF2 key derivation,
so that sync and export features can encrypt data before it leaves the device, with the passphrase never stored or transmitted.

## Acceptance Criteria

1. Given `encrypt ^5.0.3` and `crypto` packages are declared in `pubspec.yaml`, when `EncryptionService` is initialized with a user passphrase, then `lib/core/encryption/encryption_service.dart` exposes `encrypt(String plaintext) -> String` and `decrypt(String ciphertext) -> String` using AES-256-GCM mode.
2. Key derivation uses PBKDF2 with 100,000 iterations, SHA-256, 256-bit output via `dart:crypto`.
3. A random salt is generated at first setup and stored in `shared_preferences`; the passphrase and derived key are never written to disk.
4. The derived key is held in memory only during an active session and cleared on app backgrounding.
5. `EncryptionService` is exposed as a Riverpod provider.
6. `flutter test test/unit/encryption_service_test.dart` passes:
   - encrypt -> decrypt returns original plaintext,
   - two encryptions of the same plaintext produce different ciphertexts,
   - decrypting with wrong passphrase throws a typed `AppError`.

## Tasks / Subtasks

- [ ] Implement encryption core service (AC: 1, 2)
  - [ ] Create `lib/core/encryption/encryption_service.dart`
  - [ ] Implement AES-256-GCM encrypt/decrypt API
  - [ ] Implement PBKDF2 derivation (`100_000` iterations, SHA-256, 32-byte key)
- [ ] Implement secure salt and key lifecycle (AC: 3, 4)
  - [ ] Generate and persist random salt (first setup only)
  - [ ] Keep derived key only in-memory during active session
  - [ ] Clear key material on lifecycle background transition
- [ ] Expose provider and integration points (AC: 5)
  - [ ] Add Riverpod provider (`@riverpod`) for `EncryptionService`
  - [ ] Ensure service can be consumed by sync/export/repository layers
- [ ] Add unit tests and error handling (AC: 6)
  - [ ] Create `test/unit/encryption_service_test.dart`
  - [ ] Add deterministic tests for roundtrip and wrong passphrase failure
  - [ ] Ensure typed domain errors are used (`AppError`)

## Dev Notes

- This service is foundational for NFR6/NFR7/NFR8 and must be implemented before sync/backup stories.
- Prefer explicit binary encoding strategy for ciphertext payload (salt reference/nonce/tag/ciphertext packaging) and keep format stable.
- Do not leak sensitive data through logs, exceptions, or debug traces.
- Integrate with lifecycle service so key invalidation is automatic when app backgrounds.
- Ensure compatibility with later repository-layer field encryption (Story 1.7).

### Project Structure Notes

- Keep cryptographic primitives inside `lib/core/encryption/` only.
- Domain-facing contracts should remain framework-agnostic where possible.
- Error surfaces must route through typed app errors and centralized messages.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.3.
- Source: `_bmad-output/planning-artifacts/architecture.md` — encryption and key-management constraints.
- Source: `_bmad-output/planning-artifacts/prd.md` — privacy/security NFR context.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- Story generated as next backlog item in Epic 1 sequence.

### Completion Notes List

- Story 1.3 prepared in ready-for-dev format.
- Acceptance criteria and implementation tasks aligned with planning artifacts.

### File List

- _bmad-output/implementation-artifacts/1-3-aes-256-encryption-service.md