# Story 4.7: Navigation Swipe — Daily View ↔ Friends List

Status: done

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

- [x] Create `spetaka/lib/features/shell/presentation/app_shell_screen.dart` hosting a `PageController` + `PageView` for the two root pages (AC: 1, 2)
- [x] Add a minimal 2-dot indicator widget in the shell (can live in the same file initially) using theme colors and `Semantics` (AC: 3, 8)
- [x] Provide a lightweight way for child widgets to trigger page changes (choose ONE):
	- InheritedWidget (`AppShellController.of(context)`), or
	- Riverpod provider that exposes `animateToPage(0/1)`
	(AC: 4)
- [x] Router refactor in `spetaka/lib/core/router/app_router.dart` to ensure:
	- The shell is always present for `/` and `/friends`.
	- Friend and settings subroutes are pushed above the shell (root navigator) so the `PageController` state is preserved.
	Implementation constraint (avoid ambiguous patterns):
	- Use a top-level `ShellRoute` whose builder returns `AppShellScreen`.
	- Define base “index routes” for `/` and `/friends` as no-op pages (e.g., `SizedBox.shrink()`) and let `AppShellScreen` render the actual Daily/Friends widgets.
	- Define detail routes (`/friends/:id`, `/friends/new`, event routes, `/settings`) with `parentNavigatorKey` set to the root navigator key so they overlay the shell.
	(AC: 6)
- [x] Remove the `people_outline` `IconButton` from `DailyViewScreen` and replace any remaining `FriendsRoute().go(...)` navigation used just to “switch tabs” with the shell controller (AC: 4)
- [x] Update any “return to friends list” flows that currently call `const FriendsRoute().go(context)` (notably in `FriendCardScreen`) to return appropriately without losing shell state (AC: 4, 6)
- [x] Implement back behaviour in the shell with `PopScope`:
	- If shell index == 1, consume the pop and animate to 0.
	- If shell index == 0, allow the inner page to handle back (e.g., DailyView collapses expanded card) (AC: 7)
- [x] Testing updates (keep them targeted and deterministic):
	- Update `spetaka/test/unit/app_shell_theme_test.dart` router expectations if route structure changes.
	- Add/adjust widget tests to cover: swipe changes page, back from Friends returns to Daily, page indicator semantics label present (AC: 2, 7, 8).

### Review Follow-ups (AI)

- [ ] [AI-Review][LOW] Fix `GoRouter.of(context).canPop()` called in `build()` — subscribes shell to all router changes; move to a listener or cache in `didChangeDependencies` [app_shell_screen.dart:131]
- [ ] [AI-Review][LOW] Story 5.1 AC8 touch-target test fails (pre-existing); Story 5.4 acquittement rows and Story 8.4 last-contact tests also fail. Track in respective story artifacts so full suite runs don't mask 4.7 regressions.

## Dev Notes

- Sprint tracking: this story key is listed in `_bmad-output/implementation-artifacts/sprint-status.yaml`; keep story and sprint status synchronized when review outcomes change.
- Do not hard-code palette values in UI; use `Theme.of(context).colorScheme.*` (the project tokens live in `spetaka/lib/shared/theme/app_tokens.dart`).
- Keep the shell responsible only for root navigation between the two pages; do not introduce additional navigation affordances beyond the page indicator.
- Regression watch-outs:
	- Daily View has its own `PopScope` for the expanded card: make sure the shell back handler does not prevent that logic from running when index == 0.
	- Ensure horizontal swipe does not interfere with vertical scroll gestures inside `CustomScrollView` / `ListView`.
- Localisation: any new semantics labels or tooltips introduced by this story must use existing l10n patterns (`context.l10n.*`).

### References

- `_bmad-output/implementation-artifacts/1-4-app-shell-gorouter-navigation-design-system.md` — existing router conventions
- `spetaka/lib/core/router/app_router.dart` — current GoRouter configuration
- `spetaka/lib/core/router/app_route_types.dart` — shell-aware route helpers (`HomeRoute` / `FriendsRoute`)
- `spetaka/lib/features/daily/presentation/daily_view_screen.dart` — current `people_outline` action + `PopScope`
- `spetaka/lib/features/friends/presentation/friend_card_screen.dart` — current “go back to friends list” route usage
- `spetaka/lib/features/friends/presentation/friend_form_screen.dart` — edit-mode return flow above shell overlays
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart` — Friends list root page

## Dev Agent Record

### Agent Model Used

GPT-5.4

### Debug Log References

- `flutter test test/widget/app_shell_screen_test.dart test/unit/app_shell_theme_test.dart --reporter=compact` → `+39: All tests passed!`
- `flutter test test/widget/app_shell_screen_test.dart --reporter=compact` → `+10: All tests passed!` (2 new AC6 event-route tests added)
- `flutter test test/widget/friend_form_screen_test.dart --name "4.7/AC6" --reporter=compact` → `+1: All tests passed!` (M2 real-shell edit-save test)

### Completion Notes List

- Finalized the GoRouter shape so the shell remains mounted for direct deep links and overlay routes while staying within GoRouter's immediate-child navigator constraints.
- Added `initialLocation` support to `createAppRouter()` so regression tests can start directly on overlay routes and verify that the shell still exists underneath.
- Kept overlay routes nested under the base shell routes (`/` and `/friends`) with `parentNavigatorKey: _rootNavigatorKey`; an intermediate attempt to make them direct `ShellRoute` children was rejected because GoRouter asserts those children must share the shell navigator key.
- Hardened shell regression coverage for direct `/friends/new` and `/settings` startup, and updated router tests to reconstruct full nested paths.

### File List

- `spetaka/lib/core/router/app_router.dart`
- `spetaka/lib/core/router/app_route_types.dart`
- `spetaka/lib/features/shell/presentation/app_shell_screen.dart`
- `spetaka/lib/features/daily/presentation/daily_view_screen.dart`
- `spetaka/lib/features/daily/presentation/heart_briefing_widget.dart`
- `spetaka/lib/features/friends/presentation/friend_card_screen.dart`
- `spetaka/lib/features/friends/presentation/friend_form_screen.dart`
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart`
- `spetaka/lib/core/l10n/app_localizations.dart`
- `spetaka/lib/core/l10n/app_localizations_en.dart`
- `spetaka/lib/core/l10n/app_localizations_fr.dart`
- `spetaka/lib/l10n/app_en.arb`
- `spetaka/lib/l10n/app_fr.arb`
- `spetaka/test/widget/app_shell_screen_test.dart`
- `spetaka/test/widget/friend_form_screen_test.dart`
- `spetaka/test/unit/app_shell_theme_test.dart`

## Senior Developer Review (AI)

Date: 2026-03-26

### Outcome

**Changes Requested** — le shell swipe est globalement en place, mais AC6 n'est toujours pas garanti sur tous les flux réels, et la story n'est pas suffisamment tenue à jour pour un audit fiable.

### Findings

#### 🔴 HIGH

1. **Le flux “éditer un ami puis revenir à sa fiche” contourne encore le contrat shell + overlay et peut perdre l'état de navigation sous-jacent.**
	- La story exige que les sous-routes restent au-dessus du shell sans reset d'état (`/friends/:id`, `/friends/new`, routes événements, `/settings`).
	- Or `FriendFormScreen` termine l'édition avec `FriendDetailRoute(widget.editFriendId!).go(context)`, ce qui remplace la pile au lieu de revenir sur l'overlay existant.
	- Avec la configuration actuelle du routeur, `/friends/:id` est une route racine sœur du `ShellRoute`, pas une sous-route avec `parentNavigatorKey` attachée au shell. Ce flux ne garantit donc pas le retour au contexte Daily/Friends précédent après édition.

#### 🟡 MEDIUM

2. **Le `Dev Agent Record -> File List` est incomplet par rapport à l'implémentation réelle de 4.7.**
	- La task list et les références de la story mentionnent explicitement `friend_card_screen.dart` comme flux à adapter, mais ce fichier n'apparaît pas dans le `File List` final.
	- La logique clé qui fait basculer `HomeRoute` / `FriendsRoute` vers le contrôleur de shell vit désormais dans `spetaka/lib/core/router/app_route_types.dart`, mais ce fichier n'est pas documenté non plus.
	- Résultat: la surface réellement modifiée pour satisfaire AC4/AC6 n'est pas traçable depuis l'artefact.

3. **La story est en statut implémenté/revue alors que toutes les tâches restent non cochées.**
	- Les subtâches 4.7 sont toujours toutes en `- [ ]` alors que la story contient déjà une implémentation, des tests et plusieurs entrées de change log.
	- Cela bloque l'audit “tasks claimed done vs code reality” demandé par le workflow de review et rend l'état d'avancement ambigu.

4. **La couverture de tests ne protège pas les autres flux AC6 au-delà du cas Daily -> fiche ami.**
	- Le test widget couvre le swipe, le back Android, le label TalkBack et un seul scénario de préservation d'état: ouverture de fiche ami depuis Daily puis retour.
	- En revanche, la story exige le même contrat pour `/friends/new`, `/friends/:id/events/new`, `/friends/:id/events/:eventId/edit` et `/settings`.
	- Les tests unitaires actuels valident surtout l'existence ou l'accessibilité des routes, pas la préservation effective de l'état du shell sur ces parcours.

Date: 2026-03-25

### Outcome

**Changes Requested** — the PageView shell is present and the basic swipe/back interactions work, but AC6 is not fully met and the story record is not review-complete.

### Findings

#### 🔴 HIGH

1. **Opening `/friends/:id` from Daily can change the underlying shell page, so swipe state is not preserved on return.**
	- `DailyViewScreen` opens detail via `FriendDetailRoute(friend.id).push(context)`.
	- `AppShellScreen` maps any path starting with `/friends` to index `1` and re-syncs when the current path starts with `/friends`.
	- That means opening a friend detail from Daily can flip the shell to Friends behind the overlay, violating AC6 and the earlier promise that returning from friend detail preserves the Daily context.

2. **Heart Briefing still replaces location with `go()` instead of pushing above the shell.**
	- `HeartBriefingWidget` uses `FriendDetailRoute(friend.id).go(context)`.
	- Story 4.7 explicitly requires detail routes to be pushed above the shell so the current shell page is preserved. This flow bypasses that contract and can drop the current Daily state from navigation history.

3. **Overlay routes are not configured with `parentNavigatorKey: _rootNavigatorKey`, despite the story requirement.**
	- `/friends/new`, `/friends/:id`, and `/settings` are declared as children of the `ShellRoute`, but none set `parentNavigatorKey`.
	- GoRouter’s default behavior is to place ShellRoute children on the shell navigator, so the implementation diverges from both the story task list and the epic acceptance criteria.

#### 🟡 MEDIUM

4. **The story artifact is stale and incomplete for a code review.**
	- The existing review block still says there was no implementation and that the story was `ready-for-dev`, which is now false.
	- `Dev Agent Record` still has no `File List`, so the delivered source changes cannot be audited against a declared implementation surface.

5. **Tests miss the key AC6 preservation path.**
	- Current tests cover swipe, Android back from Friends, semantics label, and route reachability.
	- No test verifies that opening a friend detail from Daily preserves the shell page on return, and no test asserts the required root-navigator overlay behavior.


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

- 2026-03-27: Code review pass — AC6 event-route tests added (add-event and edit-event overlays preserve shell page), M2 real-shell edit-save test added, L1 _isSyncingFromRouter stuck-flag bug fixed; status confirmed done.
- 2026-03-26: Review follow-up fixes applied — edit-save now pops back to stacked detail overlays, AC6 widget coverage expanded for `/friends/new` and `/settings`, File List/tasks synchronized, status → review.

- 2026-03-26: Senior dev code review — status set to in-progress; changes requested for edit-return shell preservation, File List traceability, unchecked task audit, and broader AC6 regression coverage.
- 2026-03-27: Auto-fix pass completed — overlay routing was finalized with shell-preserving nested root overlays, direct-start regression tests were added, targeted shell/router validation passed, and the story status moved to done.

## Senior Developer Review Follow-up (AI)

### Reviewer

GPT-5.4

### Findings Resolved

- Reworked the shell overlay route tree so direct starts such as `/friends/new` and `/settings` preserve the underlying `AppShellScreen` instead of bypassing or remounting it.
- Corrected the router regression tests so nested shell subroutes are asserted by full path rather than by raw segment.
- Added explicit regression coverage for starting on shell-overlay routes and confirming the `PageView` stays mounted beneath the overlay.

### Validation

- `flutter test test/widget/app_shell_screen_test.dart test/unit/app_shell_theme_test.dart --reporter=compact`
- `flutter test test/widget/app_shell_screen_test.dart test/widget/friend_form_screen_test.dart test/widget/friend_card_screen_test.dart test/unit/app_shell_theme_test.dart --reporter=compact` — unrelated Story 5.1 `friend_card_screen_test.dart` failures remain; no 4.7-specific regressions observed.

- 2026-03-26: Flutter retest passed for `test/widget/app_shell_screen_test.dart` and `test/unit/app_shell_theme_test.dart` after root-level overlay routing and shell-test stabilization.
- 2026-03-25: Review fixes applied — shell base-path sync constrained, overlay routes moved to root navigator, Heart Briefing detail navigation changed to push, AC6 regression tests added, status → review.
- 2026-03-25: Senior dev code review — status set to in-progress; changes requested for shell-state preservation, root-navigator overlays, story traceability, and AC6 test coverage.
- 2026-03-05: Senior dev code review — Blocked (no implementation delivered yet; ACs not verifiable).
- 2026-03-05: Implémentation livrée — statut → review (shell PageView + routeur ShellRoute + tests).
