# Story 6.5: Encrypted Local Backup — Export & Import

> _Epic 6 has been refocused on local backup only; WebDAV sync moves to Phase 2.
> This is the **sole Phase 1 backup story**. Some planning docs may refer to it
> as “6.1” (internal epic story #1), but the tracking key remains `6-5-*`._

Status: done

## Story

As Laurus,
I want to export all my relationship data to a single encrypted file on my
device and restore it at any time by entering my passphrase,
So that my data is portable, recoverable after reinstall, and never dependent
on a third-party server or network connection.

## Context

This story is the primary data protection mechanism for Phase 1. It replaces
the WebDAV sync scope for v1. The user sets a passphrase once (stored only
in-memory during session; never written to disk). The export file is
self-contained and restorable on any Android device with Spetaka installed.

The user explicitly enters the passphrase at export time and at import time.

Important: the existing `EncryptionService` derives its key from a per-install
PBKDF2 salt stored in `shared_preferences`. That salt is *not* portable across
devices, so **backup encryption MUST use a per-backup salt stored in the backup
file** (see “File format”) in order to satisfy NFR14 (restore on any device).

## Acceptance Criteria

1. **Export — create encrypted backup file:**
   - **Given** Laurus taps "Export backup" in the settings Backup section
   - **When** the export is triggered
   - **Then** he is prompted to enter (and confirm) a passphrase.
   - **And** all data (friends, events, acquittements, event_types, settings
     minus passphrase itself) is serialized to JSON via `toJson()` on each
     model; ISO 8601 timestamps in JSON; demo friends (`is_demo = true`)
     are excluded.
   - **And** the JSON payload is encrypted using AES-256-GCM with a key derived
     from the entered passphrase + a **fresh per-backup PBKDF2 salt**
     (PBKDF2-HMAC-SHA256, 100k iterations, 256-bit key), consistent with the
     algorithm in `EncryptionService`.
   - **And** the encrypted file is saved to device external storage /
     Downloads as `spetaka_backup_YYYYMMDD_HHMMSS.enc`.
   - **And** a confirmation snackbar shows the saved file path.
   - **And** demo friends are never included in the backup payload (AC5 of
     original story).

2. **Export — complete and self-contained:**
   - **Given** the exported file exists
   - **Then** it is a complete, self-contained snapshot — every friend card,
     event, acquittement, event type, and setting (NFR14) — restorable to
     any Android device with Spetaka installed.

3. **Import — decrypt and restore:**
   - **Given** Laurus taps "Import backup" in the settings Backup section
   - **When** a file picker opens and he selects a `.enc` file and enters his passphrase
   - **Then** the app reads the backup header to extract the per-backup salt,
     derives the key from passphrase + that salt, and decrypts the payload.
   - **And** on successful decryption, the restore is **replace-all**:
     existing local tables covered by the backup are cleared and then all
     entities are written to SQLite via their repositories — same IDs (UUID),
     no conflicts.
   - **And** the daily view reflects restored data within one Drift stream
     emission.
   - **And** after successful import, a confirmation message is shown and
     the user is navigated to the daily view.

4. **Import — failure safety:**
   - **Given** the file is corrupted or the passphrase is wrong
   - **Then** a typed error from `lib/core/errors/app_error.dart` is surfaced
     and rendered via `lib/core/errors/error_messages.dart`:
     - Wrong passphrase / auth failure: `DecryptionFailedAppError`
     - Corrupted/invalid file format: `CiphertextFormatAppError`
   - **And** no partial data is written to SQLite — the restore is all-or-nothing.
   - **And** existing local data is untouched on any import failure.

5. **Passphrase — never persisted:**
   - **Given** the export or import passphrase
   - **Then** it is never written to disk, `shared_preferences`, or logs.
   - **And** the derived key is discarded after the file operation completes.

6. **Loading state:**
   - Export and import show a loading state via Riverpod `AsyncValue` while in progress.
   - No blocking dialogs during file I/O — progress indicator in the button.

7. **Accessibility:**
   - All interactive elements meet 48×48dp touch targets (NFR15).
   - WCAG AA contrast for all text (NFR16).
   - Passphrase fields and file picker action accessible via TalkBack (NFR17).

## Tasks / Subtasks

- [x] **Add `file_picker` and `permission_handler` dependencies** (or use
      `path_provider` + `share_plus` for save — evaluate best Android approach)
  - [x] Evaluate `file_picker ^6.x` for import (open `.enc` file)
  - [x] Decide export strategy that is **scoped-storage compliant** on Android 10+
    and meets the “Downloads” requirement (prefer MediaStore/SAF; avoid broad
    storage permissions when possible)
  - [x] Add chosen packages (or platform channel) to `pubspec.yaml`

- [x] **Implement serialization contract**
  - [x] Create `BackupPayload` model with `toJson()` / `fromJson()`
  - [x] Include: `friends[]`, `events[]`, `acquittements[]`, `event_types[]`,
    `settings` (Phase 1 user prefs like density; exclude any secrets)
  - [x] Exclude: demo friends (`is_demo == true`)
  - [x] All timestamps as ISO 8601 strings in JSON

- [x] **Implement BackupRepository**
  - [x] `exportEncrypted(String passphrase) → Future<String>` (returns file path)
  - [x] `importEncrypted(String filePath, String passphrase) → Future<void>`
  - [x] Key derivation: derive key from passphrase + **per-backup** PBKDF2 salt
        stored in the file header (do not rely on per-install prefs salt)
  - [x] All-or-nothing restore: run inside a Drift transaction — rollback on any failure

- [x] **Build Backup UI in Settings**
  - [x] Add "Backup & Restore" section to `SettingsScreen`
  - [x] "Export backup" button → passphrase dialog → export → snackbar with path
  - [x] "Import backup" button → file picker → passphrase dialog → import → navigate to daily view
  - [x] Loading state via `AsyncValue` on each button
  - [x] Clear passphrase copy: "Your passphrase is the only key to your backup. If you lose it, the backup cannot be recovered."

- [x] **Wire Riverpod provider**
  - [x] `backupRepositoryProvider` (`@Riverpod`) exposing export/import futures
  - [x] `BackupNotifier` handling async state for export and import

- [x] **Write repository tests**
  - [x] `test/repositories/backup_repository_test.dart`
  - [x] Export roundtrip: export → import → verify all entities restored
  - [x] Ciphertext-at-rest: verify exported bytes ≠ original JSON
  - [x] Wrong passphrase: typed error, no partial write
  - [x] Corrupt file: typed error, no partial write
  - [x] All existing tests remain green: `flutter test`

## Dev Notes

### Key Architecture Points

- **`BackupRepository`** lives at `lib/features/backup/data/backup_repository.dart`.
  The Settings UI is a caller of this repository; it should not own the data layer.
- **No `SyncRepository`** needed in Phase 1 — the WebDAV-oriented `SyncRepository`
  is a Phase 2 artifact. `BackupRepository` is a simpler, file-only abstraction.
- **Key derivation (critical for NFR14)**: do **not** use the per-install
  `EncryptionService` salt from `shared_preferences` for backup encryption.
  Instead, generate a fresh random salt per exported backup and store it in the
  backup file header so import on a different device can derive the same key.
  This keeps passphrase rules intact (never persisted) while making the backup
  portable.
- **All-or-nothing import**: wrap all DB writes in a single Drift transaction.
  On any exception, rollback — do not leave the DB in a partially restored state.
- **File format (portable):** must include a small unencrypted header so the
  per-backup salt is available before decryption.

  **V1 format (recommended):**
  - ASCII magic: `SPBK` (4 bytes)
  - Version: `0x01` (1 byte)
  - PBKDF2 salt: 16 bytes (raw)
  - Ciphertext payload: UTF-8 bytes of the `EncryptionService.encrypt()` output
    (Base64URL string that already contains IV + tag + ciphertext)

  Import reads magic+version+salt, derives key, then decrypts the ciphertext
  string.
- **INTERNET permission**: NOT required by this story. Local file backup is fully
  offline.
- **`android:allowBackup="false"` in AndroidManifest**: verify this is set to
  prevent app-private data (SQLite + preferences) from being auto-backed-up to
  Google Drive. If not set, add it as part of this story.

### File Structure

```
lib/
  features/
    backup/
      data/
        backup_repository.dart    ← NEW
      domain/
        backup_payload.dart       ← NEW: BackupPayload model
      providers/
        backup_providers.dart     ← NEW
        backup_providers.g.dart   ← generated

    # Settings UI integration lives in Settings feature / app shell routing.
    # Keep data-layer code in the backup feature.

test/
  repositories/
    backup_repository_test.dart   ← NEW
```

### Passphrase UX Copy

- Export dialog: _"Choose a passphrase to protect your backup. Write it down somewhere safe — it cannot be recovered."_
- Import dialog: _"Enter the passphrase you used when creating this backup."_
- Error copy MUST come from `error_messages.dart` via typed `AppError` mapping.

### Dependencies to Evaluate

| Purpose | Candidate | Notes |
|---|---|---|
| File picker (import) | `file_picker ^6.x` | Standard choice for Flutter |
| Save to Downloads (export) | `path_provider` + share sheet | Or `file_saver` package |
| Permission (storage) | `permission_handler ^11.x` | Prefer to avoid broad permissions by using MediaStore/SAF for Downloads when possible |

### References

- `_bmad-output/planning-artifacts/epics.md` — Epic 6 (Phase 1 backup)
- `_bmad-output/planning-artifacts/architecture.md` — Repository pattern, Error handling
- Story 1.3 — `EncryptionService` ciphertext format (must not change)
- Story 1.7 / 1.8 — Repository-layer encryption pattern to replicate

## Dev Agent Record

### Implementation Plan

- **Task 1 — Dependencies:** Added `file_picker: ^8.3.7` (import) and `media_store_plus: ^0.1.3` (Android Downloads export) to `pubspec.yaml`. Chose MediaStore for scoped-storage compliant saves to `Downloads/Spetaka/` without broad storage permissions.
- **Task 2 — Serialization:** Created `BackupPayload` in `lib/features/backup/domain/backup_payload.dart`. Used Drift-generated `.toJson()` / `.fromJson()` on each data class (Friend, Event, Acquittement, EventTypeEntry). Demo friends filtered with `where((f) => !f.isDemo)`.
- **Task 3 — BackupRepository:** V1 binary format: `SPBK` (4B) + version (1B) + PBKDF2 salt (16B) + ciphertext UTF-8 bytes. Export writes via MediaStore on Android (Downloads), with fallback to app-accessible storage. Export filters out demo friends and avoids orphan exports by selecting events/acquittements only for exported friend IDs. Import uses a single `db.transaction()` with `deleteAll()` + DAO inserts for atomic replace-all; settings restore runs best-effort after a successful DB commit.
- **Task 4 — Settings UI:** Extracted `SettingsScreen` from `app_router.dart` into `lib/features/settings/presentation/settings_screen.dart`. Added `_BackupSection` with export/import `_ActionTile` widgets (48dp touch target, Semantics, TalkBack). Passphrase dialog captures and validates input; confirm-field on export. `ref.listen` on `backupExportProvider` / `backupImportProvider` drives snackbar + navigation.
- **Task 5 — Providers:** `@Riverpod(keepAlive: true) BackupRepository` + autoDispose `BackupExportNotifier` (state: `AsyncValue<String?>`) + `BackupImportNotifier` (state: `AsyncValue<bool>`). Generated `backup_providers.g.dart` via `build_runner`.
- **Task 6 — Tests:** Tests cover full roundtrip (including settings restore), ciphertext-at-rest, wrong passphrase (`DecryptionFailedAppError`), invalid/corrupt header (`CiphertextFormatAppError`), demo exclusion, and replace-all restore. Export payload is decrypted in-test to assert ISO 8601 timestamps and settings snapshot.

### Completion Notes

✅ All 7 story tasks and subtasks implemented and verified.
✅ AC1 (export with passphrase + per-backup salt + Downloads-compatible path): done.
✅ AC2 (self-contained snapshot including all entity types): done.
✅ AC3 (import → replace-all → daily view reload via Drift stream): done.
✅ AC4 (failure safety — typed errors, no partial write, transaction rollback): done.
✅ AC5 (passphrase never persisted): derived key bytes are zeroed after file operations.
✅ AC6 (AsyncValue loading state on buttons): done.
✅ AC7 (accessibility — 48dp targets, Semantics, passphrase accessible): done.
✅ All 371 tests pass (`flutter test`), zero regressions.
✅ `flutter analyze`: No issues.

**Export strategy decision (Android):** Save to Downloads via MediaStore (scoped storage, no broad storage permissions), under `Downloads/Spetaka/`. If MediaStore fails, fallback to app-accessible storage and still show the resulting path in the snackbar.

### Senior Developer Review (AI)

Post-implementation code review fixes applied to ensure AC alignment:

- Export now targets Android Downloads (MediaStore) instead of app-specific external storage.
- Backup payload now includes a minimal settings snapshot (e.g. density mode) and restores it best-effort after a successful DB import.
- JSON timestamps are exported as ISO 8601 strings (and converted back on import before calling Drift `fromJson`).
- Import picker restricted to `.enc` files.
- Invalid/corrupt file headers are surfaced as `CiphertextFormatAppError` per AC.
- Android auto-backup is explicitly disabled (`android:allowBackup="false"`).

## File List

### New Files
- `spetaka/lib/features/backup/domain/backup_payload.dart`
- `spetaka/lib/features/backup/data/backup_repository.dart`
- `spetaka/lib/features/backup/providers/backup_providers.dart`
- `spetaka/lib/features/backup/providers/backup_providers.g.dart`
- `spetaka/lib/features/settings/presentation/settings_screen.dart`
- `spetaka/test/repositories/backup_repository_test.dart`

### Modified Files
- `spetaka/pubspec.yaml` — added `file_picker: ^8.3.7`, `media_store_plus: ^0.1.3`
- `spetaka/pubspec.lock` — updated by dependency resolution
- `spetaka/lib/core/encryption/encryption_service.dart` — added 4 public static helpers: `generateRandomBytes`, `deriveKeyForBackup`, `encryptWithKeyBytes`, `decryptWithKeyBytes`
- `spetaka/lib/core/errors/app_error.dart` — added `BackupFileFormatAppError`
- `spetaka/lib/core/errors/error_messages.dart` — added case for `BackupFileFormatAppError`
- `spetaka/lib/core/router/app_router.dart` — removed inline `SettingsScreen` class, added import for new settings screen
- `spetaka/lib/core/database/daos/friend_dao.dart` — added `deleteAll()`
- `spetaka/lib/core/database/daos/event_dao.dart` — added `selectAll()`, `deleteAll()`
- `spetaka/lib/core/database/daos/acquittement_dao.dart` — added `selectAllRaw()`, `deleteAll()`
- `spetaka/lib/core/database/daos/event_type_dao.dart` — added `deleteAll()`
- `spetaka/android/app/src/main/AndroidManifest.xml` — set `android:allowBackup="false"`
- `spetaka/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` — regenerated
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — 6-5 status
- `_bmad-output/implementation-artifacts/6-5-encrypted-local-file-export-import.md` — this file

## Change Log

| Date       | Change                                                                     |
|------------|----------------------------------------------------------------------------|
| 2026-03-02 | Story 6.5 implemented: encrypted local backup export & import (Amelia/AI) |
| 2026-03-02 | Code review fixes: Downloads export (MediaStore), settings snapshot, ISO timestamps, stricter import + error typing (Amelia/AI) |

## Handoff (Epic 6 → Epic 7 Gate)

### Sécurité (smoke)

- Passphrase: jamais persistée (pas de `shared_preferences`, pas de logs). Utilisée uniquement pour dériver une clé de backup en mémoire.
- Chiffrement: AES-256-GCM, clé dérivée via PBKDF2-HMAC-SHA256 (100k itérations) avec **salt par-backup** stocké dans l’en-tête du fichier.
- Import “fail-safe”: toute restauration DB est encapsulée dans **une transaction Drift** (succès total ou rollback total). Sur échec (mauvaise passphrase / fichier corrompu), la DB locale reste inchangée.

### Android Downloads

- Export cible `Downloads/Spetaka/` via MediaStore (scoped storage). Fallback vers un chemin app-accessible si MediaStore échoue.

### Vérification rapide

1) Settings → Backup: exporter un fichier `spetaka_backup_*.enc`.
2) Désinstaller/réinstaller (ou vider données) puis importer le `.enc` avec la même passphrase.
3) Vérifier: données présentes (friends/events/…), setting `density_mode` restauré, aucune donnée partielle en cas d’échec (tester mauvaise passphrase).
