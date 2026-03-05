# Story 4.7: Navigation Swipe — Daily View ↔ Friends List

Status: review

## Story

As Laurus,
I want to swipe left/right to switch between the Daily View and the Friends List,
so that navigation between the two main screens feels fluid and natural.

## Acceptance Criteria

1. A horizontal `PageView` (index 0 = Daily View, index 1 = Friends List) is hosted in a new `AppShellScreen` widget.
2. Swiping left from Daily View navigates to Friends List; swiping right from Friends List navigates back to Daily View.
3. A subtle 2-dot page indicator at the bottom of the shell reflects the active page. The active dot uses `Theme.of(context).colorScheme.primary` (no hard-coded hex values).
4. The `people_outline` `IconButton` in the Daily View `AppBar` is removed. Any “go to Friends list” behaviour uses the shared shell controller (`PageController`) rather than swapping routes.
5. `PopScope` on `DailyViewScreen` (collapse expanded card before app exit) remains correct and does not conflict with horizontal swipe. The shell must not break vertical scrolling inside either page.
6. GoRouter sub-routes remain functional and are pushed on top of the shell without resetting swipe state: `/friends/:id`, `/friends/new`, `/friends/:id/events/new`, `/friends/:id/events/:eventId/edit`, `/settings`, etc.
7. Android back/system button behaviour:
	 - From Friends List (index 1): animates back to Daily View (index 0) and does not exit.
	 - From Daily View (index 0): default back behaviour applies (i.e., inner `DailyViewScreen` can collapse expanded card; otherwise app exits).
8. TalkBack: both pages are fully traversable; the page indicator has a meaningful semantics label (localized).

## Tasks / Subtasks

- [ ] Create `spetaka/lib/features/shell/presentation/app_shell_screen.dart` hosting a `PageController` + `PageView` for the two root pages (AC: 1, 2)
- [ ] Add a minimal 2-dot indicator widget in the shell (can live in the same file initially) using theme colors and `Semantics` (AC: 3, 8)
- [ ] Provide a lightweight way for child widgets to trigger page changes (choose ONE):
	- InheritedWidget (`AppShellController.of(context)`), or
	- Riverpod provider that exposes `animateToPage(0/1)`
	(AC: 4)
- [ ] Router refactor in `spetaka/lib/core/router/app_router.dart` to ensure:
	- The shell is always present for `/` and `/friends`.
	- Friend and settings subroutes are pushed above the shell (root navigator) so the `PageController` state is preserved.
	Implementation constraint (avoid ambiguous patterns):
	- Use a top-level `ShellRoute` whose builder returns `AppShellScreen`.
	- Define base “index routes” for `/` and `/friends` as no-op pages (e.g., `SizedBox.shrink()`) and let `AppShellScreen` render the actual Daily/Friends widgets.
	- Define detail routes (`/friends/:id`, `/friends/new`, event routes, `/settings`) with `parentNavigatorKey` set to the root navigator key so they overlay the shell.
	(AC: 6)
- [ ] Remove the `people_outline` `IconButton` from `DailyViewScreen` and replace any remaining `FriendsRoute().go(...)` navigation used just to “switch tabs” with the shell controller (AC: 4)
- [ ] Update any “return to friends list” flows that currently call `const FriendsRoute().go(context)` (notably in `FriendCardScreen`) to return appropriately without losing shell state (AC: 4, 6)
- [ ] Implement back behaviour in the shell with `PopScope`:
	- If shell index == 1, consume the pop and animate to 0.
	- If shell index == 0, allow the inner page to handle back (e.g., DailyView collapses expanded card) (AC: 7)
- [ ] Testing updates (keep them targeted and deterministic):
	- Update `spetaka/test/unit/app_shell_theme_test.dart` router expectations if route structure changes.
	- Add/adjust widget tests to cover: swipe changes page, back from Friends returns to Daily, page indicator semantics label present (AC: 2, 7, 8).

## Dev Notes

- Sprint tracking: this story key is not currently listed in `_bmad-output/implementation-artifacts/sprint-status.yaml`; add it there before starting implementation so status updates are visible.
- Do not hard-code palette values in UI; use `Theme.of(context).colorScheme.*` (the project tokens live in `spetaka/lib/shared/theme/app_tokens.dart`).
- Keep the shell responsible only for root navigation between the two pages; do not introduce additional navigation affordances beyond the page indicator.
- Regression watch-outs:
	- Daily View has its own `PopScope` for the expanded card: make sure the shell back handler does not prevent that logic from running when index == 0.
	- Ensure horizontal swipe does not interfere with vertical scroll gestures inside `CustomScrollView` / `ListView`.
- Localisation: any new semantics labels or tooltips introduced by this story must use existing l10n patterns (`context.l10n.*`).

### References

- `_bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md` — existing router conventions
- `spetaka/lib/core/router/app_router.dart` — current GoRouter configuration
- `spetaka/lib/features/daily/presentation/daily_view_screen.dart` — current `people_outline` action + `PopScope`
- `spetaka/lib/features/friends/presentation/friend_card_screen.dart` — current “go back to friends list” route usage
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart` — Friends list root page

## Dev Agent Record

### Agent Model Used

GPT-5.2

## Senior Developer Review (AI)

Date: 2026-03-05

### Outcome

**Blocked / Changes Requested** — impossible de valider les Acceptance Criteria car aucune implémentation n’est livrée pour cette story.

### Git vs Story Discrepancies

- Le fichier de story `4-7-swipe-navigation-daily-friends.md` n’est pas suivi par git (fichier non tracké) et aucun changement applicatif correspondant n’apparaît dans `git diff`.
- La story est en statut `ready-for-dev` (pas `review`) et ne contient pas de “Dev Agent Record” ni de “File List” d’implémentation.

### Findings

#### 🔴 HIGH

1. **AC1/AC2 non implémentés (shell PageView absent).**
	- Aucun `PageView`/`PageController` n’existe actuellement dans `lib/`.
	- Il n’existe pas de widget `AppShellScreen` qui hoste les deux pages racines.

2. **AC4 non satisfait : le bouton `people_outline` est toujours présent dans la Daily View et navigue via route.**
	- Preuve: `DailyViewScreen` contient encore `Icon(Icons.people_outline)` (voir `daily_view_screen.dart:116`) et fait `FriendsRoute().go(context)`.

3. **AC6 non satisfait : la configuration GoRouter ne suit pas la contrainte “ShellRoute top-level + detail routes en overlay root navigator”.**
	- Preuve: le routeur construit `/` → `DailyViewScreen` (`app_router.dart:117`) et imbrique `friends` (`app_router.dart:120`) au lieu d’un `ShellRoute` qui encapsule un shell permanent.
	- Risque: refactor nécessaire pour préserver l’état de swipe lorsque des sous-routes (friend detail, settings, event edit, etc.) s’empilent.

4. **AC7 non implémenté : comportement back Android demandé au niveau du shell inexistant.**
	- L’app ne peut pas “revenir à la page 0” depuis Friends List via animation PageController sans shell.

#### 🟡 MEDIUM

5. **AC5 risque d’interaction PopScope (back) :** `DailyViewScreen` possède déjà un `PopScope` pour replier la carte étendue. Le futur shell devra coopérer (ne pas consommer le back quand index == 0) sinon régression.

6. **AC8 non implémenté :** aucun indicateur 2-points (donc aucune `Semantics` localisée) n’existe encore.

7. **Sprint tracking manquant :** la story indique qu’elle n’est pas listée dans `sprint-status.yaml` ; c’est toujours le cas. Sans tracking, les statuts ne seront pas synchronisés.

#### 🟢 LOW

8. **Dette/ambiguïté :** il existe déjà `spetaka/lib/features/app_shell/app_shell.dart` (placeholder non utilisé). La story propose de créer un nouveau shell (`AppShellScreen`) : risque de duplication/naming confusion. Préférer réutiliser/renommer l’existant ou supprimer le placeholder une fois le vrai shell créé.

### Recommended Next Actions (Dev)

- Passer par un workflow de dev (DS) pour implémenter réellement la story avec une “File List” + tests.
- Implémenter un shell PageView (AC1/2/3/7/8), puis refactor GoRouter vers une structure `ShellRoute` (AC6) en gardant `DailyViewScreen` PopScope intact (AC5).
- Remplacer toute navigation “switch page” via routes (ex: `FriendsRoute().go`) par un contrôleur de shell (InheritedWidget ou Riverpod) (AC4).
- Ajouter/ajuster tests widget: swipe change page + back from index 1 returns index 0 + semantics label sur l’indicator.

## Handoff

- Implémentation du shell `PageView` + indicateur (a11y) + back Android.
- Refactor routeur via `ShellRoute` + routes base `/` et `/friends` (no-op), sous-routes rendues au-dessus du shell sans reset.
- Tests ciblés ajoutés/ajustés (router + swipe/back + semantics).

## Change Log

- 2026-03-05: Senior dev code review — Blocked (no implementation delivered yet; ACs not verifiable).
- 2026-03-05: Implémentation livrée — statut → review (shell PageView + routeur ShellRoute + tests).
