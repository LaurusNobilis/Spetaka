# Story 1.4: App Shell, GoRouter Navigation & Design System

Status: review

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
- spetaka/test/unit/app_shell_theme_test.dart
- spetaka/test/widget_test.dart

### Change Log

- 2026-02-27: Story 1.4 implemented — app shell shell verified, tokens + theme + shared widgets
  created, google_fonts added, 25 tests written, widget_test.dart boot regression fixed,
  63/63 tests green, flutter analyze clean. Status → review.
