# Story 4.1: Priority Engine — Score Computation

Status: done

## Story
As Laurus, I want a dynamic priority score so daily ranking highlights who needs care most.

## Acceptance Criteria
1. `priority_engine.dart` is pure Dart and returns sorted friends with `priorityScore`.
2. Formula includes event weight, overdue days, category weight, concern x2, and high care score boost.
3. Urgency tiers separate urgent (today/overdue) and important (next 3 days).
4. Computation target is <500ms for 100 cards.
5. Unit tests validate deterministic ranking rules.

## Tasks
- [x] Implement pure scoring engine and constants.
- [x] Implement urgency tiering rules.
- [x] Add deterministic unit tests and perf benchmark test.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.1)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

## Handoff

**Fichiers créés / modifiés**

| Fichier | Action |
|---|---|
| `spetaka/lib/features/daily/domain/priority_engine.dart` | Créé — moteur pur Dart |
| `spetaka/test/unit/priority_engine_test.dart` | Créé — 17 tests (unité + benchmark) |
| `spetaka/lib/features/features.dart` | Export `daily/domain/priority_engine.dart` ajouté |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | `4-1` → `done` |

**Architecture du moteur**

- DTOs purs Dart : `FriendScoringInput`, `EventScoringInput`, `PrioritizedFriend`
- Enum `UrgencyTier` : `urgent` (today/overdue) · `important` (≤3j) · `normal`
- Constantes : `kBaseScore=10`, `kCareScoreMultiplier=5`, `kOverdueBonusRate=0.3`, `kCategoryWeights`
- Formule : `score = eventWeight + overdueBonus + categoryWeight + (hasConcern ? 20 : 0) + careBoost`
- `PriorityEngine.sort(friends, {now, excludeDemo=false})` — `excludeDemo` prépare le couplage 4-5

**Résultats**

- `flutter analyze` : No issues found
- `flutter test` : 17/17 passed
- Benchmark : <500ms pour 100 cartes (confirmé en test)

**Point d'attention pour 4-5**

`FriendScoringInput.isDemo` existe déjà. Passer `excludeDemo: true` dans le pipeline
de la Daily View suffira — aucune modification du moteur nécessaire.
