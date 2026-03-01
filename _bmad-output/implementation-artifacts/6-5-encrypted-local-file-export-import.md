# Story 6.1: Encrypted Local Backup — Export & Import

> _Previously numbered 6.5. Epic 6 has been refocused on local backup only;
> WebDAV sync moves to Phase 2. This is now the **sole Phase 1 backup story**._

Status: ready-for-dev

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

The passphrase used for backup is the same one derived by `EncryptionService`
(PBKDF2 → AES-256-GCM). The User explicitly enters the passphrase at export
time and at import time — this is distinct from the salt lifecycle.

## Acceptance Criteria

1. **Export — create encrypted backup file:**
   - **Given** Laurus taps "Export backup" in the settings Backup section
   - **When** the export is triggered
   - **Then** he is prompted to enter (and confirm) a passphrase.
   - **And** all data (friends, events, acquittements, event_types, settings
     minus passphrase itself) is serialized to JSON via `toJson()` on each
     model; ISO 8601 timestamps in JSON; demo friends (`is_demo = true`)
     are excluded.
   - **And** the JSON payload is encrypted with `EncryptionService.encrypt()`
     using the entered passphrase (a fresh key is derived from this passphrase
     + the stored salt via PBKDF2 100k iterations; the key is used only for
     this operation and discarded after).
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
   - **Then** the app decrypts the payload using `EncryptionService.decrypt()`
     with a key derived from the entered passphrase + stored salt.
   - **And** on successful decryption, all entities are written to SQLite via
     their repositories — same IDs (UUID), no conflicts.
   - **And** the daily view reflects restored data within one Drift stream
     emission.
   - **And** after successful import, a confirmation message is shown and
     the user is navigated to the daily view.

4. **Import — failure safety:**
   - **Given** the file is corrupted or the passphrase is wrong
   - **Then** a typed error from `error_messages.dart` is shown:
     - Wrong passphrase: `"Passphrase incorrect — unable to decrypt backup. Check your passphrase and try again."`
     - Corrupted file: `"Backup file is corrupted or not a valid Spetaka backup."`
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

- [ ] **Add `file_picker` and `permission_handler` dependencies** (or use
      `path_provider` + `share_plus` for save — evaluate best Android approach)
  - [ ] Evaluate `file_picker ^6.x` for import (open `.enc` file)
  - [ ] Evaluate `path_provider` + `open_file` or `share_plus` for export
        (save to Downloads or share sheet)
  - [ ] Add chosen packages to `pubspec.yaml`

- [ ] **Implement serialization contract**
  - [ ] Create `BackupPayload` model with `toJson()` / `fromJson()`
  - [ ] Include: `friends[]`, `events[]`, `acquittements[]`, `event_types[]`,
        `settings` (density, PBKDF2 salt)
  - [ ] Exclude: demo friends (`is_demo == true`)
  - [ ] All timestamps as ISO 8601 strings in JSON

- [ ] **Implement BackupRepository**
  - [ ] `exportEncrypted(String passphrase) → Future<String>` (returns file path)
  - [ ] `importEncrypted(String filePath, String passphrase) → Future<void>`
  - [ ] Key derivation: derive key from passphrase + stored PBKDF2 salt
  - [ ] All-or-nothing restore: run inside a Drift transaction — rollback on any failure

- [ ] **Build Backup UI in Settings**
  - [ ] Add "Backup & Restore" section to `SettingsScreen`
  - [ ] "Export backup" button → passphrase dialog → export → snackbar with path
  - [ ] "Import backup" button → file picker → passphrase dialog → import → navigate to daily view
  - [ ] Loading state via `AsyncValue` on each button
  - [ ] Clear passphrase copy: "Your passphrase is the only key to your backup. If you lose it, the backup cannot be recovered."

- [ ] **Wire Riverpod provider**
  - [ ] `backupRepositoryProvider` (`@Riverpod`) exposing export/import futures
  - [ ] `BackupNotifier` handling async state for export and import

- [ ] **Write repository tests**
  - [ ] `test/repositories/backup_repository_test.dart`
  - [ ] Export roundtrip: export → import → verify all entities restored
  - [ ] Ciphertext-at-rest: verify exported bytes ≠ original JSON
  - [ ] Wrong passphrase: typed error, no partial write
  - [ ] Corrupt file: typed error, no partial write
  - [ ] All existing tests remain green: `flutter test`

## Dev Notes

### Key Architecture Points

- **`BackupRepository`** lives at `lib/features/settings/data/backup_repository.dart`
  (under settings feature — backup is a settings-adjacent concern).
- **No `SyncRepository`** needed in Phase 1 — the WebDAV-oriented `SyncRepository`
  is a Phase 2 artifact. `BackupRepository` is a simpler, file-only abstraction.
- **Key derivation**: use the existing PBKDF2 salt from `shared_preferences` +
  user-entered passphrase → derive key via `EncryptionService._deriveKey()`.
  If the stored salt is missing (new install, first backup ever), generate a new
  salt and persist it before deriving.
- **All-or-nothing import**: wrap all DB writes in a single Drift transaction.
  On any exception, rollback — do not leave the DB in a partially restored state.
- **File format**: encrypted bytes only, no metadata wrapper. The ciphertext
  already embeds the GCM nonce (first 12 bytes) and auth tag (bytes 12–28) per
  the established Story 1.3 format.
- **INTERNET permission**: NOT required by this story. Local file backup is fully
  offline.
- **`android:allowBackup="false"` in AndroidManifest**: verify this is set to
  prevent the `.enc` file and SQLite DB from being auto-backed-up to Google Drive.
  If not set, add it here.

### File Structure

```
lib/
  features/
    settings/
      data/
        backup_repository.dart    ← NEW
      domain/
        backup_payload.dart       ← NEW: BackupPayload model
      providers/
        backup_providers.dart     ← NEW
        backup_providers.g.dart   ← generated
      presentation/
        settings_screen.dart      ← extend with Backup section
        export_import_screen.dart ← optional dedicated screen

test/
  repositories/
    backup_repository_test.dart   ← NEW
```

### Passphrase UX Copy

- Export dialog: _"Choose a passphrase to protect your backup. Write it down somewhere safe — it cannot be recovered."_
- Import dialog: _"Enter the passphrase you used when creating this backup."_
- Error (wrong passphrase): _"Incorrect passphrase. Your backup was not restored."_
- Error (corrupted file): _"This file does not appear to be a valid Spetaka backup."_

### Dependencies to Evaluate

| Purpose | Candidate | Notes |
|---|---|---|
| File picker (import) | `file_picker ^6.x` | Standard choice for Flutter |
| Save to Downloads (export) | `path_provider` + share sheet | Or `file_saver` package |
| Permission (storage) | `permission_handler ^11.x` | Android 13+ uses `READ_MEDIA_*`; Android ≤12 uses `WRITE_EXTERNAL_STORAGE` |

### References

- `_bmad-output/planning-artifacts/epics.md` — Epic 6 (Phase 1 backup)
- `_bmad-output/planning-artifacts/architecture.md` — Repository pattern, Error handling
- Story 1.3 — `EncryptionService` ciphertext format (must not change)
- Story 1.7 / 1.8 — Repository-layer encryption pattern to replicate
