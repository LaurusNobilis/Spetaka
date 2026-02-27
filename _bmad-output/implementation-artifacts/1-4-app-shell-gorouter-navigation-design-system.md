# Story 1.4: App Shell, GoRouter Navigation & Design System

Status: in-progress

## Story

As a developer,
I want the complete app shell with GoRouter route tree, Material 3 theme, and all design tokens in place,
so that every feature screen has a consistent navigation framework and visual foundation to build upon.

## Acceptance Criteria

1. `lib/app.dart` contains `MaterialApp.router` with `GoRouter` and `ProviderScope`.
2. `lib/core/router/app_router.dart` defines typed route tree: `/`, `/friends`, `/friends/new`, `/friends/:id`, `/settings`, `/settings/sync`, each with placeholder screen title.
3. `lib/shared/theme/app_tokens.dart` defines design tokens (palette calm/warm, spacing, radius, typography with DM Sans + Lora, motion durations).
4. `lib/shared/theme/app_theme.dart` builds M3 `ThemeData` from tokens.
5. Reusable states exist: `lib/shared/widgets/loading_widget.dart` and `lib/shared/widgets/error_widget.dart`.
6. App launches on daily view placeholder with no crash, clean analysis, and navigable routes.
7. `MaterialApp.router` sets both `theme` and `darkTheme`; dark mode uses warm brown tokens and avoids cold fallback.

## Tasks / Subtasks

- [x] Build app shell entrypoint (AC: 1)
  - [x] Wire `ProviderScope`
  - [x] Configure `MaterialApp.router`
- [x] Define router map and placeholders (AC: 2, 6)
  - [x] Implement route tree in `app_router.dart`
  - [x] Create placeholder screens for all declared routes
- [x] Implement theme foundation (AC: 3, 4, 7)
  - [x] Create tokens in `app_tokens.dart`
  - [x] Build light/dark theme from tokens in `app_theme.dart`
- [x] Add reusable UI states (AC: 5)
  - [x] Create loading and error shared widgets
- [x] Validate shell readiness (AC: 6)
  - [x] Run app boot smoke test
  - [x] Run `flutter analyze`

### Review Follow-ups (AI)

- [ ] [AI-Review][HIGH] AC5 mismatch: story requires `lib/shared/widgets/error_widget.dart`, but implementation uses `lib/shared/widgets/app_error_widget.dart` (either align filename/exports or update AC/spec) [spetaka/lib/shared/widgets/app_error_widget.dart:5-12] [_bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md:17]
- [ ] [AI-Review][HIGH] App startup blocks on runtime font fetching (`await AppTheme.loadFonts()`), which risks slow/cold-start and offline failure; prefer bundling fonts as assets or make prefetch best-effort (no await / guarded) [spetaka/lib/main.dart:6-11] [spetaka/lib/shared/theme/app_theme.dart:18-27]
- [ ] [AI-Review][MEDIUM] `onBackground` is passed into `AppTheme._build` but never applied to the `ColorScheme`; additionally `colorScheme.surface` is set to `background`, which may break M3 semantics (surface vs background) [spetaka/lib/shared/theme/app_theme.dart:59-85]
- [ ] [AI-Review][MEDIUM] “Typed route tree” is only partially delivered: `AppRoute` classes exist but are not integrated for nested paths/navigation helpers; consider aligning typed route contracts with future screen widgets [spetaka/lib/core/router/app_router.dart:4-89]
- [ ] [AI-Review][MEDIUM] Epic spec names placeholder screens (DailyViewScreen/FriendsListScreen/etc) but implementation uses `_PlaceholderScreen` titles only; decide whether to introduce named placeholder widgets to stabilize downstream imports [spetaka/lib/core/router/app_router.dart:56-108]
- [ ] [AI-Review][MEDIUM] Dev Agent Record File List is incomplete vs git: `spetaka/pubspec.lock` changed in the implementation commit but is not listed here; add it for auditability [git show f0f6da6] [_bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md:84-96]
- [ ] [AI-Review][LOW] Route tests assert route presence but not navigability/expected placeholder titles per route; add navigation tests for `/friends/new`, `/settings/sync`, etc [spetaka/test/unit/app_shell_theme_test.dart:92-133]
- [ ] [AI-Review][LOW] Widget smoke tests wrap `SpetakaApp` in an extra `ProviderScope` even though the app already provides one; this can mask provider-scope mistakes [spetaka/test/widget_test.dart:16-31] [spetaka/lib/app.dart:12-20]

## Dev Notes

- Keep all token values centralized in `app_tokens.dart` to avoid divergence across features.
- Dark theme must follow warm palette constraints from UX specs.
- Route contracts here are foundational and should remain stable for downstream stories.

### Project Structure Notes

- Router assets stay under `lib/core/router/`.
- Theme assets stay under `lib/shared/theme/`.
- Reusable state widgets stay under `lib/shared/widgets/`.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.4.
- Source: `_bmad-output/planning-artifacts/architecture.md` — router and design system constraints.
- Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — typography and dark-mode warmth constraints.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- `AppTheme._build` initially called `GoogleFonts.dmSansTextTheme()` directly, triggering async
  HTTP fetches in tests → moved to `AppTheme.loadFonts()` startup helper; theme build now uses
  `TextStyle(fontFamily: AppTokens.fontBody)` — test-safe and production-correct.
- `widget_test.dart` had pre-existing broken import (`main.dart` does not export `SpetakaApp`)
  and unreachable text assertion (`MaterialApp.title` is OS-level, not rendered) → fixed both.
- `Color.red`/`.blue` deprecated in Flutter 3.x → replaced with `.r`/`.b` float getters.

### Completion Notes List

- AC1: `lib/app.dart` — `MaterialApp.router` + outer `ProviderScope` + `AppTheme.light/dark` wired (pre-existing, verified).
- AC2: `lib/core/router/app_router.dart` — typed route tree with all 6 paths + `_PlaceholderScreen` (pre-existing, verified).
- AC3: `lib/shared/theme/app_tokens.dart` — full token set: palette (calm/warm + dark brown), spacing, radius (14dp card), typography (DM Sans + Lora), motion (300ms easeInOutCubic).
- AC4: `lib/shared/theme/app_theme.dart` — `AppTheme.light()` + `AppTheme.dark()` from tokens; `AppTheme.loadFonts()` startup helper.
- AC5: `lib/shared/widgets/loading_widget.dart` + `app_error_widget.dart` — reusable loading/error state widgets.
- AC6: Boot smoke test passes — `Daily` placeholder renders, app launches with no crash.
- AC7: Dark theme uses `darkBackground: Color(0xFF1E1A17)` (deep warm brown) seeded through `ColorScheme.fromSeed(...).copyWith(surface: ...)` — cold grey avoided.
- `google_fonts: ^6.2.1` added to `pubspec.yaml` (resolved to 6.3.3).
- `lib/shared/shared.dart` barrel updated.
- 25 new tests added; `widget_test.dart` fixed; 63/63 tests green; `flutter analyze` clean.

### File List

- spetaka/lib/app.dart
- spetaka/lib/core/router/app_router.dart
- spetaka/lib/main.dart
- spetaka/lib/shared/shared.dart
- spetaka/lib/shared/theme/app_tokens.dart
- spetaka/lib/shared/theme/app_theme.dart
- spetaka/lib/shared/widgets/loading_widget.dart
- spetaka/lib/shared/widgets/app_error_widget.dart
- spetaka/pubspec.yaml
- spetaka/pubspec.lock
- spetaka/test/unit/app_shell_theme_test.dart
- spetaka/test/widget_test.dart

### Change Log

- 2026-02-27: Story 1.4 implemented — app shell shell verified, tokens + theme + shared widgets
  created, google_fonts added, 25 tests written, widget_test.dart boot regression fixed,
  63/63 tests green, flutter analyze clean. Status → review.

## Senior Developer Review (AI)

Reviewer: Laurus · Date: 2026-02-27

Outcome: Changes requested (action items added; no auto-fix applied)

Summary:
- Git vs story discrepancies: 1 (pubspec.lock changed but missing from File List prior to this review)
- Issues found: 2 High, 4 Medium, 2 Low

AC validation (against repo state at commit `f0f6da6`):
- AC1: IMPLEMENTED (ProviderScope + MaterialApp.router) [spetaka/lib/app.dart:12-20]
- AC2: IMPLEMENTED (route tree paths + placeholder titles) [spetaka/lib/core/router/app_router.dart:56-108]
- AC3: IMPLEMENTED (palette/spacing/radius/typography families/motion durations present) [spetaka/lib/shared/theme/app_tokens.dart]
- AC4: IMPLEMENTED (ThemeData from tokens) [spetaka/lib/shared/theme/app_theme.dart:29-110]
- AC5: PARTIAL (error widget exists but filename in AC/spec mismatches) [spetaka/lib/shared/widgets/app_error_widget.dart:5-12] [_bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md:17]
- AC6: IMPLEMENTED (analyze clean; tests green; daily placeholder renders) [spetaka/test/widget_test.dart:25-35]
- AC7: IMPLEMENTED (warm dark background token used) [spetaka/lib/shared/theme/app_tokens.dart]

Notes:
- No external doc search performed; review relies on in-repo specs (epics/architecture/UX) and code.
