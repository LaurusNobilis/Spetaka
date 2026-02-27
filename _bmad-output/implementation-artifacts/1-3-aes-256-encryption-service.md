# Story 1.3: AES-256 Encryption Service

Status: done

## Story

As a developer,
I want a tested, reusable encryption service implementing AES-256-GCM with PBKDF2 key derivation,
so that sync and export features can encrypt data before it leaves the device, with the passphrase never stored or transmitted.

## Acceptance Criteria

1. **Given** `encrypt ^5.0.3` and `crypto` packages are declared in `pubspec.yaml`,
   **When** `EncryptionService` is initialized with a user passphrase,
   **Then** `lib/core/encryption/encryption_service.dart` exposes `encrypt(String plaintext) → String` and `decrypt(String ciphertext) → String` using AES-256-GCM mode.

2. **Given** a passphrase is supplied,
   **When** the derived key is computed,
   **Then** key derivation uses PBKDF2 with 100,000 iterations, SHA-256, and 256-bit output via the `crypto` pub package (`package:crypto`).

3. **Given** the app runs for the first time,
   **When** `EncryptionService` needs a salt,
   **Then** a cryptographically random salt is generated via `Random.secure()` and persisted to `shared_preferences` under key `spetaka_pbkdf2_salt`; the passphrase and derived key are **never** written to disk.

4. **Given** the user backgrounds the app,
   **When** `AppLifecycleState.paused` is observed via `WidgetsBindingObserver`,
   **Then** the in-memory derived key is zeroed/nulled immediately — requiring re-derivation on next use.

5. **Given** `EncryptionService` exists,
   **When** it is declared as a Riverpod provider,
   **Then** a `@Riverpod(keepAlive: true)` annotation generates `encryptionServiceProvider`; the provider must **not** auto-dispose.

6. **Given** the encryption service is implemented,
   **When** `flutter test test/unit/encryption_service_test.dart` runs,
  **Then** tests pass, including:
   - `encrypt(plaintext)` followed by `decrypt(ciphertext)` returns the original `plaintext`.
   - Two independent calls to `encrypt(samePlaintext)` produce different ciphertexts (GCM nonce is random per call).
   - Calling `decrypt(ciphertext)` with a different passphrase throws a typed `AppError` (not a raw Dart exception).

## Tasks / Subtasks

- [x] **Add missing `crypto` dependency** (AC: 2)
  - [x] In `pubspec.yaml`, add `crypto: ^3.0.5` under `dependencies`
  - [x] Run `flutter pub get` to resolve

- [x] **Implement core encryption service** (AC: 1, 2)
  - [x] Create `lib/core/encryption/encryption_service.dart`
  - [x] Implement `encrypt(String plaintext) → String` using AES-256-GCM
    - Generate a fresh 12-byte random IV/nonce per call (`Random.secure()`)
    - Payload format: Base64url( `iv (12 bytes)` + `tag (16 bytes)` + `ciphertext` ) — all concatenated before encoding
  - [x] Implement `decrypt(String ciphertext) → String`
    - Decode Base64url, split IV / tag / ciphertext by fixed offsets
    - On AES-GCM authentication failure, catch and rethrow as `AppError.decryptionFailed`
  - [x] Implement PBKDF2 key derivation (100,000 iterations, SHA-256, 32-byte output)
    - Use `package:crypto` `Hmac` + manual RFC 2898 PRF loop (the `crypto` package has no `pbkdf2()` helper)

- [x] **Implement secure salt and key lifecycle** (AC: 3, 4)
  - [x] On first call: generate 16-byte random salt, persist to `shared_preferences` key `spetaka_pbkdf2_salt`; load on subsequent calls
  - [x] Store derived key in a private nullable field; keep in memory only during an active session
  - [x] Implement `WidgetsBindingObserver.didChangeAppLifecycleState`: zero and null the key field on `AppLifecycleState.paused`
  - [x] Add `// TODO(1.5): replace with AppLifecycleService once Story 1.5 is implemented` comment

- [x] **Expose Riverpod provider** (AC: 5)
  - [x] Annotate with `@Riverpod(keepAlive: true)` (NOT bare `@riverpod` which would set `isAutoDispose: true`)
  - [x] Provider function signature: `EncryptionService encryptionService(Ref ref)` (use bare `Ref`)
  - [x] Run `flutter pub run build_runner build --delete-conflicting-outputs`
  - [x] Export via `lib/core/core.dart` barrel

- [x] **Add error type** (AC: 6)
  - [x] Create `lib/core/errors/app_error.dart` with `AppError.decryptionFailed` variant
  - [x] Create `lib/core/errors/error_messages.dart` with user-facing string for decryption failure
  - [x] Export errors from `lib/core/core.dart`

- [x] **Write unit tests** (AC: 6)
  - [x] Create `test/unit/encryption_service_test.dart`
  - [x] Test 1: roundtrip — `service.decrypt(service.encrypt('hello'))` == `'hello'`
  - [x] Test 2: nonce randomness — `service.encrypt('x') != service.encrypt('x')`
  - [x] Test 3: wrong passphrase — second service with different passphrase; `decrypt` throws `AppError.decryptionFailed`
  - [x] Run `flutter test` — confirm 100 % green, no regressions

## Dev Notes

### Critical Architecture Guardrails

- **Do NOT encrypt the SQLite database file with SQLCipher.** The architecture explicitly defers SQLCipher for v1; Android app sandbox provides acceptable isolation. Field-level encryption (Story 1.7) is the NFR6 approach.
- **Passphrase NEVER touches disk.** Only the random salt goes to `shared_preferences`. Derived key lives in a private nullable field only. Zero/null it on `AppLifecycleState.paused`.
- **GCM over CBC — always.** Use `AesMode.gcm` exclusively. GCM gives authenticated encryption (integrity + confidentiality). CBC would require a separate MAC.
- **Random 12-byte IV per `encrypt()` call.** Never reuse a nonce with AES-GCM for the same key. A 12-byte nonce from `Random.secure()` satisfies this.
- **Stable ciphertext format:** `Base64url(iv[12] + tag[16] + ciphertext)`. This format must not change after Story 1.3 ships — Story 1.7 (field-level encryption) and Epic 6 (WebDAV sync / local export) depend on it.
- **`@Riverpod(keepAlive: true)` is mandatory.** The service holds in-memory key state. Auto-disposal would discard the key — all subsequent decrypt calls would fail. Same pattern as `AppDatabase` in Story 1.2 (see commit `fd176b1`).
- **Riverpod v3 provider signature:** `EncryptionService encryptionService(Ref ref)` — bare `Ref`, NOT `EncryptionServiceRef`. Riverpod generator v4 unified to `Ref`. Critical lesson from Story 1.2.
- **PBKDF2 manual implementation required.** `package:crypto` provides `Hmac` + `sha256` but no `pbkdf2()` call. Implement RFC 2898 §5.2 PRF loop (1 block = 32 bytes, 100,000 iterations). Expect ~200–400 ms on real hardware; wrap in `Isolate.run()` only if UI jank is observed in practice (architecture flags this as an option, not a requirement).
- **Error surfaces.** Catch all crypto/format exceptions; rethrow as typed `AppError`. User-visible strings in `error_messages.dart`. Never log key material or plaintext.

### File Structure Requirements

```
lib/
  core/
    encryption/
      encryption_service.dart        ← NEW (main deliverable)
      encryption_service_provider.g.dart  ← generated by build_runner
    errors/
      app_error.dart                 ← NEW: typed domain error hierarchy
      error_messages.dart            ← NEW: user-visible strings
    core.dart                        ← extend barrel: add encryption + errors exports
test/
  unit/
    encryption_service_test.dart     ← NEW
pubspec.yaml                         ← add crypto: ^3.0.5
```

> All cryptographic primitives stay inside `lib/core/encryption/` only. No crypto logic in features, repositories, or widgets.

### Library & Framework Requirements

| Package | Version in pubspec | Status | Notes |
|---|---|---|---|
| `encrypt` | `^5.0.3` | ✅ present | Use `Encrypter`, `Key`, `IV`, `AesMode.gcm` |
| `crypto` | `^3.0.5` | ✅ present | Provides `Hmac`, `sha256` for PBKDF2 PRF |
| `shared_preferences` | `^2.3.5` | ✅ present | Persist salt only (`spetaka_pbkdf2_salt`) |
| `flutter_riverpod` | `^3.2.1` | ✅ present | |
| `riverpod_annotation` | `^4.0.0` | ✅ present | |
| `riverpod_generator` | `^4.0.0` (dev) | ✅ present | Re-run after annotation change |
| `dart:math` (`Random.secure()`) | SDK built-in | ✅ no dep needed | Nonce + salt generation |
| `dart:convert` (`base64Url`) | SDK built-in | ✅ no dep needed | Ciphertext encoding |

### Testing Requirements

- **Test isolation:** Instantiate `EncryptionService` directly (not via provider); pass a known passphrase in the constructor.
- **Salt handling in tests:** Call `SharedPreferences.setMockInitialValues({})` in `setUpAll` to reset state between test runs.
- **No async key derivation in test setUp** if it blocks: `flutter_test` supports `async` test bodies — derive key inside each test body or use `setUp(() async { ... })`.
- **All existing tests must remain green.** Run `flutter test` at the end; confirm the full suite passes (33 tests from 1.1/1.2 + 3 new = 36 minimum).

### Previous Story Intelligence (Story 1.2 Learnings)

| Pattern from Story 1.2 | Action for Story 1.3 |
|---|---|
| `@Riverpod(keepAlive: true)` required for root singleton services — auto-dispose erased DB connection (fixed in commit `fd176b1`) | Use `@Riverpod(keepAlive: true)` for `EncryptionService` — holds key state, must not dispose |
| Riverpod v3 provider function uses bare `Ref` parameter — `EncryptionServiceRef` would be a compile error | `EncryptionService encryptionService(Ref ref)` — copy pattern from `app_database.dart` |
| `build_runner build --delete-conflicting-outputs` regenerates `.g.dart` | Run after adding `@Riverpod(keepAlive: true)` annotation |
| Internal services (DAOs) not re-exported from `core.dart` — only public interface | Export `EncryptionService` class from `core.dart`; keep PBKDF2 helpers private |
| `try/catch + FlutterError.reportError` before rethrow in critical init paths (`_openConnection`) | Wrap salt I/O and key derivation failures the same way |

### Git Intelligence (Recent Commits)

```
fd176b1  fix(1.2): code-review fixes — keepAlive provider, DAO barrel isolation, error handling
2af0233  feat(1.2): Drift database foundation & migration infrastructure
294b41d  Docs: mark AC1/CI validation as confirmed
2cf1749  CI: ensure release APK builds on x86_64
```

- `lib/core/encryption/` does **not** exist yet — creating from scratch.
- `lib/core/errors/` does **not** exist yet — creating as part of this story.
- `lib/core/core.dart` barrel is ready to extend (was updated in Story 1.2).

### Dependencies on Other Stories

| Story | Status | Impact |
|---|---|---|
| Story 1.1 (Flutter scaffold) | ✅ done | Project structure and `lib/core/` exist |
| Story 1.2 (Drift DB) | ✅ done | `lib/core/core.dart` barrel ready; Riverpod patterns established |
| Story 1.5 (AppLifecycleService) | ⏳ ready-for-dev (later) | Until 1.5 ships, use `WidgetsBindingObserver` directly in `EncryptionService`; leave `// TODO(1.5)` comment |
| Story 1.7 (Field encryption) | ⏳ ready-for-dev (later) | **Depends on this story.** `EncryptionService` must be stable and ciphertext format must not change after 1.3 is done |

## Dev Agent Record

### Agent Model Used

GPT-5.2 (GitHub Copilot)

### Debug Log References

- Local validation (Linux ARM64 container): `flutter analyze` green, `flutter test` green (38 tests).

### Completion Notes List

- ✅ Added `crypto` dependency (`crypto: ^3.0.5`) to support PBKDF2 HMAC-SHA256.
- ✅ Implemented `EncryptionService` with AES-256-GCM using `encrypt ^5.0.3` and a stable ciphertext format: Base64url(`iv[12] + tag[16] + ciphertext`).
- ✅ PBKDF2 implemented manually (RFC 2898) with 100,000 iterations, SHA-256, 32-byte key.
- ✅ Salt lifecycle: 16-byte Random.secure salt persisted in `shared_preferences` under `spetaka_pbkdf2_salt` (passphrase/key never persisted).
- ✅ Key lifecycle: in-memory key cleared on `AppLifecycleState.paused` via `WidgetsBindingObserver`.
- ✅ Riverpod provider added with `@Riverpod(keepAlive: true)`.
- ✅ Typed errors added (`AppError` + decryption/format/init variants) and surfaced in tests.
- ✅ Unit tests added (3) and passing.
- ✅ Hardened initialization and lifecycle handling: init failures are typed errors, passphrase/derivedKey temporary buffers are zeroed, and key clearing triggers on additional lifecycle states.
- ✅ Added extra negative-path tests (uninitialized encrypt, invalid ciphertext format).

## Senior Developer Review (AI)

### Findings

- **MEDIUM**: Story doc drift — tasks remained unchecked and dependency table still claimed `crypto` was missing despite implementation being complete.
- **MEDIUM**: Salt corruption handling incomplete — decoded salt length was not validated; a malformed stored value could silently degrade security assumptions.
- **MEDIUM**: Initialization error surfacing — SharedPreferences / PBKDF2 failures could bubble as raw exceptions without a typed domain error.
- **MEDIUM**: Lifecycle hardening — key was cleared only on `paused`; clearing on other non-resumed lifecycle states reduces risk of key retention.
- **LOW**: Test coverage gap for negative paths — missing explicit tests for “not initialized” and “invalid ciphertext format”.

### Fixes Applied

- Updated story artifact to reflect reality (tasks checked, dependency table corrected, AC6 wording made non-fragile).
- Hardened `EncryptionService`:
  - validates stored salt length and regenerates on corruption
  - reports init failures via `FlutterError.reportError` and throws `EncryptionInitializationFailedAppError`
  - clears key on additional lifecycle states and zeroes temporary buffers
- Added two unit tests for negative paths.

### File List

- spetaka/pubspec.yaml
- spetaka/pubspec.lock
- spetaka/lib/core/core.dart
- spetaka/lib/core/encryption/encryption_service.dart
- spetaka/lib/core/encryption/encryption_service_provider.dart
- spetaka/lib/core/encryption/encryption_service_provider.g.dart
- spetaka/lib/core/errors/app_error.dart
- spetaka/lib/core/errors/error_messages.dart
- spetaka/test/unit/encryption_service_test.dart
- _bmad-output/implementation-artifacts/1-3-aes-256-encryption-service.md

## Change Log

- 2026-02-27: Story implemented — AES-256-GCM EncryptionService with PBKDF2(HMAC-SHA256, 100k, 256-bit), salt persistence in shared_preferences, keepAlive Riverpod provider, typed errors, and 3 unit tests (all green).
- 2026-02-27: Senior Developer Review (AI) — fixed doc drift, hardened salt/init/lifecycle handling, and expanded unit tests (all green).