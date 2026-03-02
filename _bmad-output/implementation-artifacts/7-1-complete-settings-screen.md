# Story 7.1: Complete Settings Screen

Status: done

## Story

As Laurus,
I want a single, organized settings screen where I can view and edit all app settings,
so that app configuration is discoverable, simple, and never requires digging through sub-menus.

## Acceptance Criteria

1. **Given** Laurus navigates to `/settings` (`SettingsScreen`)
	 **When** the screen renders
	 **Then** the screen displays organized sections:
	 - **Backup**: export backup + import backup actions (FR37, FR38)
	 - **Display**: density preference toggle (compact/expanded) synced with the daily view density toggle
	 - **Event Types**: link to the event type editor (Epic 3)

2. **And** all settings changes take immediate effect — no “Save” button required for toggle-type settings.

3. **And** the Backup section includes passphrase copy:
	 “Your passphrase encrypts your backup. It is never stored. If you lose it, your backup cannot be recovered.”

4. **And** a “Reset backup settings” option clears any stored PBKDF2 salt from `shared_preferences`,
	 with a clear warning and confirmation dialog (FR40, adapted for local backup).

5. **And** WebDAV sync configuration (a “Sync & Backup” sub-screen at `/settings/sync`) is a **Phase 2 placeholder**:
	 it is shown as a greyed-out “Coming in Phase 2” entry in the settings screen.

6. **And** the settings screen meets accessibility requirements:
	 48×48dp tap targets, WCAG AA contrast, and TalkBack navigation (NFR15, NFR16, NFR17).

## Tasks / Subtasks

- [x] Settings screen structure (AC: 1, 2)
	- [x] Keep `/settings` as the single entry point for user-configurable settings
	- [x] Group content into visible sections: Backup, Display, Event Types (headings + tiles)

- [x] Backup section completeness (AC: 1, 3)
	- [x] Ensure existing Export/Import flows remain unchanged and stable
	- [x] Keep passphrase helper copy visible near export/import actions

- [x] Display section: density preference (AC: 1, 2)
	- [x] Reuse the existing density preference source of truth (`densityModeProvider`)
	- [x] Provide a settings toggle that updates immediately and persists via existing shared prefs key
	- [x] Verify daily view reflects changes immediately after toggling (no app restart)

- [x] Event Types section: deep link (AC: 1)
	- [x] Add a navigation tile that routes to `/settings/event-types` (Manage Event Types screen)

- [x] Sync & Backup placeholder (AC: 5)
	- [x] Add a disabled/greyed-out entry labeled “Sync & Backup (Coming in Phase 2)”
	- [x] Do not expose functional WebDAV actions in Phase 1
	- [x] If tapping is allowed, it must not imply functionality (prefer disabled tile)

- [x] Reset backup settings (AC: 4)
	- [x] Add a “Reset backup settings” action
	- [x] Show a destructive confirmation dialog warning that this does not decrypt backups and may require re-entering passphrases
	- [x] On confirm: reset/rotate the PBKDF2 salt stored in `shared_preferences` (see Dev Notes)

- [x] Accessibility verification (AC: 6)
	- [x] Confirm each tile meets minimum touch target height (≥ 48dp)
	- [x] Provide `Semantics` labels for tiles that aren’t self-descriptive
	- [x] Ensure disabled placeholder is still understandable via TalkBack (state announced)

## Dev Notes

### Architecture / Guardrails

- Phase 1 is local-first and offline-first: do not add network calls, background sync, or WebDAV credential storage as part of this story.
- Reuse existing settings persistence patterns; avoid creating a second “settings store”.
- Do not re-implement encryption or backup logic: this story is primarily **UI + wiring** for already-existing settings.

### Suggested implementation locations

- Settings UI: `lib/features/settings/presentation/settings_screen.dart`
- Router routes already exist for:
	- `/settings` (settings root)
	- `/settings/sync` (currently placeholder screen)
	- `/settings/event-types` (Manage Event Types)
- Density preference provider: `lib/features/daily/data/density_provider.dart`

### Reset backup settings (PBKDF2 salt)

- The per-install PBKDF2 salt key is defined in `EncryptionService.saltPrefsKey`.
- Clearing this key should be safe for the app, but it changes the derived key for any flows that depend on the per-install salt.
- This must not affect the ability to import an existing exported `.enc` backup because backups include a per-backup salt in the file header.

### Testing expectations

- Add/extend a widget test for `SettingsScreen` to assert:
	- required section headings exist
	- the “Sync & Backup (Coming in Phase 2)” tile is disabled
	- the density toggle updates UI state and calls the notifier
- Keep tests deterministic: do not rely on actual `SharedPreferences` disk state without using the standard test setup/mocks already used in the repo.

### Project Structure Notes

- Keep changes inside the feature-first structure: settings UI in `features/settings/`, preference logic reused from `features/daily/`.
- Avoid introducing new shared “settings” abstractions unless strictly necessary; prefer wiring existing providers and services.

## References

- `_bmad-output/planning-artifacts/epics.md` → Epic 7 / Story 7.1 acceptance criteria
- `lib/features/settings/presentation/settings_screen.dart` (current Settings UI baseline)
- `lib/features/daily/data/density_provider.dart` (density preference source of truth)
- `lib/core/encryption/encryption_service.dart` (`saltPrefsKey`)
- `lib/core/router/app_router.dart` (`/settings`, `/settings/sync`, `/settings/event-types`)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (initial implementation)
GPT-5.2 (post-review fixes)

### Debug Log References

- No blocking issues encountered.

### Implementation Plan

1. Added `package:shared_preferences` and `EncryptionService` + `DensityProvider` imports to `settings_screen.dart`.
2. Introduced shared `_SectionHeading` widget (13 sp, w600, letterSpacing 0.5) replacing the inline `Padding/Text` in `_BackupSection`.
3. Added `_DisplaySection` — `ConsumerWidget` that reads `densityModeProvider` and renders a `SwitchListTile`; toggle calls `notifier.toggle()` immediately (no save button).
4. Added `_EventTypesSection` — navigates to `ManageEventTypesRoute` via `const ManageEventTypesRoute().go(context)`; `Semantics` wrapper annotates the tile.
5. Added `_SyncPlaceholderSection` — `ListTile(enabled: false)` with subtitle "Coming in Phase 2"; `Semantics(enabled: false)` wrapper announces the disabled state to TalkBack.
6. Updated `_onResetBackupSettings()` to require confirmation + passphrase; delegates to `BackupRepository.resetBackupSettings(passphrase)` to rotate PBKDF2 salt safely.
7. All tiles use `minVerticalPadding: 12` (≥ 48 dp tap targets).

### Completion Notes List

- All 7 tasks completed in a single session; no new dependencies required.
- Reused 100% of existing providers (`densityModeProvider`, backup providers, router routes) per guardrails.
- Widget tests updated (`test/widget/settings_screen_test.dart`); full test suite passes.
- `flutter analyze` reports zero issues.

### Senior Developer Review (AI) — Fixes Applied

- Reset backup settings now rotates the per-install PBKDF2 salt safely by re-encrypting sensitive DB fields in a single transaction.
- Backup export/import ensure `EncryptionService.initialize(passphrase)` is called before decrypting/encrypting sensitive-at-rest fields.
- Settings UX tightened: exact AC3 copy, passphrase fields disable autocorrect/suggestions, and Sync placeholder no longer shows a chevron.

## File List

| File | Change |
|------|--------|
| `spetaka/lib/features/settings/presentation/settings_screen.dart` | Complete settings screen (sections, density toggle, event types link, Sync placeholder) + Reset backup settings wiring |
| `spetaka/lib/features/backup/data/backup_repository.dart` | Safe PBKDF2 salt rotation + ensures encryption initialization for export/import |
| `spetaka/lib/features/backup/providers/backup_providers.dart` | Added `BackupResetNotifier` for reset action state |
| `spetaka/lib/features/backup/providers/backup_providers.g.dart` | Generated provider updates |
| `spetaka/lib/core/database/daos/acquittement_dao.dart` | Added `updateAcquittement(...)` for transactional re-encryption |
| `spetaka/test/widget/settings_screen_test.dart` | Widget tests covering AC1-AC6 (copy assertion updated) |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | Status updated: ready-for-dev → in-progress → review → done |
| `_bmad-output/implementation-artifacts/7-1-complete-settings-screen.md` | Story updated (tasks, notes, status) |

## Change Log

- 2026-03-02: Story 7.1 implemented — complete settings screen with Display, Event Types and Sync placeholder sections, plus Reset backup settings action. 8 widget tests added. All 379 tests pass, zero lint issues. Status → review.
- 2026-03-02: Post-review fixes — safe reset backup settings (salt rotation + DB re-encryption), backup encryption initialization on export/import, tightened UX copy + placeholder affordance. Status → done.
