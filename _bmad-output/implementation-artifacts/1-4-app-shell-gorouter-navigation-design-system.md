# Story 1.4: App Shell, GoRouter Navigation & Design System

Status: ready-for-dev

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

- [ ] Build app shell entrypoint (AC: 1)
  - [ ] Wire `ProviderScope`
  - [ ] Configure `MaterialApp.router`
- [ ] Define router map and placeholders (AC: 2, 6)
  - [ ] Implement route tree in `app_router.dart`
  - [ ] Create placeholder screens for all declared routes
- [ ] Implement theme foundation (AC: 3, 4, 7)
  - [ ] Create tokens in `app_tokens.dart`
  - [ ] Build light/dark theme from tokens in `app_theme.dart`
- [ ] Add reusable UI states (AC: 5)
  - [ ] Create loading and error shared widgets
- [ ] Validate shell readiness (AC: 6)
  - [ ] Run app boot smoke test
  - [ ] Run `flutter analyze`

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

GPT-5.3-Codex

### Debug Log References

- Story generated in yolo batch progression for Epic 1.

### Completion Notes List

- Story 1.4 prepared in `ready-for-dev` format with explicit routing/theming guardrails.

### File List

- _bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md
