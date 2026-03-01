# Story 4.4: Coach-Tone Greeting Line & Density Control

Status: done

## Story
As Laurus, I want a warm greeting and one-tap density toggle so daily ritual stays human and adjustable.

## Acceptance Criteria
1. Greeting line in Lora adapts to context (0/1/2+ surfaced, concern present, time of day, user name).
2. Tone is always encouraging and non-punitive.
3. Density toggle supports compact vs expanded daily list.
4. Density preference persists via `shared_preferences`.
5. Widget tests validate greeting rendering and toggle effect.

## Tasks
- [ ] Implement greeting copy generator with context variants.
- [ ] Build density toggle and list-size behavior.
- [ ] Persist/restore density preference.
- [ ] Add widget tests.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.4)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

**Status:** done  
**Commits:** adebb7a (domain/provider), 60c5f1e (screen integration)

### Fichiers créés / modifiés
- `lib/features/daily/domain/greeting_service.dart` — GreetingService (pure Dart)
- `lib/features/daily/data/density_provider.dart` — DensityNotifier + densityModeProvider
- `lib/features/daily/presentation/daily_view_screen.dart` — Greeting banner + density toggle UI
- `test/unit/greeting_service_test.dart` — 32 tests (variants 0/1/2+ surfacés, concern, heure, non-punitif)
- `test/widget/daily_view_screen_test.dart` — 11 tests (greeting présent/absent, toggle état, cards)

### AC couverts
1. Greeting adapté au contexte (0/1/2+ surfacés, concern, heure, user_name=Laurus) ✓
2. Tone non-punitif — 24 assertions automatiques ✓
3. Density toggle compact/expanded en AppBar (key `density_toggle`) ✓
4. Persistance via shared_preferences (`density_mode`) ✓
5. Widget tests greeting variants + toggle effect → 43/43 ✓

### Décisions techniques
- `GreetingService` : const, pure Dart, paramètre `hour` optionnel pour les tests
- `DensityNotifier` : async load depuis SharedPreferences via `Future.microtask`
- `_GreetingBanner` : key `greeting_banner`, style italic, au-dessus de HeartBriefingWidget

### Résultats qualité
- `flutter analyze lib/features/daily/` → No issues
- `flutter test` → 309/309 All tests passed
