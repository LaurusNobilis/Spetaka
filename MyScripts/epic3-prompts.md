# Epic 3 — Prompts “Story Batch Autopilot” (YOLO)

Objectif: enchaîner les stories de l’Epic 3 **sans changer de chat à chaque story**, tout en gardant un contexte minimal pour éviter la saturation.

Principes:
- **Source de vérité = fichiers sur disque**, pas le chat.
- **Contexte minimal strict**: sprint-status + 1–2 fichiers de story + fichiers Dart strictement nécessaires + sorties d’erreurs.
- **Stop** si une story `.md` n’existe pas → te dire explicitement “lance create-story”.
- **1 commit par story** + `git push` + `sprint-status.yaml` (story → done) + petit **Handoff** (≤120 lignes) dans la story.
- Si le modèle dérive: **nouvelle session seulement entre les batches (A → B → C)**.

---

########################

## Prompt — Batch A (3.1 puis 3.2)

Tu es en mode “Story Batch Autopilot” (Epic 3 / implementation). Objectif: terminer exactement **2 stories**: **3-1** puis **3-2**, sans extra.

Règles de contexte:
- Ne charge que:
  1) /_bmad-output/implementation-artifacts/sprint-status.yaml
  2) /_bmad-output/implementation-artifacts/3-1-add-a-dated-event-to-a-friend-card.md
  3) /_bmad-output/implementation-artifacts/3-2-add-a-recurring-check-in-cadence.md
  4) Les fichiers Dart strictement nécessaires + sorties de `flutter test`/`flutter analyze` si échec.
- Si un des fichiers story (3-1/3-2) n’existe pas: STOP et dis-moi “lance create-story”.

Boucle d’exécution (3-1 puis 3-2):
1) Implémente la story en respectant uniquement les AC.
2) Wiring minimal (routes/providers) seulement si requis.
3) Qualité: lance `flutter analyze` + `flutter test` (ciblés si possible).
4) Commit séparé par story + push.
5) Mets à jour /_bmad-output/implementation-artifacts/sprint-status.yaml: story → `done`.
6) Écris un Handoff court (≤120 lignes) dans le fichier story (bloc “Handoff” à la fin).

Stop conditions:
- Stop après 3-2 done.
- En cas de blocage: diagnostic minimal + 3 options max, pas de refactor.

Commandes “checkpoint” (2–3 min):
- `cd spetaka && flutter analyze`
- `cd spetaka && flutter test`
- `git status -sb`
- `git push`

---

########################

## Prompt — Batch B (3.3 puis 3.5)

Mode “Story Batch Autopilot” (Epic 3 / implementation). Objectif: terminer exactement **2 stories**: **3-3** puis **3-5**, sans extra.

Contexte minimal:
- Lis seulement:
  1) /_bmad-output/implementation-artifacts/sprint-status.yaml
  2) /_bmad-output/implementation-artifacts/3-3-edit-or-delete-an-event.md
  3) /_bmad-output/implementation-artifacts/3-5-manual-event-acknowledgement.md
  4) Fichiers Dart nécessaires + outputs d’erreurs.

Pré-contrôle:
- Si 3-1 ou 3-2 n’est pas `done` dans sprint-status.yaml: STOP (les flows event/listing dépendent souvent des bases).

Exécution:
- Implémente 3-3 puis 3-5.
- À chaque story: tests/analyze → commit → push → sprint-status.yaml → `done` → handoff ≤120 lignes.

Stop après 3-5 done.

---

########################

## Prompt — Batch C (3.4 seul)

Mode “Story Autopilot”. Objectif: terminer exactement **1 story**: **3-4**, sans extra.

Contexte minimal:
- Lis seulement:
  1) /_bmad-output/implementation-artifacts/sprint-status.yaml
  2) /_bmad-output/implementation-artifacts/3-4-personalize-event-types.md
  3) Fichiers Dart nécessaires + outputs d’erreurs.

Pré-contrôle:
- Si 3-1, 3-2, 3-3, 3-5 ne sont pas `done`: STOP (risque de conflit sur event types / UX / wiring).

Exécution:
1) Implémente 3-4 (event types + UI + wiring) selon AC.
2) Tests/analyze.
3) Commit + push.
4) sprint-status.yaml: story → done.
5) Handoff ≤120 lignes.

Stop après 3-4 done.

---

########################

## Prompt — Pre-New-Session Checklist (avant d’ouvrir un nouveau chat)

Tu es en mode “Pre-New-Session Checklist” (objectif: sécuriser l’état du repo avant d’ouvrir une nouvelle session).

Règles:
- Ultra concis.
- Ne lis que:
  1) /_bmad-output/implementation-artifacts/sprint-status.yaml
  2) Les outputs d’erreurs (tests/analyze) si échec.
- Exécute les commandes nécessaires, puis rends un verdict GO/NO-GO.

Checklist (ordre strict):
1) Git:
   - `git status -sb`
   - Si modifs: STOP et liste les fichiers + propose commit OU discard.
2) Qualité Flutter:
   - `cd spetaka && flutter analyze`
   - `cd spetaka && flutter test`
   - Si échec: STOP, cause racine probable + 1 correction à tenter.
3) Sprint status:
   - Ouvre sprint-status.yaml et vérifie que les stories du batch fini sont en `done`.
4) Handoff:
   - Vérifie bloc “Handoff” (≤120 lignes) pour chaque story du batch.
5) Push:
   - `git push`

Sortie attendue (format strict):
- Verdict: GO ou NO-GO
- Preuves: 3 lignes max
- Next: “ouvre New Session maintenant” OU actions (max 5)

---

########################

## Prompt — Epic 3 Gate Review (STRICT + CI)

Tu es en mode “Epic Gate Review — STRICT + CI” (objectif: vérifier qu’on peut démarrer l’epic suivant sans dettes, et que la CI est verte).

Contraintes:
- Concis et actionnable.
- Zéro refactor large.
- Si un check échoue: Verdict NO-GO + 3 actions max, puis STOP.
- Contexte minimal: sprint-status.yaml + erreurs analyze/test + max 5 fichiers liés aux erreurs.

Repo CI:
- Repo GitHub = LaurusNobilis/Spetaka
- Branche = main

Checks (ordre strict):
1) Git propre + synchro remote
   - `git status -sb`
   - `git push`
2) Qualité Flutter (bloquant)
   - `cd spetaka && flutter analyze`
   - `cd spetaka && flutter test`
3) CI GitHub Actions (bloquant)
   - Si `gh` dispo: lire le dernier run main (status/conclusion/url)
   - Sinon: `curl -sS -H "Accept: application/vnd.github+json" "https://api.github.com/repos/LaurusNobilis/Spetaka/actions/runs?branch=main&per_page=1"`
   - Si impossible (auth/rate limit): NO-GO avec 1 action: vérifier manuellement Actions.
4) BMAD tracking
   - Ouvre sprint-status.yaml et vérifie que toutes les stories Epic 3 (3.1–3.5) sont `done` et l’epic est `done`.
5) Migrations/Drift (si modifiées récemment)
   - `git --no-pager diff --name-only HEAD~20..HEAD` puis scan minimal.

Sortie (format strict):
- Verdict: GO ou NO-GO
- Preuves: 4 lignes max
- Next: si GO “Epic suivant OK — ouvre une New Session et lance la prochaine story”

