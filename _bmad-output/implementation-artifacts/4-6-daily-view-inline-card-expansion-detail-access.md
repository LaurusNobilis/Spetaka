# Story 4.6: Daily View — Inline Card Expansion & Detail Access

Status: done

## Story
As Laurus, I want inline card expansion in daily view so I can act without leaving the ritual screen.

## Acceptance Criteria
1. Tap on collapsed card expands inline with `AnimatedSize` + `AnimatedCrossFade` (300ms easeInOutCubic).
2. Expanded card reveals action row, last note, and `Full details` link.
3. Only one card expanded at a time.
4. Back gesture collapses expanded card before app exit.
5. `Full details` navigates to `/friends/:id`; return preserves scroll and collapsed state.
6. Accessibility labels/hints and 48x48dp targets are met.
7. Animation target is 60fps on Samsung S25.

## Tasks
- [ ] Implement inline expand/collapse controller.
- [ ] Add expanded content layout and single-expanded-card rule.
- [ ] Implement back behavior and detail navigation.
- [ ] Add accessibility semantics and perf checks.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.6)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

**Status:** done  
**Commit:** 60c5f1e (DailyViewScreen — screen integration batch C)

### Fichiers modifiés
- `lib/features/daily/presentation/daily_view_screen.dart` — expansion inline intégrée
- `test/widget/daily_view_screen_test.dart` — tests 4-6 inclus

### AC couverts
1. AnimatedSize + AnimatedCrossFade 300ms easeInOutCubic ✓
2. Contenu étendu : action row (call/SMS/WA), last note, lien Full details ✓
3. Une seule carte ouverte à la fois (state `String? expandedFriendId`) ✓
4. Back gesture : PopScope collapse avant exit ✓
5. Navigation Full-details via `push()` → scroll + état collapsed préservés au retour ✓
6. Semantics labels sur tous les boutons interactifs ✓
7. Touch targets : ConstrainedBox(minHeight: 48, minWidth: 72) ✓

### Décisions techniques
- `ConsumerStatefulWidget` pour tenir `_expandedFriendId` + `_scrollController`
- `AnimatedCrossFade` → les deux enfants restent dans l'arbre ; tests utilisent `.hitTestable()`
- `_ExpandedContent.actionService` reçu via `ref.read(contactActionServiceProvider)`
- `FriendDetailRoute.push()` (pas `.go()`) pour back-stack navigation

### Résultats qualité
- `flutter analyze lib/features/daily/` → No issues
- `flutter test` → 309/309 All tests passed
- Perf 60fps : architecture AnimatedSize/AnimatedCrossFade native Flutter sans Raster work