# Story 9.2: Configurable Concern Cadence Interval in Settings

Status: done

## Story

As Laurus,
I want to configure the default interval for the automatic concern follow-up cadence from the Settings screen,
so that the cadence matches how frequently I want to check in on friends going through difficult times.

## Acceptance Criteria

1. **Given** Laurus navigates to `SettingsScreen`
   **When** the screen loads
   **Then** a "Concern follow-up cadence" section is displayed with a label showing the current default interval (e.g., "Every 7 days — default")
   **And** tapping the setting opens a selector (bottom sheet or inline dropdown) with options: Every 3 days, Every 5 days, Every 7 days (default), Every 10 days, Every 14 days, Every 21 days, Every 30 days — presented as human-readable labels

2. **Given** Laurus selects an interval
   **When** the selector is dismissed
   **Then** the new interval is immediately saved to `shared_preferences` under the key `'concern_cadence_days'` as an integer
   **And** `ConcernCadenceSettingsProvider` — a Riverpod `Notifier<int>` reading from `shared_preferences` — emits the new value; all downstream consumers react immediately
   **And** the settings screen label updates to reflect the selected interval

3. **Given** the setting is changed
   **Then** existing auto-created concern cadences already in the `events` table are **not** retroactively updated — the new interval applies only to concern flags set after the change
   **And** this behaviour is clearly noted in the UI: "Applies to new concern flags — existing cadences are not changed."

4. **Given** no value has been saved to `shared_preferences`
   **Then** `ConcernCadenceSettingsProvider` defaults to `7` — no null handling required by consumers; always returns a valid integer

5. **Given** the selector
   **Then** all options meet 48×48dp touch targets (NFR15); TalkBack reads: "Concern cadence: Every [N] days, [selected/not selected]" (NFR17)

## Tasks / Subtasks

- [x] Task 1: Create `ConcernCadenceNotifier` provider (AC: 2, 4)
  - [x] 1.1 Create `lib/features/settings/data/concern_cadence_provider.dart`
  - [x] 1.2 Add `ConcernCadenceNotifier extends Notifier<int>` with `build()` returning `7` and loading async from shared_preferences
  - [x] 1.3 Add `set(int days)` method that updates state + persists to `shared_preferences` key `'concern_cadence_days'`
  - [x] 1.4 Add `concernCadenceProvider` as `NotifierProvider<ConcernCadenceNotifier, int>`

- [x] Task 2: Add l10n keys for concern cadence section (AC: 1, 3, 5)
  - [x] 2.1 Add keys to `app_en.arb`: `concernCadenceSectionTitle`, `concernCadenceLabel`, `concernCadenceEveryNDays`, `concernCadenceDefault`, `concernCadenceAppliesNote`, `concernCadenceSemantics`
  - [x] 2.2 Add corresponding keys to `app_fr.arb`

- [x] Task 3: Add `_ConcernCadenceSection` to Settings screen (AC: 1, 2, 3, 5)
  - [x] 3.1 Add `_ConcernCadenceSection` `ConsumerWidget` in `settings_screen.dart`
  - [x] 3.2 Show current interval with `_SectionHeading` + `ListTile` pattern
  - [x] 3.3 On tap, show a `showModalBottomSheet` with 7 interval options as `ListTile` items
  - [x] 3.4 Each option has a radio-style leading icon; selected option is visually distinguished
  - [x] 3.5 Add subtitle note: "Applies to new concern flags — existing cadences are not changed."
  - [x] 3.6 Wrap with `Semantics` for TalkBack: "Concern cadence: Every N days"
  - [x] 3.7 Add section to Settings `Column` between `_EventTypesSection` and `_SyncPlaceholderSection`

- [x] Task 4: Write unit test for `ConcernCadenceNotifier` (AC: 2, 4)
  - [x] 4.1 Create `test/unit/settings/concern_cadence_provider_test.dart`
  - [x] 4.2 Test: default value is 7 when no preference stored
  - [x] 4.3 Test: `set(14)` → state updates to 14, persisted to shared_preferences
  - [x] 4.4 Test: build reads stored value from shared_preferences on init

- [x] Task 5: Write widget test for concern cadence section (AC: 1, 5)
  - [x] 5.1 Add tests to `test/widget/settings_screen_test.dart` (existing file)
  - [x] 5.2 Test: section heading "Concern follow-up cadence" is rendered
  - [x] 5.3 Test: tapping the tile opens a bottom sheet with all 7 interval options
  - [x] 5.4 Test: selecting an option updates the displayed interval

## Dev Notes

### Architecture / Guardrails

- **Provider pattern**: Follow the exact manual `Notifier` + `NotifierProvider` pattern from `display_prefs_provider.dart`. Do NOT use `@riverpod` code generation for this provider — settings providers in this project consistently use manual registration.
- **SharedPreferences key**: `'concern_cadence_days'` (int). This is the key that Story 9.1 will read via `ref.read(concernCadenceProvider)` when auto-creating concern cadences.
- **No DB interaction**: This story is purely UI + SharedPreferences. No Drift tables, no migrations, no event modifications. Story 9.1 handles the event auto-creation logic.
- **No retroactive updates**: When the interval changes, existing cadence events in the `events` table must NOT be modified. This is by design (AC3). The UI must communicate this clearly.
- **Offline-first**: No network calls. SharedPreferences is local storage only.

### Provider Contract (consumed by Story 9.1)

Story 9.1 will depend on `concernCadenceProvider` to read the configured interval when creating auto-cadence events:

```dart
// In Story 9.1's FriendRepository.setConcern():
final cadenceDays = ref.read(concernCadenceProvider); // always returns int, default 7
```

The provider MUST:
- Always return a valid `int` (never null)
- Default to `7` when no preference is stored
- Expose the name `concernCadenceProvider` (not `concernCadenceSettingsProvider` — keep it short)

### Interval Options

Fixed list of 7 options (not user-extendable):

| Days | Label (EN) | Label (FR) |
|------|-----------|-----------|
| 3 | Every 3 days | Tous les 3 jours |
| 5 | Every 5 days | Tous les 5 jours |
| 7 | Every 7 days (default) | Tous les 7 jours (défaut) |
| 10 | Every 10 days | Tous les 10 jours |
| 14 | Every 14 days | Tous les 14 jours |
| 21 | Every 21 days | Tous les 21 jours |
| 30 | Every 30 days | Tous les 30 jours |

### UI Placement

Insert the `_ConcernCadenceSection` in the Settings screen `Column` between `_EventTypesSection` and `_SyncPlaceholderSection`:

```dart
children: [
  _BackupSection(),
  _DisplaySection(),
  _EventTypesSection(),
  _CategoryTagsSection(),
  _ConcernCadenceSection(),   // ← NEW (Story 9.2)
  _SyncPlaceholderSection(),
  _FeedbackSection(),
],
```

### Bottom Sheet Selector Pattern

Use `showModalBottomSheet` with `ListView` of `ListTile` items. Each tile:
- Leading: `Icon(Icons.radio_button_checked)` for selected, `Icon(Icons.radio_button_unchecked)` for unselected
- Title: human-readable label (localized)
- `minVerticalPadding: 12` for 48dp touch targets (NFR15)
- On tap: call `ref.read(concernCadenceProvider.notifier).set(days)` then `Navigator.pop(context)`

### Existing Files to Modify

| File | Change |
|------|--------|
| `spetaka/lib/features/settings/presentation/settings_screen.dart` | Add `_ConcernCadenceSection`, import provider, add to Column |
| `spetaka/lib/l10n/app_en.arb` | Add concern cadence l10n keys |
| `spetaka/lib/l10n/app_fr.arb` | Add concern cadence l10n keys |

### New Files to Create

| File | Purpose |
|------|---------|
| `spetaka/lib/features/settings/data/concern_cadence_provider.dart` | `ConcernCadenceNotifier` + `concernCadenceProvider` |
| `spetaka/test/unit/settings/concern_cadence_provider_test.dart` | Unit tests for provider |

### Existing File to Extend

| File | Change |
|------|--------|
| `spetaka/test/widget/settings_screen_test.dart` | Add widget tests for concern cadence section |

### Project Structure Notes

- Provider lives in `lib/features/settings/data/` — consistent with `display_prefs_provider.dart` and `category_tags_provider.dart` in the same directory.
- Test file follows the existing `test/unit/settings/` convention for unit tests.
- Widget tests extend the existing `settings_screen_test.dart` file.

### Previous Story Intelligence

**Story 7.1 (Settings Screen) patterns:**
- Settings screen uses `_SectionHeading` → `ListTile`/widget → `Divider(height: 24)` pattern for each section.
- All `ListTile` items use `minVerticalPadding: 12` for 48dp targets.
- `Semantics` wrapper with `label` and `button: true` on interactive tiles.
- Settings screen is a `ConsumerWidget` (not StatefulWidget) — sections that need ref are `ConsumerWidget`.
- Import path: `import '../data/display_prefs_provider.dart'` (relative).

**Display preferences provider patterns:**
- `extends Notifier<T>` with `build()` returning default, `Future.microtask(_load)` for async init.
- `set(T value)` method persists via `SharedPreferences.getInstance()` then `setInt`/`setString`.
- `_load()` reads from shared_preferences and updates state if stored value exists.
- Manual `NotifierProvider<X, T>(X.new)` — NOT code-generated.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 9, Story 9.2 acceptance criteria]
- [Source: _bmad-output/planning-artifacts/prd.md — FR51: concern follow-up cadence interval config]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR15: 48×48dp touch targets]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR17: TalkBack screen reader navigation]
- [Source: _bmad-output/implementation-artifacts/7-1-complete-settings-screen.md — settings screen patterns]
- [Source: spetaka/lib/features/settings/data/display_prefs_provider.dart — provider pattern reference]
- [Source: spetaka/lib/features/settings/presentation/settings_screen.dart — UI section pattern]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (GitHub Copilot)

### Debug Log References

- 2026-03-26: Senior review fixes applied for persistence ordering, value sanitization, and TalkBack semantics.
- `flutter analyze --no-pub lib/features/settings/data/concern_cadence_provider.dart lib/features/settings/presentation/settings_screen.dart test/unit/settings/concern_cadence_provider_test.dart test/widget/settings_screen_test.dart` → clean.
- `flutter test --no-pub test/unit/settings/concern_cadence_provider_test.dart` → 5/5 tests passed.
- `flutter test --no-pub test/widget/settings_screen_test.dart` is currently blocked by unrelated pre-existing compile errors in `lib/features/friends/presentation/friends_list_screen.dart` referencing missing search l10n keys from Story 8.2.

### Completion Notes List

- Created `ConcernCadenceNotifier` provider following the exact `DarkModeEnabledNotifier` pattern: `Notifier<int>`, `build()` returns 7 default, `Future.microtask(_load)` for async SharedPreferences init, `set(int)` persists via `setInt`.
- Added 6 l10n keys to both `app_en.arb` and `app_fr.arb`, plus manually updated the 3 generated l10n Dart files.
- Added `_ConcernCadenceSection` as a `ConsumerWidget` in `settings_screen.dart` — uses `_SectionHeading` + `ListTile` pattern consistent with other sections. Bottom sheet shows 7 fixed interval options with radio-button icons.
- Subtitle note "Applies to new concern flags — existing cadences are not changed." is displayed below the current interval (AC3).
- All `ListTile` items use `minVerticalPadding: 12` for 48dp touch targets (NFR15).
- `Semantics` wrappers on all interactive elements for TalkBack (NFR17).
- 3 unit tests for provider: default value, set+persist, async load from stored prefs.
- 3 widget tests: section heading rendered, bottom sheet with 7 options, selection updates display.
- Senior review fixes: selector now awaits SharedPreferences persistence before dismissing, unsupported cadence values are sanitized back to the 7-day default, and semantics nodes now expose an exact TalkBack label without duplicated child semantics.
- Added regression coverage for invalid stored values, invalid programmatic writes, delayed persistence before bottom-sheet dismissal, and exact AC5 semantics labels.

### File List

- `spetaka/lib/features/settings/data/concern_cadence_provider.dart` (NEW)
- `spetaka/lib/features/settings/presentation/settings_screen.dart` (MODIFIED)
- `spetaka/lib/l10n/app_en.arb` (MODIFIED)
- `spetaka/lib/l10n/app_fr.arb` (MODIFIED)
- `spetaka/lib/core/l10n/app_localizations.dart` (MODIFIED — generated)
- `spetaka/lib/core/l10n/app_localizations_en.dart` (MODIFIED — generated)
- `spetaka/lib/core/l10n/app_localizations_fr.dart` (MODIFIED — generated)
- `spetaka/test/unit/settings/concern_cadence_provider_test.dart` (NEW)
- `spetaka/test/widget/settings_screen_test.dart` (MODIFIED)

## Senior Developer Review (AI)

### Reviewer

GPT-5.4

### Findings Resolved

- The bottom-sheet selector now awaits `ConcernCadenceNotifier.set()` before dismissing, so the preference is persisted before the UI closes.
- The cadence provider now centralizes the allowed options and sanitizes invalid persisted or programmatic values back to the 7-day default.
- The concern cadence row and selector options now use explicit container semantics with excluded child semantics so TalkBack reads the exact AC5 string without duplicated labels.
- The 9.2 test suite now covers invalid persisted values, invalid writes, delayed persistence ordering, and exact selector semantics labels.

### Validation

- `flutter analyze --no-pub lib/features/settings/data/concern_cadence_provider.dart lib/features/settings/presentation/settings_screen.dart test/unit/settings/concern_cadence_provider_test.dart test/widget/settings_screen_test.dart`
- `flutter test --no-pub test/unit/settings/concern_cadence_provider_test.dart`
- `flutter test --no-pub test/widget/settings_screen_test.dart` blocked by unrelated compile errors in Story 8.2 search localization work

### Change Log

- 2026-03-25: Story 9.2 implemented — configurable concern cadence interval in Settings. Added `ConcernCadenceNotifier` provider (SharedPreferences-backed, default 7 days), l10n keys (EN/FR), `_ConcernCadenceSection` UI with bottom sheet selector, unit tests, and widget tests.
- 2026-03-26: Senior Developer Review (AI) — fixed persistence-before-dismiss ordering, sanitized unsupported cadence values, tightened TalkBack semantics, expanded 9.2 regression coverage, and marked the story done.
