---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: []
session_topic: 'Suggestions de messages — retours d'expérience et approfondissement'
session_goals: 'Explorer des améliorations et nouvelles directions pour la fonctionnalité de suggestion de messages, en s'appuyant sur des retours d'usage réels'
selected_approach: 'AI-Recommended Techniques'
techniques_used: [Five Whys, SCAMPER, What If Scenarios]
ideas_generated: [13]
context_file: ''
---

# Brainstorming Session Results

**Facilitator:** Laurus
**Date:** 2026-03-30

## Session Overview

**Topic:** Suggestions de messages — retours d'expérience et approfondissement
**Goals:** Explorer des améliorations et nouvelles directions pour la fonctionnalité de suggestion de messages, en s'appuyant sur des retours d'usage réels

### Session Setup

_Session initiée par Laurus avec retours terrain sur la feature "message suggestions" (Epic 10.2 — DraftMessageSheet + 3 variantes LLM)._

---

## Racines identifiées (Five Whys)

**Root A — Style personnel absent**
Le LLM n'a aucune information sur le style d'écriture de l'utilisateur → génère du générique → les suggestions sonnent "ChatGPT" et non "Laurus".
→ Solution : apprentissage implicite par observation des deltas correction/envoi (ton + longueur + mots-clés)

**Root B — Contexte événement non exploité**
Le prompt ne module pas le ton selon le type d'événement ET n'intègre pas le commentaire libre → 3 variantes toutes du même registre générique.
→ Solution : enrichir le prompt avec type + commentaire + tonalité cible par type d'événement

---

## Idées générées

### Thème 1 — Prompt & Contexte LLM (Root B)

**[SCAMPER-S#1]** : Prompt dynamique par type d'événement + commentaire
_Concept_ : `PromptTemplate.messageSuggestion()` calcule une `eventTone` à partir du type ET du commentaire libre. Un anniversaire sans commentaire → festif. Un anniversaire avec commentaire "a perdu son père il y a 3 mois" → douceur, pas de blague.
_Nouveauté_ : Le commentaire de l'événement agit comme un modificateur de tonalité — couche sémantique entièrement nouvelle.

**[SCAMPER-M#1]** : Contexte événement visible dans la DraftMessageSheet
_Concept_ : Header de la sheet affiche `[type d'événement] · [date relative] · "[commentaire]"` — l'utilisateur voit exactement pourquoi il écrit pendant qu'il choisit une variante.
_Nouveauté_ : Boucle cognitive consciente — tu vois le contexte, tu choisis, tu envoies. Cohérence garantie.

**[SCAMPER-P#2]** : Anti-répétition pour les cadences récurrentes
_Concept_ : Avant de générer les 3 variantes, le prompt inclut le dernier message envoyé (`ContactHistory`). Instruction LLM : "Ne pas réutiliser les mêmes tournures qu'il y a [N] semaines." L'app affiche : _"Dernière fois : 'Coucou, je pensais à toi !' — voici quelque chose de différent."_
_Nouveauté_ : La répétition devient visible ET résolue automatiquement.

---

### Thème 2 — Style personnel appris (Root A)

**[SCAMPER-S#2]** : UserVoiceProfile — 3 vecteurs appris on-device
_Concept_ : Un `UserVoiceProfile` (Dart class, SQLite) stocke : niveau de formalité (0-10), longueur préférée (N mots moyen), liste de mots-clés récurrents. Alimenté automatiquement à chaque envoi depuis `DraftMessageSheet` (observation du delta suggestion → message envoyé).
_Nouveauté_ : Apprentissage 100% on-device — cohérent avec la philosophie privacy-first de Spetaka. Longueur + ton + mots-clés = contraintes injectées dans le prompt.

**[SCAMPER-S#2 — enrichi]** : UserVoiceProfile inclus dans le backup chiffré
_Concept_ : Le `UserVoiceProfile` fait partie du payload de la sauvegarde locale chiffrée (Story 6.5). Quand l'utilisateur réinstalle ou change de téléphone, son style le suit.
_Nouveauté_ : Le style personnel devient une donnée de profil au même titre que les amis.

**[SCAMPER-M#2]** : Longueur + ton + mots-clés = contraintes du UserVoiceProfile, pas choix du LLM
_Concept_ : Les 3 variantes ont la même longueur apprise (style de l'utilisateur). Prompt : _"Écris dans ce style : [formalité X/10, ~N mots, inclure si pertinent : [mots-clés]]"_.
_Nouveauté_ : Le LLM devient un exécutant du style de l'utilisateur, pas l'inventeur d'un style générique.

---

### Thème 3 — UX & Points d'entrée

**[SCAMPER-C#2]** : 4e bouton "✦ Message" dans la rangée d'actions de la Daily View
_Concept_ : La rangée `[📞 Appeler] [💬 SMS] [🟢 WA]` devient `[📞 Appeler] [💬 SMS] [🟢 WA] [✦ Message]`. Un tap ouvre directement `DraftMessageSheet` avec l'événement actif pré-chargé — type + commentaire déjà injectés dans le prompt.
_Nouveauté_ : Point d'entrée LLM au même niveau de friction que les actions de contact existantes. Zéro navigation supplémentaire.

---

### Thème 4 — Daily View & Expérience globale

**[SCAMPER-P#1]** : Daily View greeting line — variation bienveillante à chaque ouverture
_Concept_ : La ligne de bienvenue (Story 10.3) produit une phrase différente à chaque ouverture — toujours chaleureuse, jamais punitive, jamais répétitive. Pool de variantes rotatif ou génération LLM légère.
_Nouveauté_ : L'app "respire" — chaque ouverture a une micro-surprise positive. Elle ne devient pas une routine mécanique.

---

### Thème 5 — Variantes & Labels émotionnels (Phase 3)

**[Cross-Pollination#13]** : Labels émotionnels sur les 3 variantes
_Concept_ : Au lieu de "Option 1 / 2 / 3", afficher : _"Chaleureux · Direct · Drôle"_ — l'utilisateur choisit le registre, pas juste le texte.
_Nouveauté_ : La sélection devient intentionnelle et émotionnellement consciente.

**[Cross-Pollination#12]** : Dernier message envoyé en filigrane dans la sheet
_Concept_ : Le dernier message envoyé à cet ami apparaît discrètement en haut de la `DraftMessageSheet` — pas pour copier, mais pour ancrer la continuité relationnelle.
_Nouveauté_ : Crée une conscience de l'historique de la relation au moment de composer.

---

## Organisation par phase

### Phase 2 — Faisable maintenant (stories candidates)

| ID | Idée | Complexité | Impact |
|---|---|---|---|
| P2-A | Prompt dynamique par type + commentaire d'événement | Faible | Élevé |
| P2-B | Contexte événement visible dans DraftMessageSheet (header) | Faible | Élevé |
| P2-C | 4e bouton "✦ Message" dans la rangée Actions Daily View | Moyen | Élevé |
| P2-D | UserVoiceProfile — 3 vecteurs appris on-device | Moyen | Élevé |
| P2-E | UserVoiceProfile inclus dans le backup chiffré | Faible | Moyen |
| P2-F | Anti-répétition cadences récurrentes (dernier message dans prompt) | Faible | Moyen |
| P2-G | Greeting line variée à chaque ouverture | Faible | Moyen |

### Phase 3 — Directions ambitieuses

| ID | Idée | Notes |
|---|---|---|
| P3-A | Labels émotionnels sur les variantes (Chaleureux · Direct · Drôle) | UX différenciante |
| P3-B | Dernier message en filigrane dans la DraftMessageSheet | Besoin de ContactHistory exposé dans la sheet |
| P3-C | Import export WhatsApp pour bootstrap du UserVoiceProfile | Complexité parsing + privacy |

---

## Prochaines étapes recommandées

**Sprint immédiat — 2 stories à forte valeur :**
1. **Story 10.5** : Prompt enrichi (type + commentaire) + contexte visible dans DraftMessageSheet + bouton "✦ Message" dans la Daily View Actions *(P2-A + P2-B + P2-C — peuvent être livrés ensemble)*
2. **Story 10.6** : UserVoiceProfile — apprentissage implicite on-device + injection dans prompt + inclusion dans backup *(P2-D + P2-E)*

**Après ces 2 stories :**
- P2-F (anti-répétition) et P2-G (greeting variée) sont des améliorations légères sur stories existantes

---

## Session CH — Authenticité & LLM (2026-03-30, suite)

### Philosophie produit cristallisée

> **"Investis-toi et l'IA t'aidera."**

Le LLM n'est pas un substitut à l'attention portée à ses amis — c'est un amplificateur de ce que l'utilisateur a déjà investi dans la relation (notes, commentaires d'événements, contexte). Sans investissement → signal court. Avec investissement → amplification précise.

**Guardrail d'authenticité absolute :** La suggestion LLM ne peut jamais en savoir plus sur l'ami que ce que l'utilisateur a écrit.

### Règles produit validées (ajoutées à Story 10.6)

**P3-1 — Longueur pilotée par la profondeur du commentaire (`commentDepth`)**
- Commentaire vide ou ≤ 3 mots → max 8 mots (signal pur : "Coucou, je pensais à toi !")
- Commentaire 4–15 mots → max 20 mots (signal + contexte)
- Commentaire > 15 mots → max 40 mots (message personnalisé avec détails)

**P3-2 — Détection d'émotion par keywords (Option A, déterministe, offline)**
- Catégorie anxiété : `anxieux, stressé, peur, kiné, douleur, difficile, inquiet` → tone: reassuring
- Catégorie deuil : `perdu, décédé, deuil, séparation, rupture, triste` → tone: gentle (no humour)
- Catégorie joie : `heureux, fier, excité, content, réussi, diplôme, bébé, mariage` → tone: celebratory
- Aucun marqueur → tone: neutral (comportement existant 10.5)

Option B (LLM interprète le commentaire lui-même) = Phase 3 — trop de délégation émotionnelle au modèle.

**P3-3 — 3 variantes comme acte d'intention**
Le choix parmi 3 variantes *force* l'utilisateur à se demander "laquelle me ressemble avec cet ami aujourd'hui ?". L'acte de choix = l'acte d'intention. C'est ce qui définit la sincérité du message, pas les mots eux-mêmes.

**P3-4 — UserVoiceProfile = style de l'expéditeur, commentaire = profondeur du contenu sur l'ami**
Deux dimensions orthogonales :
- **Commentaire d'événement** → profondeur du contenu (ce qu'on sait sur l'ami)
- **UserVoiceProfile** → style de l'utilisateur (comment il écrit naturellement)
Les deux ensemble = message le plus juste possible.
