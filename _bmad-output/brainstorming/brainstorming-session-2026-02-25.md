---
stepsCompleted: [1, 2, 3, 4]
session_active: false
workflow_completed: true
inputDocuments: []
session_topic: 'Spetaka Android app for managing friends and important recurring/non-recurring dates with action shortcuts and daily follow-up queue'
session_goals: 'Define product direction for friend profiles, event reminders, acquittal/history flow, daily follow-up view, messaging shortcuts (SMS/WhatsApp), WebDAV storage feasibility, and future MacBook Pro usage strategy'
selected_approach: 'ai-recommended'
techniques_used: ['SCAMPER Method', 'What If Scenarios', 'Reverse Brainstorming']
ideas_generated: []
context_file: ''
---

# Brainstorming Session Results

**Facilitator:** Laurus
**Date:** 2026-02-25

## Session Overview

**Topic:** Spetaka Android app for tracking important dates for friends, with per-friend messaging shortcuts and event management.

**Goals:**
- Shape the core concept and feature priorities.
- Clarify event lifecycle (today/tomorrow + overdue unacknowledged events, acknowledgment, and history).
- Explore technical options for WebDAV-based sync/storage.
- Prepare a future path to use the app from a MacBook Pro in a later phase.

### Session Setup

User described an Android-first app named Spetaka with one entry per friend, message shortcuts (SMS/WhatsApp), optional recurring events, a friends list view, and a daily follow-up view showing overdue unacknowledged past events plus events due today and tomorrow.

User also asked about WebDAV storage and future MacBook Pro usage in a next phase.

## Technique Selection

**Approach:** AI-Recommended Techniques
**Analysis Context:** New product concept definition with UX, feature, and technical dimensions.

**Recommended Techniques:**

- **SCAMPER Method:** Systematically pressure-test every existing feature via 7 lenses to surface enhancements and trade-offs.
- **What If Scenarios:** Break constraints around sync, platforms, and edge cases to expand the solution space.
- **Reverse Brainstorming:** Surface failure modes and design pitfalls before implementation.

**AI Rationale:** SCAMPER grounds the session in the known feature set; What If opens the solution space for technical and platform ambiguity; Reverse Brainstorming converts risks into design guardrails.

---

## Inventaire complet des idées

### Thème 1 — Fiche Ami & Données Relationnelles

**[S #5b]: Catégories multi-tags**
Un ami peut appartenir à plusieurs catégories simultanément (ex: "Collègue" ET "Ami proche"). Les catégories sont des tags, pas des cases exclusives. La cadence appliquée est celle du tag le plus exigeant, ou configurable.

**[S #6]: Notes personnelles — "mémoire de contexte"**
Champ libre "Ce que j'aime savoir sur lui/elle" sur chaque fiche : intérêts, passions, infos importantes. Injectées dans le prompt LLM lors de la génération de brouillons.

**[A #3]: "Dernier contact" visible (adapté CRM)**
Ligne discrète sous le nom : *"Dernier contact : Message · il y a 3 semaines"*. Toujours visible sans ouvrir l'historique.

**[M #3]: Liaison fiche ↔ répertoire téléphone**
À la création d'une fiche, import depuis le répertoire Android : nom, numéro mobile uniquement. Lien maintenu — si le numéro change dans le répertoire, Spetaka se met à jour.

**[E #3]: Un seul numéro mobile par ami**
Constraint de design : simplicité absolue. Pas de numéros multiples.

**[E #1]: Pas de photos en v1**
Reporté en phase ultérieure pour alléger le build initial et le stockage WebDAV.

---

### Thème 2 — Types d'Événements & Cadences

**[S #2]: Event Type as First-Class Object**
Types avec comportement propre : `Anniversaire`, `Anniversaire de mariage`, `RDV médical`, `Événement de vie important`, `Prise de contact régulière (cadence)`, `RDV important`. Chaque type porte un ton par défaut pour le LLM.

**[S #2c]: Types d'événements éditables par l'utilisateur**
La liste de types est entièrement modifiable après installation : ajouter, renommer, supprimer, réordonner. Les types sont des données utilisateur, pas du code figé.

**[S #2b]: Commentaire libre sur l'événement**
Champ "contexte libre" optionnel sur chaque événement. Évite l'explosion de types — le type structure, le commentaire nuance.

**[S #3]: Cadence comme type d'événement**
Type dédié "Prise de contact régulière" avec récurrence configurable par ami. Overdue cadences remontent dans la vue du jour comme n'importe quel événement.

**[C #1]: Cadence liée à la catégorie — mais configurable**
"Ami proche" → 2 semaines par défaut. "Famille" → 1 semaine. "Ami lointain" → 3 mois. Surcharge possible par ami. Rien de figé.

---

### Thème 3 — Actions & Acquittement

**[M #2]: Actions 1-tap depuis la fiche**
Trois boutons permanents sur chaque fiche : 📞 Appeler · 💬 SMS · 🟢 WhatsApp. Un tap → action directe.

**[M #2b]: Acquittement automatique sur action directe**
Appel/message depuis la fiche → à la reouverture de l'app, acquittement pré-rempli proposé (type + heure). Confirmation en 1 tap.

**[Acquittement enrichi]**
Sélecteur rapide au moment de l'acquittement : 💬 Message envoyé · 📞 Appelé · 🤝 Vu en personne · 📝 Message vocal. L'historique devient un vrai journal de relation.

**[A #4]: Événement "suivi de préoccupation" (adapté journaling)**
À l'acquittement, option "cet ami traverse quelque chose" + note courte. Crée automatiquement un événement de suivi dans X jours. Indicateur discret sur la fiche tant que actif.

---

### Thème 4 — Vue du Jour & Algorithme de Priorité

**[R #3b]: Briefing du cœur — structure 2+2**
En tête de vue : 🔴 2 Urgents (non-acquittés anciens, préoccupation active, dans 24h) · 💛 2 Importants (3 prochains jours, cadences proches). Reste de la liste en dessous.

**[R #2]: Score de priorité dynamique**
Les événements sont pondérés par urgence humaine :
```
Score = Poids du type d'événement
      + Ancienneté du non-acquittement
      + Catégorie de l'ami (famille > ami proche > lointain)
      + Préoccupation active (×2)
      + Care score faible de l'ami (remonte en priorité)
```

**[R #4]: Suggestion proactive douce sur la fiche**
Si care score descend, affichage discret sur la fiche : *"Cela fait 8 semaines — peut-être lui envoyer un petit message ?"* — visible uniquement si tu ouvres la fiche.

**[R #5]: "Personne oubliée" — remontée automatique**
Ami sans événement planifié ET sans acquittement depuis X jours (configurable) → remonte dans la vue du jour avec tag *"Perdu de vue ?"*.

---

### Thème 5 — Messagerie & Brouillons

**[M #1]: Brouillons préparés en avance**
Sur n'importe quelle fiche ou événement, préparer un message à l'avance. Le jour J, il remonte en tête de vue avec bouton "Envoyer" direct.

**[M #1b]: Rotation de brouillons pour cadences**
Pour les contacts récurrents, 3 variantes de brouillons en rotation — tu choisis au moment d'envoyer.

---

### Thème 6 — LLM & Personnalisation des Messages *(Phase 2)*

**[S #1]: AI-Drafted Message from Event Context**
LLM local sur Android (Samsung S25 — Galaxy AI / Gemma via MediaPipe). Génère un brouillon à partir du type d'événement + notes de la fiche. 100% offline, sans vie privée compromise.

**[A #1]: LLM en mode "palette d'ingrédients"**
Deux modes au choix : Mode Compositeur (brouillon complet) · Mode Palette (3-5 fragments à assembler soi-même). Le message reste la voix de l'utilisateur.

**[S #4]: Bibliothèque de "voix personnelle"**
Profil de style personnel : ton habituel, expressions favorites, phrases d'encouragement récurrentes. Le LLM s'en inspire pour chaque brouillon.

**[A #2]: Bibliothèque de phrases personnelles indexée**
Fichier texte éditable, organisé par catégories : Encouragements, Anniversaires, Reprises de contact, Libre. Le LLM sélectionne 2-3 phrases de ta bibliothèque + génère 1-2 fragments contextuels.

**[A #2b]: Format de la bibliothèque**
Fichier `.txt` ou `.md` — une phrase par ligne, sections titrées. Synchronisé via WebDAV. Éditable dans l'app ou sur Mac.

---

### Thème 7 — Stockage & Sync

**[R #1]: Chiffrement WebDAV transparent**
Passphrase saisie une fois à l'installation → tout chiffré automatiquement. Aucun impact UX. Les données sont illisibles sur le WebDAV. **Phase 1.**

---

### Thème 8 — Philosophie & Principes de Design

**[Design Principle #1]: "Special Take Care"**
Spetaka = *"Qui mérite mon attention aujourd'hui ?"*. Chaque décision de design se filtre par : *"Est-ce que ça aide Laurus à vraiment prendre soin des gens qui comptent ?"*

**[DC #1 + DC #2]: Application 100% non-intrusive**
Zéro notification push. Zéro widget. Zéro badge icône. Jamais — pas reporté, définitivement exclu. L'app existe quand tu décides qu'elle existe.

**[DC #3]: Historique léger mais complet**
Tout garder, en format volontairement court — mots-clés, phrases clés. La légèreté est une contrainte de design.

---

### Thème 9 — Gamification RPG *(Phase 2)*

**[G #1]: Spetaka RPG — inspiré Habitica, adapté à l'amour des amis**

**Ton personnage :** Nom éditable dans l'app. Stats :
- **Points de Vie Relationnels (PVR)** — santé globale des liens. Ne baissent jamais par inactivité.
- **Points d'Expérience (XP)** — gagnés à chaque acquittement, brouillon envoyé, événement créé.
- **Or du Cœur 💛** — monnaie pour la Boutique.

**Les 4 classes** (débloquées niveau 10) :
| Classe | Style | Bonus |
|---|---|---|
| 🌿 Le Tisseur | Liens durables, cadences | XP ×1.5 sur cadences |
| 🔥 Le Présent | Réactif, événements importants | XP ×1.5 sur urgents |
| 💫 Le Mémoriel | Anniversaires, dates clés | XP ×1.5 sur événements de vie |
| 🌊 Le Veilleur | Amis en difficulté | XP ×2 sur suivi préoccupation |

**Niveaux et titres :**
```
Niv. 1-5   → Ami Attentionné
Niv. 6-10  → Gardien Émergent
Niv. 11-20 → Tisseur de Liens
Niv. 21-35 → Gardien Assidu
Niv. 36-50 → Pilier des Relations
Niv. 51+   → Ami Fidèle
```

**Quêtes quotidiennes :** 3 quêtes générées à l'ouverture, basées sur les vraies données. Expirent à la prochaine ouverture (pas à minuit — philosophie pull).

**Boutique du Gardien 💛 :** Thèmes visuels, avatars, équipements cosmétiques, parchemins de phrases spéciaux.

**Forêt des Liens 🌱 :** Chaque ami = une graine. Les acquittements la font grandir → Arbre ancien 🌳. Un ami négligé s'endort (feuilles grises). Un contact le réveille. Jamais de mort.

**Trophées :** Premier acquittement, 0 anniversaire raté en 3 mois, suivi préoccupation résolu, streak 52 semaines, ami "perdu de vue" recontacté, 20 amis dans Spetaka, 50 brouillons préparés...

**Principe fondateur :** Rien ne punit. Tu gagnes quand tu agis. Le personnage attend patiemment — il ne souffre pas.

---

## Organisation & Priorisation

### Phase 1 — MVP Android

| Feature | Priorité |
|---|---|
| Fiches amis (lien répertoire, mobile, tags multi, notes contextuelles) | 🔴 Core |
| Types d'événements éditables (5 par défaut) | 🔴 Core |
| Vue du jour : non-acquitté + aujourd'hui + 3 prochains jours | 🔴 Core |
| Briefing du cœur 2+2 (urgents/importants) | 🔴 Core |
| Score de priorité dynamique | 🔴 Core |
| Actions 1-tap (appel, SMS, WhatsApp) + acquittement auto | 🔴 Core |
| Acquittement enrichi (type d'action) | 🔴 Core |
| Brouillons préparés en avance + rotation | 🟡 Important |
| Suivi de préoccupation | 🟡 Important |
| "Dernier contact" visible sur fiche | 🟡 Important |
| "Personne oubliée" — remontée auto | 🟡 Important |
| Stockage WebDAV chiffré (passphrase unique) | 🔴 Core |

### Phase 2 — Enrichissement

| Feature | Notes |
|---|---|
| LLM local (Galaxy AI / Gemma) — palette + bibliothèque | Indépendant du reste |
| Gamification RPG complète | Indépendant du LLM |
| App MacBook Pro | Après stabilisation Android |
| Photos sur les fiches | Après WebDAV stable |

---

## Résumé de session

**30+ idées structurantes** générées en une session via SCAMPER.

**Percées clés :**
1. **Spetaka = assistant de priorité**, pas un agenda — le score de priorité dynamique est le cœur algorithmique.
2. **LLM en mode palette** — l'utilisateur garde sa voix, le LLM fait le travail ingrat.
3. **Gamification sans punition** — inspirée Habitica mais radicalement bienveillante.
4. **Philosophie pull absolue** — aucune intrusion, jamais, même en phase 2.
5. **WebDAV chiffré dès la v1** — la vie privée n'est pas une option de phase 2.

**Prochaine étape recommandée :** `/bmad-bmm-create-product-brief` pour formaliser ces idées en brief produit structuré.
