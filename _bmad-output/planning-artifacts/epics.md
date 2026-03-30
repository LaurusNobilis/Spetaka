---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/architecture.md"
  - "_bmad-output/planning-artifacts/architecture-phase2-addendum.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
phaseContext: "Phase 2 additions run — Phase 1 epics/stories preserved intact"
lastUpdated: "2026-03-25"
---

# Spetaka - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Spetaka, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

**Phase 1 — Friend Management (Fiches)**
FR1: User can create a friend card (fiche) by importing contact details from the phone's address book
FR2: User can create a friend card manually by entering name and mobile number
FR3: User can assign one or more category tags to a friend card
FR4: User can add and edit free-text context notes on a friend card
FR5: User can view all friend cards in a list
FR6: User can open a friend card to see full details, events, and contact history
FR7: User can edit any field on a friend card at any time
FR8: User can delete a friend card
FR9: User can mark a friend as having an active concern (préoccupation flag) with a short descriptive note
FR10: User can clear an active concern flag from a friend card

**Phase 2 — Friend List Enhancements**
FR11 _(Phase 2)_: User can filter the friend list by one or more category tags
FR12 _(Phase 2)_: User can search the friend list by friend name
FR13 _(Phase 2)_: User can filter the friend list by status (has active concern, has overdue event, no recent contact)
FR14 _(Phase 2)_: System displays the date of the most recent acquittement as "last contact" on each friend card and in the friend list

**Phase 1 — Event & Cadence Management**
FR15: User can add an event to a friend card with a date, type, and optional free-text comment
FR16: User can add a recurring check-in cadence to a friend card with a configurable interval
FR17: User can edit or delete any event on a friend card
FR18: User can view the list of event types and edit it (add, rename, delete, reorder)
FR19: System provides 5 default event types at first launch: birthday, wedding anniversary, important life event, regular check-in, important appointment
FR20: User can manually mark an event as acknowledged (acquitted) from the friend card

**Phase 2 — Smart Concern Cadence**
FR21 _(Phase 2)_: When a concern flag is active on a friend card, system automatically creates a recurring check-in cadence with a 7-day default interval; the interval is configurable in settings; the cadence is automatically removed when the concern flag is cleared

**Phase 1 — Daily View & Priority Engine**
FR22: User can open a daily view showing friends who need attention today
FR23: System surfaces overdue unacknowledged events, today's events, and events within the next 3 days in the daily view
FR24: System orders the daily view by a dynamic priority score weighted by: event type importance, days overdue, friend category, active concern flag (×2), and low care score
FR25: System displays a heart briefing at the top of the daily view: 2 urgent entries and 2 important entries
FR26: User can tap any entry in the daily view to open the corresponding friend card

**Phase 1 — Actions & Communication**
FR27: User can initiate a phone call to a friend with one tap from their card
FR28: User can initiate an SMS to a friend with one tap from their card
FR29: User can open a WhatsApp conversation with a friend with one tap from their card
FR30: System detects when the user returns to the app after a communication action and presents the friend's card pre-focused for acquittement and note-taking

**Phase 1 — Acquittement & Contact History**
FR31: User can log an acquittement on a friend card specifying the action type (call, SMS, WhatsApp message, voice message, seen in person)
FR32: User can add a free-text note to an acquittement describing what was discussed or any relevant context
FR33: System pre-fills the acquittement prompt with the detected action type and current timestamp when triggered by post-action return
FR34: User can confirm the pre-filled acquittement in one tap
FR35: System maintains a chronological contact history log per friend card (acquittements with type, date, note)
FR36: System updates the friend's care score after each acquittement is logged

**Phase 3 — WebDAV Sync** _(deferred from Phase 2, decision 2026-03-25)_
FR37 _(Phase 3)_: User can configure a WebDAV server connection (URL, username, password, encryption passphrase)
FR38 _(Phase 3)_: User can test the WebDAV connection before enabling sync
FR39 _(Phase 3)_: System encrypts all data with the user's passphrase before transmitting to WebDAV
FR40 _(Phase 3)_: System syncs data to WebDAV automatically when network is available and sync is configured
FR41 _(Phase 3)_: User can restore all data from WebDAV after reinstall by re-entering their passphrase

**Phase 1 — Local Backup**
FR42: User can export all data to an encrypted local file as a standalone backup
FR43: User can import and restore data from a previously exported encrypted file

**Phase 2 — Draft Messages & On-Device LLM**
FR44 _(Phase 2)_: User can create a draft message on a friend card — a free-text message template contextualised for that friend
FR45 _(Phase 2)_: User can request the on-device LLM to generate alternative phrasings for an existing draft message; the LLM produces ≥ 3 variants from which the user selects or copies one
FR46 _(Phase 2)_: LLM inference runs entirely on-device with no network call; inference is triggered only by explicit user action (not automatically)
FR47 _(Phase 2)_: User can edit, save, or discard any draft message or LLM-suggested variant before use

**Phase 1 — Settings & Configuration**
FR48: User can view and edit all app settings from a dedicated settings screen
FR49: User can update the backup passphrase and reset backup settings (WebDAV sync configuration is Phase 3)
FR50: System operates with full functionality when no network connection is available

**Phase 2 — Concern Cadence Settings**
FR51 _(Phase 2)_: User can configure the default concern follow-up cadence interval (default: 7 days) from the settings screen

### NonFunctional Requirements

NFR1: The daily view loads and renders its full content within 1 second on the primary target device (Samsung S25)
NFR2: Priority score recomputation completes within 500ms — the daily view never shows a loading state for ranking
NFR3: Tapping a 1-tap action button (Call, SMS, WhatsApp) launches the target app within 500ms
NFR4: Friend card opens within 300ms of tap from any screen
NFR5: **Phase 3** — WebDAV sync background operation (not applicable in Phase 1 or Phase 2 — no WebDAV)
NFR6: All on-device data is encrypted at rest using AES-256 with a key derived from the user's passphrase (PBKDF2 or Argon2) — **Phase 1: all fields including `name` and `mobile` (Story 1.8)**
NFR7: **Phase 3** — Data transmitted to WebDAV is encrypted client-side (not applicable in Phase 1 or Phase 2)
NFR8: The user's passphrase is never stored, transmitted, or logged — only the in-memory derived key is used during an active session
NFR9: The app requests only READ_CONTACTS and INTERNET permissions, each requested at first point of use, not at install — **Phase 1: INTERNET not required (no WebDAV)**
NFR10: No analytics, telemetry, crash reporting, or advertising SDKs are included — zero data transmitted to any third-party service
NFR11: The local SQLite database is the single source of truth — no data loss after any unexpected app termination or device restart
NFR12: **Phase 3** — WebDAV sync failures must not corrupt local data (not applicable in Phase 1 or Phase 2)
NFR13: **Phase 1 (local backup):** A full restore from the encrypted local backup file reproduces all friend cards, events, acquittements, and settings without data loss
NFR14: The exported backup file is a complete, self-contained snapshot restorable to any device
NFR15: All interactive elements meet the minimum touch target size of 48×48dp (Android Material Design baseline)
NFR16: Text content meets WCAG AA contrast ratio (4.5:1 minimum for normal text)
NFR17: Core flows (daily view, friend card, acquittement) are navigable with Android TalkBack screen reader

**Phase 2 — On-Device LLM**
NFR18 _(Phase 2)_: LLM inference executes entirely on-device using a bundled local model (Gemma-3n-E2B-it or equivalent); no inference request, prompt, or generated text is ever transmitted to any remote server
NFR19 _(Phase 2)_: The app does not request or use the `INTERNET` permission for LLM inference; the LLM feature must remain fully functional with the device in airplane mode
NFR20 _(Phase 2)_: The bundled LLM model does not exceed 4 GB of device storage; model selection must meet this constraint at implementation time
NFR21 _(Phase 2)_: LLM inference is triggered only by explicit user action; no background or automatic inference is performed

### Additional Requirements

**From Architecture — Technical Setup (impacts Epic 1 Story 1):**
- STARTER TEMPLATE: `flutter create --org dev.spetaka --platforms android spetaka` — project initialization is the first implementation story
- Feature-first clean architecture: `lib/core/`, `lib/features/`, `lib/shared/` directory structure as defined in architecture document
- State management: Riverpod v3.2.1 with `@riverpod` code generation — manual providers forbidden
- Local persistence: Drift v2.31.0 — single `AppDatabase`, reactive stream-based queries
- Navigation: GoRouter v14.6.3 with declarative typed route tree
- Encryption library: `encrypt ^5.0.3` — AES-256-GCM mode; PBKDF2 (100,000 iterations, SHA-256) via `dart:crypto` for key derivation
- WebDAV client: **Phase 3 only** — `webdav_client ^3.0.1` not included in Phase 1 or Phase 2 dependencies
- Contact import plugin: `flutter_contacts ^1.1.9+2` — READ_CONTACTS at point-of-use only
- URL launcher: `url_launcher ^6.3.1` routed through centralized `ContactActionService`
- Entity IDs: UUID v4 strings via `uuid ^4.5.1` — never auto-increment integers
- CI/CD: GitHub Actions pipeline (flutter analyze → flutter test → flutter build apk --release)
- Play Store track strategy: Internal → Closed testing (Laurus's circle) → Production (after 4-week personal gate)
- Zero notification surface enforced at architecture level: no FCM SDK, no notification channels, no WorkManager notification tasks
- AppLifecycle detection isolated in `AppLifecycleService` — OEM fallback via manual "I just reached out" button
- Repository pattern strictly enforced: DAOs (SQL only) → Repositories (business logic) → Providers (UI streams) → Features
- Error handling: typed domain errors in `lib/core/errors/`; user-visible strings in `error_messages.dart`
- All timestamps stored as int Unix epoch ms in SQLite; converted at DAO boundary
- Phone number normalization centralized in `PhoneNormalizer` utility (shared by contact import + WhatsApp + SMS)

**From UX — Experience Requirements:**
- Virtual friend "Sophie" pre-loaded on first launch to demonstrate the full Spetaka loop before real data exists
- Context-aware, coach-tone greeting line on daily view — personalized, never metric-based (never "3 overdue contacts")
- Daily view density is user-adjustable via a single tap (expand/collapse) — not in a settings screen
- No tutorial screen — the first friend card form IS the onboarding; the virtual friend provides the stage
- Acquittement must feel like a warm one-tap confirmation, never a form — no interruption, no obligation language
- Post-acquittement: subtle warm animation + gentle offer to reach out to someone else (no pressure)
- Empty daily view = warm "all clear" state — never clinical or alarming
- Typography: DM Sans (primary typeface) + Lora (greeting line candidate)
- No shame/guilt/debt mechanics anywhere: no overdue counts displayed as red badges, no streak mechanics, no punitive language
- Touch-first, portrait primary; Samsung S25 as primary test device
- Adjustable density preference persisted (shared_preferences)
- All design tokens centralized in `lib/shared/theme/app_tokens.dart`

**From Architecture Phase 2 Addendum — On-Device LLM (impacts Phase 2 Epics 10):**
- LLM integration: `flutter_gemma` package wrapping MediaPipe Tasks GenAI API — Dart-native, isolate-compatible
- Model: Gemma-3n-E2B-it (INT4 quantised, ~2 GB, well within 4 GB NFR20 constraint)
- Model downloaded once to `getApplicationDocumentsDirectory()` internal storage — never bundled in APK
- Two capability gates: `AiCapabilityChecker` (Android API ≥ 29 + RAM ≥ 4 GB) + `ModelManager` (model downloaded state machine)
- If hardware unsupported → LLM features fully hidden (no dead UI elements)
- If model not downloaded → `ModelDownloadScreen` hard gate before any LLM feature
- Core AI module: `lib/core/ai/` contains `llm_inference_service.dart`, `model_manager.dart`, `ai_capability_checker.dart`, `prompt_templates.dart`, `greeting_service.dart`
- `LlmInferenceService`: all inference runs in `Dart Isolate` — UI thread never blocked; 30-second timeout with static fallback
- `PromptTemplates`: all prompts centralised as constants — no runtime prompt construction outside this file
- UC1 (daily greeting line): `GreetingService` generates coach-tone greeting async post-view-load; static fallback shown immediately while awaiting — zero degraded UX
- UC2 (message suggestion): user taps "Suggest message" on event → LLM generates ≥ 3 variants → `DraftMessageSheet` shows variants for selection/editing/copy-and-send
- `DraftMessage` is session-only in-memory Riverpod state — NOT persisted to SQLite (no schema migration needed)
- `DraftMessageSheet`: event context header, 3 variant cards, editable text field, "Copy & Send via WhatsApp/SMS" → `ContactActionService`
- Session-draft storage: `FriendFormDraftNotifier` (Riverpod) persists friend form state in-memory during session — clears on save or explicit discard
- pubspec.yaml Phase 2 LLM addition: `flutter_gemma: ^1.x.x`
- No additional Android permissions beyond `INTERNET` already added for WebDAV

### FR Coverage Map

FR1: Epic 2 — Import fiche depuis contacts téléphoniques
FR2: Epic 2 — Création manuelle fiche (nom + mobile)
FR3: Epic 2 — Assignation de tags de catégorie
FR4: Epic 2 — Notes libres contextuelles sur la fiche
FR5: Epic 2 — Liste de toutes les fiches
FR6: Epic 2 — Ouverture fiche complète avec détails + historique
FR7: Epic 2 — Édition de tout champ d'une fiche
FR8: Epic 2 — Suppression de fiche
FR9: Epic 2 — Flag préoccupation active avec note descriptive
FR10: Epic 2 — Effacement du flag préoccupation
FR11: **Phase 2 Epic 8** — Filtrage liste d'amis par tags de catégorie
FR12: **Phase 2 Epic 8** — Recherche dans la liste d'amis par nom
FR13: **Phase 2 Epic 8** — Filtrage par statut (préoccupation active, overdue, no recent contact)
FR14: **Phase 2 Epic 8** — Affichage date dernier contact ("last contact") sur fiche et liste
FR15: Epic 3 — Ajout événement avec date, type, commentaire optionnel
FR16: Epic 3 — Cadence récurrente avec intervalle configurable
FR17: Epic 3 — Édition ou suppression d'événement
FR18: Epic 3 — Édition de la liste des types d'événements (ajout, renommage, suppression, réordre)
FR19: Epic 3 — 5 types d'événements par défaut au premier lancement
FR20: Epic 3 — Acquittement manuel d'un événement depuis la fiche
FR21: **Phase 2 Epic 9** — Cadence follow-up automatique 7j lors de l'activation d'un flag préoccupation; intervalle configurable; cadence supprimée quand flag effacé
FR22: Epic 4 — Vue quotidienne — amis qui nécessitent attention aujourd'hui
FR23: Epic 4 — Surface overdue + aujourd'hui + +3 jours dans la vue quotidienne
FR24: Epic 4 — Score de priorité dynamique (importance type, jours overdue, catégorie, flag ×2, care score bas)
FR25: Epic 4 — Briefing cœur 2+2 (2 urgents + 2 importants) en tête de vue quotidienne
FR26: Epic 4 — Tap sur entrée vue quotidienne → ouvre la fiche ami
FR27: Epic 5 — 1-tap appel téléphonique depuis la fiche
FR28: Epic 5 — 1-tap SMS depuis la fiche
FR29: Epic 5 — 1-tap ouverture WhatsApp depuis la fiche
FR30: Epic 5 — Détection retour app post-action + présentation fiche pré-focalisée pour acquittement
FR31: Epic 5 — Acquittement avec type d'action (call, SMS, WhatsApp, voice, seen in person)
FR32: Epic 5 — Note libre descriptive sur l'acquittement
FR33: Epic 5 — Pré-remplissage type d'action + horodatage au retour app
FR34: Epic 5 — Confirmation acquittement pré-rempli en 1 tap
FR35: Epic 5 — Log chronologique d'historique de contacts par fiche
FR36: Epic 5 — Mise à jour du care score après chaque acquittement
FR37: **Phase 3** — Configuration connexion WebDAV (URL, user, password, passphrase)
FR38: **Phase 3** — Test de connexion WebDAV avant activation sync
FR39: **Phase 3** — Chiffrement client-side AES-256 avant transmission WebDAV
FR40: **Phase 3** — Sync automatique WebDAV dès réseau disponible
FR41: **Phase 3** — Restore complet depuis WebDAV après réinstallation
FR42: Epic 6 (Phase 1) — Export données vers fichier local chiffré
FR43: Epic 6 (Phase 1) — Import et restore depuis fichier local chiffré
FR44: **Phase 2 Epic 10** — Création draft message sur fiche ami
FR45: **Phase 2 Epic 10** — LLM génère ≥ 3 phrasings alternatifs pour le draft
FR46: **Phase 2 Epic 10** — Inférence LLM on-device uniquement, déclenchée par action explicite
FR47: **Phase 2 Epic 10** — Édition, sauvegarde, ou abandon de tout draft avant utilisation
FR48: Epic 7 — Écran paramètres complet éditable
FR49: Epic 7 — Mise à jour du passphrase de sauvegarde et reset configuration backup
FR50: Epic 7 — Fonctionnement complet sans connexion réseau
FR51: **Phase 2 Epic 9** — Configuration de l'intervalle de cadence follow-up (défaut: 7 jours) depuis les paramètres

## Epic List

### Epic 1: Project Foundation & Core Infrastructure
Laurus (and any developer) can initialize the full Spetaka project scaffold with all cross-cutting infrastructure in place — Drift database, AES-256 encryption service, **full sensitive field encryption at the repository layer covering all PII fields including name and mobile (NFR6 complete — Story 1.8)**, AppLifecycle detection, phone number normalization, GoRouter navigation, dark-mode-aware design token system, and GitHub Actions CI/CD — creating a solid, architecture-compliant foundation that unblocks all feature epics.
**FRs covered:** None (technical foundation — unblocks all Phase 1 FRs)
**Additional requirements:** flutter create scaffold, Drift AppDatabase + DAOs skeleton, EncryptionService (AES-256-GCM + PBKDF2), sensitive field encryption at repository layer for narrative fields (NFR6 — Story 1.7), **extend field encryption to `name` and `mobile` (NFR6 complete — Story 1.8)**, AppLifecycleService, PhoneNormalizer, ContactActionService skeleton, GoRouter route tree, app_tokens.dart + AppTheme (light + warm dark mode), GitHub Actions CI/CD (analyze → test → build APK)

### Epic 2: Friend Cards & Circle Management
Laurus can build and manage his full relational circle — create friend cards by importing from phone contacts or manually, assign category tags, add contextual notes, set concern/préoccupation flags, and browse his complete list — giving the app its core data model and making every subsequent feature meaningful.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR10

### Epic 3: Events & Cadences
Laurus can define what matters for each friend — birthdays, anniversaries, important life events, regular check-ins — and set recurring cadence intervals. The event type list is fully personalized. Events are the raw material the priority engine consumes to surface the right people at the right moment.
**FRs covered:** FR15, FR16, FR17, FR18, FR19, FR20

### Epic 4: Daily View & Priority Engine
Laurus has a warm, intelligent daily view that tells him exactly who deserves his care today — powered by a dynamic priority score, the 2+2 heart briefing, a coach-tone greeting line, density control, and a virtual friend "Sophie" on first launch. This is the heart of the Spetaka ritual.
**FRs covered:** FR22, FR23, FR24, FR25, FR26

### Epic 5: Actions & Acquittement — The Care Loop
Laurus can contact any friend in one tap and close the care loop with a warm, frictionless acquittement. The complete gesture — from intention to action to logged contact — happens in seconds. This epic delivers the defining Spetaka experience.
**FRs covered:** FR27, FR28, FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36

### Epic 6: Local Backup & Privacy
Laurus can protect and restore all his relational data with a single AES-256 encrypted local backup file — export to his device, restore on any Android device with his passphrase. No network connection required. WebDAV sync moves to Phase 3.
**FRs covered:** FR42, FR43

### Epic 7: Settings, Offline Resilience & Play Store Release
Laurus has a complete, accessible settings screen, a fully verified offline-first experience, and a Play Store release track ready for 4 weeks of personal validation — then public distribution. Accessibility audit (NFR15–17) and zero-notification architecture verification complete the release readiness checklist.
**FRs covered:** FR48, FR49 (backup passphrase + settings reset), FR50

---

> **Phase 2 Epics below — Epics 8, 9, 10 (scope arrêté le 2026-03-25)**

### Epic 8: Friend List Intelligence — Filters, Search & Last Contact _(Phase 2)_
Laurus can filter his friend list by category tags, search by name, filter by status (concern, overdue, no recent contact), and see when he last reached each person directly on the card and list view — making his growing circle navigable and immediately contextual at a glance.
**FRs covered:** FR11, FR12, FR13, FR14

### Epic 9: Smart Concern Cadence _(Phase 2)_
When Laurus marks a friend as going through something difficult, Spetaka automatically creates a check-in cadence so that friend stays top-of-mind with no manual configuration. The default interval is configurable in settings. The cadence is automatically removed when the concern is cleared.
**FRs covered:** FR21, FR51

### Epic 10: On-Device LLM & Message Assistance _(Phase 2)_
Laurus can request on-device LLM-generated message suggestions for any event on a friend card — producing ≥ 3 warm, contextualised WhatsApp or SMS variants instantly, with no network call and no passphrase required. The daily greeting line is also enriched by the LLM when the model is available. Everything runs on-device; nothing is transmitted.
**FRs covered:** FR44, FR45, FR46, FR47
**NFRs addressed:** NFR18, NFR19, NFR20, NFR21

---

## Epic 1: Project Foundation & Core Infrastructure

Laurus (and any developer) can initialize the full Spetaka project scaffold with all cross-cutting infrastructure in place — Drift database, AES-256 encryption service, sensitive field encryption at the repository layer (NFR6), AppLifecycle detection, phone number normalization, GoRouter navigation, dark-mode-aware design token system, and GitHub Actions CI/CD — creating a solid, architecture-compliant foundation that unblocks all feature epics.

### Story 1.1: Flutter Project Scaffold & Feature-First Architecture

As a developer,
I want to initialize the Spetaka Flutter project with the correct structure, all dependencies, and a feature-first clean architecture,
So that every subsequent story has a consistent, architecture-compliant foundation to build upon with no structural rework needed.

**Acceptance Criteria:**

**Given** a clean development environment with Flutter SDK installed
**When** `flutter create --org dev.spetaka --platforms android spetaka` is run and the scaffold is configured
**Then** the project compiles with `flutter build apk --release` without errors
**And** `pubspec.yaml` declares all required dependencies: `riverpod_annotation ^3.2.1`, `drift ^2.31.0`, `go_router ^14.6.3`, `encrypt ^5.0.3`, `webdav_client ^3.0.1`, `flutter_contacts ^1.1.9+2`, `url_launcher ^6.3.1`, `uuid ^4.5.1`, `shared_preferences ^2.3.5`, `intl`, plus `dev_dependencies`: `riverpod_generator`, `drift_dev`, `build_runner`, `flutter_lints`
**And** the directory structure `lib/core/`, `lib/features/`, `lib/shared/` exists as specified in the architecture document
**And** `analysis_options.yaml` is configured with `flutter_lints`
**And** `android/app/build.gradle` sets `minSdkVersion 26` and latest stable `targetSdkVersion`
**And** `AndroidManifest.xml` declares only `INTERNET` and `READ_CONTACTS` permissions — no notification channels, no FCM
**And** `flutter analyze` returns zero errors or warnings
**And** `build_runner` generates code successfully for Riverpod and Drift

### Story 1.2: Drift Database Foundation & Migration Infrastructure

As a developer,
I want an AppDatabase class with migration strategy and a clean DAO infrastructure in place,
So that all feature stories can add their entities and queries to a stable, well-structured database layer without conflicts.

**Acceptance Criteria:**

**Given** the Flutter project scaffold from Story 1.1 exists
**When** the Drift database foundation is set up
**Then** `lib/core/database/app_database.dart` exists with `AppDatabase extends _$AppDatabase`, `schemaVersion = 1`, and `MigrationStrategy` with `onUpgrade` and `beforeOpen` hooks
**And** `lib/core/database/daos/` contains empty DAO stub files: `friend_dao.dart`, `event_dao.dart`, `acquittement_dao.dart`, `settings_dao.dart` — each with a class declaration and a comment indicating where queries will be added
**And** `AppDatabase` is exposed as a Riverpod provider via `@riverpod` code generation, accessible from any feature
**And** `NativeDatabase.memory()` is confirmed working in tests for an in-memory database fixture
**And** `flutter test test/unit/database_foundation_test.dart` passes — verifies DB opens, `schemaVersion` is 1, migration hooks are callable without error

### Story 1.3: AES-256 Encryption Service

As a developer,
I want a tested, reusable encryption service implementing AES-256-GCM with PBKDF2 key derivation,
So that sync and export features can encrypt data before it leaves the device, with the passphrase never stored or transmitted.

**Acceptance Criteria:**

**Given** `encrypt ^5.0.3` and `crypto` packages are declared in `pubspec.yaml`
**When** `EncryptionService` is initialized with a user passphrase
**Then** `lib/core/encryption/encryption_service.dart` exposes `encrypt(String plaintext) → String` and `decrypt(String ciphertext) → String` using AES-256-GCM mode
**And** key derivation uses PBKDF2 with 100,000 iterations, SHA-256, 256-bit output via `dart:crypto`
**And** a random salt is generated at first setup and stored in `shared_preferences` — the passphrase and derived key are never written to disk
**And** the derived key is held in memory only during an active session, cleared on app backgrounding
**And** `EncryptionService` is exposed as a Riverpod provider
**And** `flutter test test/unit/encryption_service_test.dart` passes: encrypt→decrypt returns original plaintext; two encryptions of the same plaintext produce different ciphertexts (GCM nonce is random); decrypting with a wrong passphrase throws a typed `AppError`

### Story 1.4: App Shell, GoRouter Navigation & Design System

As a developer,
I want the complete app shell with GoRouter route tree, Material 3 theme, and all design tokens in place,
So that every feature screen has a consistent navigation framework and visual foundation to build upon.

**Acceptance Criteria:**

**Given** the project scaffold from Story 1.1 exists
**When** the app shell is configured
**Then** `lib/app.dart` contains `MaterialApp.router` with `GoRouter` and `ProviderScope`
**And** `lib/core/router/app_router.dart` defines the complete typed route tree: `/` → `DailyViewScreen`, `/friends` → `FriendsListScreen`, `/friends/new` → `FriendFormScreen`, `/friends/:id` → `FriendCardScreen`, `/settings` → `SettingsScreen` — **`/settings/sync` (WebDavSetupScreen) is Phase 3** — each screen is a placeholder widget with a title `Text` for now
**And** `lib/shared/theme/app_tokens.dart` defines all design tokens: color palette (calm, warm), spacing scale, border radii, typography scale (DM Sans primary, Lora for greeting line), motion durations
**And** `lib/shared/theme/app_theme.dart` builds `ThemeData` with M3 `ColorScheme` derived from tokens
**And** `lib/shared/widgets/loading_widget.dart` and `lib/shared/widgets/error_widget.dart` exist as reusable standard states
**And** the app launches on Android to the placeholder daily view — no crashes, `flutter analyze` clean, all routes navigable
**And** `MaterialApp.router` is configured with both `theme:` and `darkTheme:` — the dark theme uses warm brown tokens (`color.background.dark: #1E1A17`, `color.surface.dark: #2A2420`) from `app_tokens.dart` so the app never falls back to cold M3 grey in system dark mode

### Story 1.5: Core Utilities — AppLifecycle, PhoneNormalizer & ContactActionService

As a developer,
I want the three critical cross-cutting utilities built and tested as isolated services,
So that actions, acquittement, and friend features can rely on proven, consistent behavior without duplicating logic.

**Acceptance Criteria:**

**Given** the project scaffold and design system from Stories 1.1–1.4 exist
**When** the core utilities are implemented
**Then** `lib/core/lifecycle/app_lifecycle_service.dart` observes `AppLifecycleState.resumed` and exposes a `Stream<String?> pendingAcquittementFriendId` stream via a Riverpod provider; emits `null` when no action has been taken; never uses `WidgetsBindingObserver` directly in feature widgets
**And** `lib/core/actions/phone_normalizer.dart` provides `normalize(String raw) → String` converting phone numbers to E.164 international format; returns a typed `AppError` for unparseable inputs
**And** `lib/core/actions/contact_action_service.dart` exposes `call(String number)`, `sms(String number)`, `whatsapp(String number)` — each normalizes the number and fires the correct `url_launcher` intent; widgets never call `url_launcher` directly
**And** `lib/core/errors/app_error.dart` defines the typed domain error hierarchy; `lib/core/errors/error_messages.dart` contains all user-visible strings — no raw exception messages exposed to UI
**And** `flutter test test/unit/phone_normalizer_test.dart` passes: `0612345678` → `+33612345678`; `+33612345678` unchanged; letters-only input returns `AppError`

### Story 1.6: GitHub Actions CI/CD Pipeline

As a developer (Laurus),
I want a GitHub Actions workflow that analyzes, tests, and builds the APK on every push to `main` and on pull requests,
So that regressions are caught immediately and a release-ready APK artifact is always available.

**Acceptance Criteria:**

**Given** the project repository exists on GitHub
**When** code is pushed to `main` or a pull request is opened
**Then** `.github/workflows/ci.yml` exists and triggers on `push: branches: [main]` and `pull_request:`
**And** the workflow runs three sequential steps in order: `flutter analyze` → `flutter test` → `flutter build apk --release`
**And** the workflow caches the Flutter SDK and pub package cache to minimize build time
**And** if `flutter analyze` or `flutter test` fails, the subsequent steps do not run and the workflow fails with a clear status
**And** the built APK is uploaded as a workflow artifact via `actions/upload-artifact` for manual download
**And** a first successful CI run on the repository is confirmed (green checkmark on `main`)

### Story 1.7: Sensitive Field Encryption at Repository Layer (NFR6)

As a developer,
I want sensitive narrative fields encrypted before writing to SQLite and transparently decrypted on read,
So that NFR6 (data encrypted at rest) is satisfied without SQLCipher — relying on the existing `EncryptionService` at the repository layer.

**Acceptance Criteria:**

**Given** `EncryptionService` from Story 1.3 is available with an active in-memory derived key
**When** `FriendRepository` or `AcquittementRepository` writes a record to SQLite
**Then** the following fields are encrypted via `EncryptionService.encrypt()` before the Drift DAO persists them: `friends.notes`, `friends.concern_note`, `acquittements.note`
**And** on read, these same fields are decrypted via `EncryptionService.decrypt()` at the repository layer before being returned to any provider or widget — no widget ever receives a raw ciphertext string
**And** `friends.notes`, `friends.concern_note`, and `acquittements.note` are encrypted — these are the narrative fields addressed by this story
**And** `friends.name` and `friends.mobile` are **deferred to Story 1.8** — encrypted using the same pattern to complete NFR6 for all PII fields
**And** `friends.tags`, `care_score`, and all non-PII/non-narrative fields remain plaintext (required for sort, score computation)
**And** encryption and decryption logic is centralized in `FriendRepository` and `AcquittementRepository` — Drift DAO classes are NOT encryption-aware; they receive and return raw stored values
**And** if decryption fails for any field (e.g., session key not yet initialized), a typed `AppError.sessionExpired` is thrown — the app prompts the user to re-enter their passphrase
**And** `flutter test test/repositories/field_encryption_test.dart` passes:
  - Write `FriendRecord` with non-empty `notes` → read back → `notes` equals original plaintext
  - Inspect raw Drift DAO value for the same record → confirms the stored value is NOT the plaintext (it is ciphertext)
  - Write `AcquittementRecord` with a `note` → read back → `note` equals original plaintext
  - Attempt read without initialized `EncryptionService` key → returns `AppError.sessionExpired`

---

### Story 1.8: Extend Field Encryption to `name` and `mobile` (NFR6 Complete)

As a developer,
I want `friends.name` and `friends.mobile` encrypted at the repository layer using the existing `EncryptionService`,
So that NFR6 is fully satisfied — no plaintext personally identifiable data is ever written to the SQLite database file.

**Acceptance Criteria:**

**Given** `EncryptionService` from Story 1.3 is available with an active in-memory derived key
**When** `FriendRepository` writes a friend record to SQLite (create or update)
**Then** both `friends.name` and `friends.mobile` are encrypted via `EncryptionService.encrypt()` before reaching the Drift DAO — the DAO only ever sees ciphertext for these columns

**Given** name and mobile are stored as ciphertext in SQLite
**When** `FriendRepository` reads records from the DAO
**Then** both fields are decrypted before returning `Friend` objects to providers or widgets — no widget or provider ever receives ciphertext

**Given** `FriendRepository.watchAll()` previously sorted by `name` at the Drift query level
**When** names are stored as ciphertext
**Then** sorting is performed in-memory in the repository after decryption using `list.sort((a, b) => a.name.compareTo(b.name))`

**Given** `ContactActionService` needs the mobile number for phone/SMS/WhatsApp intents
**When** a friend's mobile field is accessed anywhere downstream
**Then** `ContactActionService` and `PhoneNormalizer` always receive the decrypted plaintext mobile — decryption is transparent to all callers outside the repository

**Given** non-PII fields exist on the friend model
**Then** `care_score`, `is_concern_active`, `tags`, `created_at`, `updated_at`, `id` remain plaintext for query optimization and sort operations

**Given** decryption fails (session key not initialized)
**Then** the same typed `AppError` hierarchy from Story 1.7 is thrown — `EncryptionNotInitializedAppError`, `DecryptionFailedAppError`, `CiphertextFormatAppError` as appropriate

**Given** this story is implemented
**When** `flutter test test/repositories/field_encryption_test.dart` runs
**Then** tests pass, including: `name` and `mobile` roundtrip (write → read via repository → values match original); ciphertext-at-rest assertion (DAO-stored value ≠ original plaintext); `watchAll()` returns alphabetically sorted friends; EncryptionNotInitializedAppError thrown without an active key

---

## Epic 2: Friend Cards & Circle Management

Laurus can build and manage his full relational circle — create friend cards by importing from phone contacts or manually, assign category tags, add contextual notes, set concern/préoccupation flags, and browse his complete list.

### Story 2.1: Friend Card Creation via Phone Contact Import

As Laurus,
I want to create a friend card by selecting a contact from my phone's address book,
So that I don't have to type names or phone numbers manually — the card is pre-filled in one tap.

**Acceptance Criteria:**

**Given** Laurus is on the friends list or any main screen and taps "Add friend"
**When** he selects "Import from contacts" and grants `READ_CONTACTS` permission
**Then** the Android contact picker opens (`flutter_contacts`) and Laurus can search and select a contact
**And** the new friend card is pre-filled with the contact's display name and primary mobile number in E.164 format (via `PhoneNormalizer`)
**And** only name and primary mobile are imported — no photo in v1
**And** `READ_CONTACTS` permission is requested at this moment only, not at app launch; if denied, the flow falls back to manual entry (Story 2.2)
**And** the `friends` Drift table is created with columns: `id TEXT` (UUID), `name TEXT`, `mobile TEXT`, `notes TEXT`, `care_score REAL`, `is_concern_active INTEGER` (bool), `concern_note TEXT`, `created_at INTEGER`, `updated_at INTEGER`
**And** the new friend card is saved to SQLite with a UUID v4 `id` and `care_score = 0.0`
**And** `flutter test test/repositories/friend_repository_test.dart` passes: friend created, persisted, and retrievable by ID

### Story 2.2: Friend Card Creation via Manual Entry

As Laurus,
I want to create a friend card by typing a name and phone number manually,
So that I can add friends whose numbers aren't in my phone contacts, or when I've declined the contacts permission.

**Acceptance Criteria:**

**Given** Laurus is on the friend form screen (reached via "Add friend" → manual entry, or contact import permission denied)
**When** he enters a name and mobile number and taps Save
**Then** the form validates that name is non-empty and mobile is a parseable phone number (via `PhoneNormalizer`)
**And** if the number is invalid, an inline error message from `error_messages.dart` is shown — no toast, no modal; Laurus can correct and retry
**And** on valid submission the friend card is saved to SQLite with UUID v4 `id`, normalized E.164 mobile, and `care_score = 0.0`
**And** the form uses `FriendFormScreen` — all interactive elements meet 48×48dp minimum touch target (NFR15)
**And** the form navigates back to the friends list on success, showing the new card

### Story 2.3: Category Tags Assignment

As Laurus,
I want to assign one or more category tags to a friend card (e.g., "Family", "Close friends", "Work"),
So that the priority engine can weight relationships by category and I can organize my circle meaningfully.

**Acceptance Criteria:**

**Given** Laurus is creating or editing a friend card
**When** he taps the tags field
**Then** a tag selector appears with a predefined list of category options (minimum: "Family", "Close friends", "Friends", "Work", "Other")
**And** Laurus can select multiple tags; selected tags are visually highlighted with a minimum 48×48dp tap target per tag
**And** selected tags are stored in the `friends` table as a `tags TEXT` column (comma-separated or JSON array)
**And** saving the card persists the tags and they are visible on the friend card detail view
**And** tags are displayed as chips on the `FriendCardScreen` and `FriendCardTile`

### Story 2.4: Context Notes on Friend Card

As Laurus,
I want to add and edit a free-text note on a friend card,
So that I can capture important context about a friend — their situation, what we last talked about, what matters to them.

**Acceptance Criteria:**

**Given** Laurus is viewing or editing a friend card
**When** he taps the notes field and types a note
**Then** the note is saved to the `notes TEXT` column on the `friends` table on form submission
**And** the note is displayed on `FriendCardScreen` — multiline text, readable without truncation for typical lengths
**And** Laurus can edit the note at any time by opening edit mode
**And** the notes field is optional — saving a card without a note is valid

### Story 2.5: Friends List View

As Laurus,
I want to see all my friend cards in a browsable list,
So that I can find any friend quickly and see who is in my circle at a glance.

**Acceptance Criteria:**

**Given** Laurus navigates to `/friends` (`FriendsListScreen`)
**When** the screen loads
**Then** all `friends` records from SQLite are displayed as a scrollable list of `FriendCardTile` widgets
**And** each tile shows: friend name, category tags (as chips), and concern flag indicator if active
**And** the list loads reactively from a Riverpod `StreamProvider` backed by a Drift `watchAll()` query — updates automatically when data changes
**And** an empty state widget is shown when no friends exist yet, with a prompt to add the first friend
**And** the screen opens within 300ms on the primary device (NFR4)
**And** the list is navigable with TalkBack — each tile has a meaningful content description (NFR17)

### Story 2.6: Friend Card Detail View

As Laurus,
I want to open a friend card to see all its details — name, mobile, tags, notes, events, and contact history,
So that I have full context before reaching out and can see the full relationship history at a glance.

**Acceptance Criteria:**

**Given** Laurus taps a friend from the friends list or daily view
**When** `FriendCardScreen` opens at `/friends/:id`
**Then** the screen displays: name, mobile (formatted), tags, notes, active concern note (if set), list of events (from Epic 3 — shown as empty placeholder for now), and contact history log (from Epic 5 — shown as empty placeholder for now)
**And** 1-tap action buttons (Call, SMS, WhatsApp) are prominently displayed — they are placeholder buttons for now, wired up in Epic 5
**And** the screen opens within 300ms (NFR4)
**And** an edit button navigates to `FriendFormScreen` in edit mode for this friend
**And** the screen is reactive — changes to the friend in SQLite (e.g., updated care score) reflect without manually refreshing

### Story 2.7: Edit Friend Card

As Laurus,
I want to edit any field on a friend card at any time,
So that my circle stays accurate as relationships evolve — numbers change, notes need updating, tags change.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen` and taps the edit button
**When** `FriendFormScreen` opens in edit mode pre-populated with current values
**Then** all fields are editable: name, mobile, tags, notes
**And** saving updates the existing record in SQLite (same UUID `id`), setting `updated_at` to current timestamp
**And** navigating back to `FriendCardScreen` reflects the updated values immediately (reactive stream)
**And** if the mobile number is changed to an invalid format, the same inline validation from Story 2.2 is applied

### Story 2.8: Delete Friend Card

As Laurus,
I want to delete a friend card,
So that I can remove contacts that are no longer relevant and keep my circle clean.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen`
**When** he taps the delete option and confirms in `DeleteConfirmDialog`
**Then** the friend record is deleted from SQLite along with all associated events and acquittements (cascade delete)
**And** the dialog clearly states what will be deleted — name of the friend and a warning that all history will be lost
**And** confirming deletion navigates back to `FriendsListScreen`; cancelling returns to `FriendCardScreen` unchanged
**And** the deletion is immediate and persistent — reopening the app confirms the friend is gone

### Story 2.9: Concern / Préoccupation Flag

As Laurus,
I want to mark a friend as going through something difficult, with a short descriptive note,
So that Spetaka elevates their priority in the daily view and I'm reminded to give them extra care.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen`
**When** he taps "Set concern" and enters a short descriptive note (e.g., "Going through a difficult divorce")
**Then** `is_concern_active` is set to `true` and `concern_note` is saved on the friend record in SQLite
**And** the concern flag and note are visually displayed on `FriendCardScreen` and `FriendCardTile` — distinctive but not alarming styling
**And** when Laurus taps "Clear concern", `is_concern_active` is set to `false` and `concern_note` is cleared — a confirmation dialog is shown before clearing
**And** the priority engine (Epic 4) will use `is_concern_active` as a ×2 multiplier — the field is available in the Drift stream from now on
**And** `flutter test test/repositories/friend_repository_test.dart` includes: set concern, verify `is_concern_active = true`, clear concern, verify `is_concern_active = false`

---

## Epic 3: Events & Cadences

Laurus can define what matters for each friend — birthdays, anniversaries, important life events, regular check-ins — and configure recurring cadence intervals. The event type list is fully personalized.

### Story 3.1: Add a Dated Event to a Friend Card

As Laurus,
I want to add a specific dated event to a friend card (e.g., birthday on March 15, wedding anniversary on June 8),
So that Spetaka knows when important dates are coming and can surface this friend in the daily view at the right time.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen` and taps "Add event"
**When** he selects an event type, sets a date, and optionally adds a comment
**Then** the `events` Drift table is created with columns: `id TEXT` (UUID), `friend_id TEXT` (FK → friends.id), `type TEXT` (event type name), `date INTEGER` (Unix epoch ms), `is_recurring INTEGER` (bool, false for dated events), `comment TEXT`, `is_acknowledged INTEGER` (bool), `acknowledged_at INTEGER`, `created_at INTEGER`
**And** the event is saved to SQLite with UUID v4 `id`, correct `friend_id`, and `is_recurring = false`
**And** the event appears in the events list on `FriendCardScreen`, showing type, formatted date, and comment
**And** the event type selector shows the 5 default types: birthday, wedding anniversary, important life event, regular check-in, important appointment
**And** the date picker meets 48×48dp touch targets (NFR15)

### Story 3.2: Add a Recurring Check-in Cadence

As Laurus,
I want to set a recurring check-in cadence on a friend card with a configurable interval (e.g., "every 3 weeks"),
So that Spetaka surfaces this friend in the daily view when the interval has elapsed since my last contact.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen` and taps "Add event" → selects "Regular check-in" type
**When** he configures a recurrence interval (e.g., every 14 days, every 3 weeks, every month) and saves
**Then** the event is saved with `is_recurring = true` and a `cadence_days INTEGER` column on the `events` table added via Drift migration (schemaVersion incremented)
**And** the cadence interval options include at minimum: every 7 days, 14 days, 21 days, 30 days, 60 days, 90 days — shown as human-readable labels ("Every week", "Every 2 weeks", etc.)
**And** the cadence event appears in the events list labeled with its interval (e.g., "Regular check-in — every 3 weeks")
**And** the priority engine (Epic 4) will use `is_recurring`, `cadence_days`, and last acquittement date to compute overdue days for cadences — the fields are available in the Drift stream from now on

### Story 3.3: Edit or Delete an Event

As Laurus,
I want to edit or delete any event on a friend card,
So that I can correct mistakes, update dates that change, or remove events that are no longer relevant.

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen` viewing the events list
**When** he long-presses or taps an edit icon on an event
**Then** an edit form opens pre-filled with current event values (type, date, comment, recurrence for cadences)
**And** saving updates the event record in SQLite — `updated_at` (if column exists) reflects the change
**And** a delete option in the edit form shows `DeleteConfirmDialog` before removing — on confirm, the event is deleted from SQLite
**And** the events list on `FriendCardScreen` updates reactively after edit or delete without manual refresh

### Story 3.4: Personalize Event Types

As Laurus,
I want to view, add, rename, reorder, and delete event types,
So that my event vocabulary reflects my actual relationships, not a generic default list.

**Acceptance Criteria:**

**Given** Laurus navigates to the event type management screen (accessible from settings or event creation)
**When** the screen loads
**And** the 5 default event types are displayed: birthday, wedding anniversary, important life event, regular check-in, important appointment — stored in a dedicated `event_types` Drift table in SQLite (`id TEXT`, `name TEXT`, `sort_order INTEGER`, `created_at INTEGER`) so they are included in backup and restore flows; `shared_preferences` is explicitly forbidden for event type storage
**And** Laurus can add a new event type by tapping "Add type" and entering a name
**And** Laurus can rename an existing event type by tapping it and editing inline
**And** Laurus can delete an event type — if any events currently use this type, a warning is shown ("X events use this type — they will keep their current label")
**And** Laurus can reorder event types by drag-and-drop, with the custom order persisted
**And** the event type picker in Stories 3.1 and 3.2 reflects the current personalized list

### Story 3.5: Manual Event Acknowledgement

As Laurus,
I want to manually mark an event as acknowledged from the friend card,
So that I can close the loop on an event even when I didn't use the 1-tap action flow (e.g., I called from my recents without opening Spetaka).

**Acceptance Criteria:**

**Given** Laurus is on `FriendCardScreen` viewing an unacknowledged event
**When** he taps "Mark as done" on the event
**Then** `is_acknowledged` is set to `true` and `acknowledged_at` is set to current timestamp for that event on the `events` table
**And** the event is visually marked as acknowledged in the events list (e.g., checkmark, muted styling)
**And** recurring cadence events: after acknowledgement, the "next due" date is recomputed as `acknowledged_at + cadence_days` and displayed
**And** the priority engine (Epic 4) will exclude acknowledged non-recurring events and recompute due dates for acknowledged cadences — the `is_acknowledged` and `acknowledged_at` fields are available from now on

---

## Epic 4: Daily View & Priority Engine

Laurus has a warm, intelligent daily view that tells him exactly who deserves his care today — powered by a dynamic priority score, the 2+2 heart briefing, a coach-tone greeting line, density control, and a virtual friend "Sophie" on first launch.

### Story 4.1: Priority Engine — Score Computation

As Laurus,
I want the app to compute a dynamic priority score for each friend based on events, relationship category, concern flags, and care history,
So that the daily view always shows me the most important people first, without me having to think about it.

**Acceptance Criteria:**

**Given** friend records with events and care scores exist in SQLite
**When** the priority engine runs
**Then** `lib/features/daily_view/domain/priority_engine.dart` is a pure Dart class (no Flutter, no Riverpod, no DB access) that receives a list of `FriendWithEvents` objects and returns a sorted list with computed `priorityScore`
**And** the scoring formula weights: event type importance (birthday/anniversary higher than regular check-in, using the same `event_type_weight` constants as the care need score), days overdue (linear scaling), friend category tag weight, active concern flag (×2 multiplier on total score), and high care need score boost (friends with `care_score` > 100 receive a priority boost proportional to how overdue they are)
**And** the engine distinguishes urgency tiers: `urgent` (today + overdue unacknowledged) vs `important` (within next 3 days)
**And** computation completes in <500ms for 100 friend cards on the primary device (NFR2)
**And** `flutter test test/unit/priority_engine_test.dart` passes with deterministic test cases: concern friend scores higher than identical friend without concern; overdue event scores higher than upcoming event; acknowledged event not included in score

### Story 4.2: Daily View Surface Window

As Laurus,
I want the daily view to show me friends with overdue events, events today, and events within the next 3 days,
So that I see a meaningful, time-scoped set of people to care for — not the entire future calendar.

**Acceptance Criteria:**

**Given** Laurus navigates to `/` (`DailyViewScreen`)
**When** the screen loads
**Then** a Riverpod `StreamProvider` (backed by Drift reactive queries) computes the set of friends in the surface window: events that are overdue and unacknowledged, events with `date` = today, events with `date` within the next 3 calendar days
**And** the resulting list is passed through `PriorityEngine.sort()` and displayed ordered by `priorityScore` descending
**And** the data pipeline updates reactively — adding a new event or acknowledging one causes the daily view to update within one Drift stream emission
**And** friends with no events in the surface window do not appear in the daily view (they exist in the friends list)
**And** the full screen renders within 1 second on Samsung S25 (NFR1)

### Story 4.3: Heart Briefing 2+2 Widget

As Laurus,
I want to see a "heart briefing" at the top of the daily view showing the 2 most urgent and 2 most important friends,
So that I immediately know the 4 most critical relationships to attend to today — without having to scan a long list.

**Acceptance Criteria:**

**Given** Laurus opens the daily view with friends in the surface window
**When** the `HeartBriefingWidget` renders
**Then** it displays exactly 2 `urgent` entries (today + overdue, highest priority score) and 2 `important` entries (next 3 days, next highest scores) — fewer if fewer are available
**And** each briefing card shows: friend name, reason for surfacing (e.g., "Birthday today", "Check-in overdue 5 days"), and concern indicator if active
**And** if fewer than 2 urgent or 2 important friends exist, the briefing shows only what's available — no empty placeholders
**And** each briefing card is tappable and navigates to the friend's `FriendCardScreen`
**And** the briefing is visually distinct from the rest of the daily list — positioned at the top, differentiated by styling

### Story 4.4: Coach-Tone Greeting Line & Density Control

As Laurus,
I want a warm, personalized greeting line at the top of the daily view and the ability to adjust how many cards I see with a single tap,
So that opening Spetaka feels like a meaningful ritual — not a task board — and I control information density without going to settings.

**Acceptance Criteria:**

**Given** Laurus opens the daily view
**When** the `GreetingLineWidget` renders
**Then** a Lora-font greeting line appears above the heart briefing, dynamically composed based on context: number of urgent friends, time of day (morning/afternoon/evening), Laurus's name from settings — e.g., "Two people could use your warmth today, Laurus."
**And** the greeting tone is always encouraging and uses the user's name — never metric ("3 overdue contacts") and never urgent ("You haven't reached out in 5 days")
**And** greeting copy variants exist for: 0 friends surfaced ("All is well today, Laurus — your circle is looked after."), 1 friend, 2+ friends, concern-flagged friend present
**And** a density toggle (tap to expand / collapse) is visible below the briefing — default "compact" (shows 2+2 briefing + up to 3 more), "expanded" shows all friends in the surface window
**And** the density preference is persisted in `shared_preferences` and restored on next launch (NFR — UX requirement)
**And** `flutter test test/widgets/daily_view_test.dart` includes: greeting renders, density toggle changes visible card count, correct count passed to widget

### Story 4.5: Virtual Friend "Sophie" — First Launch Onboarding

As a new user (Laurus),
I want to see a pre-loaded fictional contact "Sophie" on first launch,
So that I experience the complete Spetaka loop — viewing a card, taking an action, logging an acquittement — before any real data exists, making the product immediately understandable.

**Acceptance Criteria:**

**Given** Laurus opens Spetaka for the first time (no existing friends in SQLite)
**When** the daily view loads
**Then** a pre-seeded fictional friend "Sophie" appears in the daily view with an upcoming "Important appointment" event in 3 days — surfaced in the heart briefing as `important`
**And** Sophie's card is visually labeled as a demo/sample card (subtle indicator) — she is a real SQLite record but flagged `is_demo = true` (add boolean column to `friends` table)
**And** the empty-state greeting reads: "Welcome, Laurus! Sophie has something coming up — see how Spetaka works before adding real friends."
**And** after Laurus adds his first real friend, Sophie remains until he explicitly dismisses her — a "Remove Sophie" option appears on her card
**And** adding the `is_demo` column to the existing `friends` table requires a Drift schema migration: `schemaVersion` is incremented to the next version and `MigrationStrategy.onUpgrade` adds the column with `ALTER TABLE friends ADD COLUMN is_demo INTEGER NOT NULL DEFAULT 0`
**And** Sophie's data does not interfere with priority scoring for real friends (demo friends excluded from priority computation)

### Story 4.6: Daily View — Inline Card Expansion & Detail Access

As Laurus,
I want to tap a friend card in the daily view and see their action buttons expand inline — without leaving the daily view — and be able to open their full profile if needed,
So that reaching out requires zero navigation, and the entire daily ritual stays on one screen.

**Acceptance Criteria:**

**Given** Laurus is on the daily view with friend cards displayed
**When** he taps any collapsed `FriendCardTile`
**Then** the card expands **in place** using `AnimatedSize` + `AnimatedCrossFade` (300ms `easeInOutCubic`) — no GoRouter navigation occurs, no page transition
**And** the expanded card reveals: the `ActionRow` (Call / SMS / WhatsApp buttons), last contact note (muted, 1 line), and a "Full details →" tappable link
**And** tapping a second card collapses the first and expands the second — only one card is expanded at a time
**And** tapping the back gesture / Android back while a card is expanded collapses it; pressing back again exits the app (standard behaviour)
**And** tapping "Full details →" on an expanded card navigates via GoRouter to `/friends/:id` (`FriendCardScreen`) — full profile, edit, and history access
**And** returning from `FriendCardScreen` via back preserves the daily view scroll position and collapsed state
**And** each collapsed tile meets 48×48dp minimum tap area (NFR15) and carries a TalkBack label: `'{name}, {N} days, {event type}'` with hint `'Double-tap to expand'` (NFR17)
**And** the inline expansion animation renders at 60fps on Samsung S25 — validated via Flutter DevTools

---

### Story 4.7: Navigation Swipe — Daily View ↔ Friends List

As Laurus,
I want to swipe left/right to switch between the Daily View and the Friends List,
so that navigation between the two main screens feels fluid and natural, without needing a navigation button.

**Acceptance Criteria:**

**Given** the app shell is implemented with a new `AppShellScreen` hosting a `PageController` + `PageView`
**Then** index 0 = Daily View, index 1 = Friends List; the `people_outline` `IconButton` is removed from the Daily View `AppBar` and all "go to Friends list" triggers use the shared `PageController`
**And** a 2-dot page indicator at the bottom of the shell reflects the active page using `Theme.of(context).colorScheme.primary` (no hard-coded values) with a localized TalkBack semantics label (NFR17)

**Given** Laurus is on the Daily View (index 0)
**When** he swipes left
**Then** the app transitions to the Friends List (index 1); swiping right from Friends List returns to Daily View

**Given** Laurus is on the Friends List (index 1) and presses the Android back button
**When** the system back gesture fires
**Then** the shell animates back to Daily View (index 0) — the app does not exit
**And** pressing back from index 0 applies default behaviour: inner `DailyViewScreen` collapses any expanded card first, then the app exits on a subsequent back

**Given** GoRouter sub-routes are active (`/friends/:id`, `/friends/new`, event edit/new routes, `/settings`)
**When** any sub-route is pushed
**Then** it is pushed above the shell via `parentNavigatorKey` pointing to the root navigator — swipe state is preserved on return; the `PageController` is not reset

**Given** the `PageView` shell is active
**Then** horizontal swipe gestures do not interfere with vertical scroll inside the `CustomScrollView` / `ListView` on either page
**And** the existing `PopScope` on `DailyViewScreen` (collapse expanded card before exit) functions correctly without conflict with the shell's own back handling

**Technical:** GoRouter `ShellRoute` refactor required. Full task breakdown and dev notes: `_bmad-output/implementation-artifacts/4-7-swipe-navigation-daily-friends.md`. New file: `lib/features/shell/presentation/app_shell_screen.dart`.

---

## Epic 5: Actions & Acquittement — The Care Loop

Laurus can contact any friend in one tap and close the care loop with a warm, frictionless acquittement. The complete gesture — from intention to action to logged contact — happens in seconds.

### Story 5.1: 1-Tap Call, SMS & WhatsApp Actions

As Laurus,
I want to initiate a phone call, SMS, or WhatsApp message from a friend's card with a single tap,
So that the friction between "I should reach out" and actually doing it is eliminated entirely.

**Acceptance Criteria:**

**Given** Laurus is on the daily view with an inline-expanded friend card, OR on `FriendCardScreen` for a friend with a stored mobile number
**When** he taps Call, SMS, or WhatsApp action button
**Then** `ContactActionService` normalizes the number to E.164 and fires the correct intent: `tel:+XXXXX` for call, `sms:+XXXXX` for SMS, `https://wa.me/XXXXX` for WhatsApp
**And** the intent launches the target app within 500ms (NFR3)
**And** if WhatsApp is not installed, `url_launcher` returns `false` and an inline message from `error_messages.dart` is shown — never a crash
**And** if the stored number is not in valid E.164 format (edge case), an error message prompts Laurus to edit the friend's number — the button does not fire an invalid intent
**And** `AppLifecycleService` records the `friendId` and action type at the moment the intent fires, enabling the acquittement trigger in Story 5.2
**And** action buttons meet 48×48dp touch target and are TalkBack-labelled (NFR15, NFR17)

### Story 5.2: App Return Detection & Acquittement Trigger

As Laurus,
I want the app to detect when I return after contacting a friend and automatically focus on that friend's card for acquittement,
So that closing the care loop requires no navigation — the app is already where I need it.

**Acceptance Criteria:**

**Given** Laurus tapped a 1-tap action from either the inline-expanded daily view card OR `FriendCardScreen`, and the target app opened
**When** Laurus returns to the Spetaka app (app moves to `AppLifecycleState.resumed`)
**Then** `AppLifecycleService` emits the pending `friendId` on its `pendingAcquittementFriendId` stream
**And** if the action was triggered from the **daily view inline card**: the app stays on the daily view with that card remaining expanded, and the acquittement bottom sheet (Story 5.3) opens over the daily view
**And** if the action was triggered from **`FriendCardScreen`**: the app navigates to (or stays on) `FriendCardScreen` for that friend and the acquittement sheet opens automatically
**And** the session state (pending friend ID + action type) is cleared from `AppLifecycleService` after the acquittement sheet opens, regardless of whether Laurus completes it
**And** if Laurus returns to the app more than 30 minutes after firing the intent (configurable constant), the auto-trigger does not fire — a manual "Log contact" button on the card remains available
**And** the OEM fallback: if `AppLifecycleState.resumed` is not reliably triggered (Samsung OEM issue), a persistent "I just reached out" button is visible on `FriendCardScreen` to manually trigger the acquittement sheet

### Story 5.3: Acquittement Sheet — Type, Note & One-Tap Confirm

As Laurus,
I want to log a contact gesture with an action type and optional note, with the prompt pre-filled from my detected action,
So that closing the care loop feels like a warm confirmation — never a form — and I can add context about the conversation in seconds.

**Acceptance Criteria:**

**Given** the acquittement sheet opens (triggered automatically or via "Log contact" button)
**When** `AcquittementSheet` renders as a bottom sheet
**Then** the `acquittements` Drift table is created with columns: `id TEXT` (UUID), `friend_id TEXT` (FK), `action_type TEXT` (call/sms/whatsapp/voice_message/seen_in_person), `note TEXT`, `logged_at INTEGER` (Unix ms), `created_at INTEGER`
**And** the sheet is pre-filled with the detected `action_type` and current `logged_at` timestamp — Laurus only needs to tap "Confirm" for the happy path (one tap, FR29)
**And** the action type selector shows all 5 options (call, SMS, WhatsApp message, voice message, seen in person) — Laurus can change the pre-filled type before confirming
**And** an optional free-text `note` field is available for conversation context — not required; focus is never forced to it
**And** a subtle warm animation/affirming micro-copy appears on confirm (e.g., "You showed up for [name] ✓") before the sheet dismisses
**And** the sheet offers a gentle "Reach out to someone else?" prompt after confirming — one tap redirects to daily view, one tap dismisses

### Story 5.4: Contact History Log per Friend

As Laurus,
I want to see a chronological log of all my past contacts with a friend — action type, date, and notes,
So that I can recall our last conversation, see how often I've reached out, and feel the continuity of the relationship.

**Acceptance Criteria:**

**Given** one or more acquittements have been logged for a friend
**When** Laurus opens `FriendCardScreen`
**Then** the contact history section displays all acquittements for this friend in reverse chronological order (most recent first)
**And** each entry shows: action type icon, human-readable date (e.g., "3 days ago", "Feb 12"), and note preview (truncated to 2 lines with expand option)
**And** the history is populated from a Riverpod `StreamProvider` backed by a Drift `watchAllForFriend(friendId)` query — updates reactively on new acquittement
**And** the history section is accessible via TalkBack with meaningful content descriptions (date + action type + note snippet) per entry (NFR17)
**And** the history section gracefully shows "No contacts logged yet" when empty

### Story 5.5: Care Score Update After Acquittement

As Laurus,
I want the app to automatically update a friend's care score when I log an acquittement,
So that the priority engine has fresh signal about how recently and frequently I've been in touch, and surfaces friends accordingly.

**Acceptance Criteria:**

**Given** Laurus confirms an acquittement in the `AcquittementSheet`
**When** the acquittement is saved to SQLite
**Then** `AcquittementRepository.logAcquittement()` atomically saves the acquittement record AND updates `care_score` on the `friends` table in a single Drift transaction
**And** the care score formula is defined as a **care need score** in `PriorityEngine` — it measures how urgently a friend needs attention, not historical contact frequency. For each active (unacknowledged) event on the friend, the per-event need score is computed as:
  `care_need_score = (days_since_last_contact / expected_interval) × event_type_weight × 100`
  where `expected_interval` = `cadence_days` for recurring events; 365 for annual events (birthday, anniversary); 90 for one-time events without a cadence;
  and `event_type_weight`: important appointment or medical → 3.0; birthday or anniversary → 2.0; regular check-in → 1.0; default → 1.0.
  The friend's `care_score` = the **maximum** `care_need_score` across all their active events. Score of 100 means the contact is exactly due; >100 means overdue. Resets toward 0 when the relevant event is acknowledged.
**And** all `event_type_weight` constants and `expected_interval` defaults are defined as named constants in `lib/features/daily_view/domain/priority_engine.dart` — no magic numbers inline
**And** `care_score` is stored as a `REAL` column on `friends` — recomputed and written atomically, never lazily recalculated at query time
**And** the updated care score is immediately visible via the reactive Riverpod stream — `FriendCardScreen` reflects the new score without manual refresh
**And** `flutter test test/repositories/acquittement_repository_test.dart` passes: log acquittement on an overdue recurring event → verify `care_score` decreases (event acknowledged, need reduces); verify a friend never-contacted with upcoming birthday has higher `care_score` than one contacted yesterday; verify `event_type_weight` of 3.0 for important appointment produces 3× the score of a regular check-in at the same overdue interval

---

## Epic 6: Local Backup & Privacy

Laurus can protect and restore all his relational data with a single AES-256-GCM encrypted local backup file — exported to device storage, restorable to any Android device using his passphrase. No network connection required. WebDAV sync is deferred to Phase 3.

> **Phase 1 scope change:** WebDAV stories (original 6.1–6.4) are deferred to Phase 3 _(decision 2026-03-25)_.
> This epic now has a single story: encrypted local file export and import.
> The implementation artifact `6-5-encrypted-local-file-export-import.md` is the
> authoritative Phase 1 spec (now re-titled Story 6.1 internally).

### Story 6.1: Encrypted Local Backup — Export & Import

As Laurus,
I want to export all my relationship data to a single encrypted file on my device and restore it at any time by entering my passphrase,
So that my data is portable, recoverable after reinstall, and never dependent on a third-party server or network connection.

**Acceptance Criteria:**

**Given** Laurus navigates to the Backup section in Settings
**When** he taps "Export backup" and enters a passphrase
**Then** all data (friends, events, acquittements, event_types, settings) is serialized to JSON via `toJson()` on each model; demo friends (`is_demo = true`) are excluded
**And** the JSON payload is encrypted with `EncryptionService.encrypt()` using a key derived from the entered passphrase + PBKDF2 salt
**And** the encrypted file is saved to device storage as `spetaka_backup_YYYYMMDD_HHMMSS.enc`
**And** a confirmation snackbar shows the saved file path
**And** the passphrase is never written to disk or logged — the derived key is discarded after the file operation

**Given** the exported file exists
**Then** it is a complete, self-contained snapshot — every friend card, event, acquittement, event type, and setting — restorable to any Android device with Spetaka installed (NFR14)

**Given** Laurus taps "Import backup", selects a `.enc` file, and enters his passphrase
**When** the decryption succeeds
**Then** all entities are written to SQLite via their repositories (same UUIDs, no conflicts)
**And** the daily view reflects restored data within one Drift stream emission
**And** on success, a confirmation message is shown and the user navigates to the daily view

**Given** the file is corrupted or the passphrase is wrong
**Then** a typed error from `error_messages.dart` is shown — no partial data is written
**And** existing local data is untouched on any import failure

**And** export and import show a loading state via Riverpod `AsyncValue` while in progress
**And** all passphrase fields include clear UX copy: "Your passphrase encrypts everything. If you lose it, your backup cannot be recovered."

---

## Epic 7: Settings, Offline Resilience & Play Store Release

Laurus has a complete, accessible settings screen, a fully verified offline-first experience, and a Play Store release track ready for 4 weeks of personal validation — then public distribution.

### Story 7.1: Complete Settings Screen

As Laurus,
I want a single, organized settings screen where I can view and edit all app settings,
So that app configuration is discoverable, simple, and never requires digging through sub-menus.

**Acceptance Criteria:**

**Given** Laurus navigates to `/settings` (`SettingsScreen`)
**When** the screen renders
**Then** the screen displays organized sections: "Backup" (export backup, import backup buttons — FR37, FR38), "Display" (density preference toggle — synced with daily view toggle), "Event Types" (link to event type editor from Epic 3)
**And** all settings changes take immediate effect — no "Save" button required for toggle-type settings
**And** the Backup section includes passphrase copy: "Your passphrase encrypts your backup. It is never stored. If you lose it, your backup cannot be recovered."
**And** a "Reset backup settings" option clears any stored PBKDF2 salt from `shared_preferences` — with a clear warning and confirmation dialog (FR40 — adapted for local backup)
**And** WebDAV sync configuration (a "Sync & Backup" sub-screen at `/settings/sync`) is a **Phase 2 placeholder** — shown as a greyed-out "Coming in Phase 2" entry in the settings screen
**And** the settings screen meets all accessibility requirements: 48×48dp tap targets, WCAG AA contrast, TalkBack navigation (NFR15, NFR16, NFR17)

### Story 7.2: Offline-First Verification & Graceful Degradation

As Laurus,
I want the app to be fully functional without any network connection — with sync cleanly disabled and no errors shown,
So that I can use Spetaka on a plane, in a tunnel, or anywhere without degraded experience.

**Acceptance Criteria:**

**Given** Laurus is using the app with no network connection (airplane mode)
**When** any feature is used (daily view, friend card, acquittement, event management)
**Then** all features function identically to online mode — SQLite is the single source of truth, no feature requires network (FR41, NFR11)
**And** if sync is enabled but network is unavailable, sync is silently skipped — no error banner, no loading spinner, no indication of degradation (the user did not request a sync action)
**And** if Laurus explicitly taps "Sync now" while offline, a calm message is shown: "No network available — your data is safe on this device." — not an error state
**And** the app is tested in airplane mode end-to-end: create friend, add event, log acquittement, open daily view, navigate to settings — all work without crashes
**And** `flutter test test/widgets/daily_view_test.dart` includes: offline scenario — Riverpod providers load from SQLite, no network calls attempted

### Story 7.3: Full Accessibility Audit & Compliance

As Laurus (and all users),
I want all core flows to meet Android accessibility standards and be navigable with TalkBack,
So that Spetaka is usable by anyone, and the app passes Play Store accessibility review.

**Acceptance Criteria:**

**Given** the complete app with all epic features implemented
**When** the TalkBack accessibility audit is performed on core flows
**Then** every interactive element in: daily view, friend card, acquittement sheet, friend form, settings screen — has a meaningful content description readable by TalkBack (NFR17)
**And** all interactive elements have a minimum touch target of 48×48dp — verified using Flutter's accessibility tools (NFR15)
**And** all text in the app meets WCAG AA contrast ratio (4.5:1 for normal text) — verified against `app_tokens.dart` color palette (NFR16)
**And** no interactive elements are reachable only by long-press without an accessible alternative
**And** `flutter test test/widgets/` suite includes accessibility assertions using `tester.getSemantics()` for critical widgets: daily view tile, acquittement sheet confirm button, friend form save button
**And** a manual TalkBack walkthrough on Samsung S25 confirms the full daily ritual (open → scan → tap friend → tap action → return → acquittement) is completable without visual cues

### Story 7.4: Play Store Release Preparation

As Laurus,
I want the app packaged, signed, and submitted to the Play Store internal track — ready for 4 weeks of personal validation before public release,
So that the distribution pipeline is in place and Spetaka reaches his close circle after the personal validation gate.

**Acceptance Criteria:**

**Given** all Epics 1–7 features are tested and the 4-week personal validation gate is passed
**When** the Play Store release is prepared
**Then** `pubspec.yaml` has a correct `version: 1.0.0+1` and the build number is auto-incremented by CI
**And** Play App Signing is configured — a local keystore is generated, the upload key is provided to Google Play Console, and `android/key.properties` is gitignored
**And** a Privacy Policy is hosted publicly and linked in the Play Console data safety form — disclosing `READ_CONTACTS` usage (read locally, not shared) and confirming zero third-party data transmission
**And** the Play Store data safety form is completed: contacts data read but not shared externally; no data transmitted to third parties; **Phase 1: no network data transmission at all** (WebDAV is Phase 2)
**And** the APK passes `flutter analyze --fatal-infos` and `flutter test` with zero failures
**And** the app is submitted to the Internal testing track and confirmed installable on Samsung S25 before any wider release
**And** the release track progression plan is documented: Internal → Closed testing (Laurus's circle) → Production (after 4-week gate + zero data-loss validation)

---

## UX Backlog — Filtering & Discovery _(superseded by Phase 2 — Epics 8 & 9)_

> Ces stories ont été intégrées dans les Epics 8 et 9 (Phase 2 — scope défini le 2026-03-25). Les critères d'acceptation complets figurent dans les stories correspondantes ci-dessous.

### UX-2.10 — Filtrer la liste des amis par tag

En tant que Laurus,
je veux filtrer la liste des amis par un ou plusieurs tags (Family, Work, etc.),
afin de me concentrer sur un sous-groupe de mon cercle.

**Critères d'acceptation :**

- Une barre de filtres (chips horizontaux) s'affiche en haut de `FriendsListScreen` avec tous les tags disponibles (depuis `categoryTagsProvider`).
- Sélectionner un ou plusieurs chips filtre la liste en temps réel (intersection ou union, à décider).
- Aucun chip sélectionné = liste complète.
- La sélection active est persistée le temps de la session (pas en base).
- La logique de filtrage est purement Dart via un `Provider` dérivé (`filteredFriendsProvider`) — aucune requête SQL supplémentaire.

**Impact technique :**
- Nouveau `StateProvider<Set<String>> activeTagFiltersProvider`.
- Nouveau `Provider<List<Friend>> filteredFriendsProvider` dérivé de `allFriendsProvider` + `activeTagFiltersProvider`.
- `FriendsListScreen` affiche les chips et consomme `filteredFriendsProvider` à la place de `allFriendsProvider`.
- **Risque tag orphelin :** si un ami a le tag `"Friends"` et que l'utilisateur l'a renommé en `"Potes"`, le chip `"Potes"` ne matchera pas — à documenter / mitiger.

---

### UX-3.6 — Vue transversale : amis par type d'événement

En tant que Laurus,
je veux voir tous les amis qui ont un événement d'un type donné (ex : tous les anniversaires),
afin d'avoir une vue calendaire ou thématique de mon cercle.

**Critères d'acceptation :**

- Un écran (ou un filtre sur la liste des amis) permet de sélectionner un type d'événement.
- La liste affiche tous les amis ayant au moins un événement de ce type, avec la prochaine date associée.
- Les types disponibles viennent de `eventTypeProvider` (types personnalisés inclus).
- Si aucun ami n'a ce type d'événement, un état vide explicite est affiché.

**Impact technique :**
- Requiert une requête JOIN `friends ⨝ events` filtrée par `event_type_id` — soit une nouvelle méthode DAO, soit un `Provider` Dart avec filtrage en mémoire sur le stream existant.
- À évaluer : filtre intégré à `FriendsListScreen` vs nouvel écran dédié.

---

## Phase 3 Backlog — WebDAV Sync _(déféré de Phase 2, décision 2026-03-25)_

> Ces stories sont déportées à la Phase 3 (décision 2026-03-25). Le périmètre Phase 2 est défini par les Epics 8, 9 et 10. Les artifacts `6-1` à `6-4` conservent leurs critères d'acceptation.

### FR37–FR41 (deferred to Phase 3): WebDAV Sync Stories

| Story | FR | Description |
|---|---|---|
| P3-6.1 | FR37, FR38 | WebDAV Configuration UI & Connection Test |
| P3-6.2 | FR39, FR40 | WebDAV Encrypt & Upload (with atomic upload-then-rename) |
| P3-6.3 | FR40 | Automatic Background WebDAV Sync |
| P3-6.4 | FR41 | Full Restore from WebDAV After Reinstall |

**Phase 3 security requirements to address:**
- `flutter_secure_storage` for WebDAV password (Android Keystore)
- PBKDF2 salt stored in `flutter_secure_storage` (upgrade from `shared_preferences`)
- HTTPS enforced — block/warn on `http://` WebDAV URLs
- Atomic upload: write to `spetaka_backup.enc.tmp`, then MOVE to `spetaka_backup.enc`
- Brute-force protection on restore passphrase entry (exponential backoff)

---

## Epic 8: Friend List Intelligence — Filters, Search & Last Contact _(Phase 2)_

Laurus can filter his friend list by category tags, search by friend name, filter by relationship status (concern active / overdue event / no recent contact), and see the date of last contact directly on each list tile and friend card — making a growing circle fast to navigate and immediately contextual at a glance.

### Story 8.1: Filter Friend List by Category Tags

As Laurus,
I want to filter my friend list by one or more category tags (e.g., "Family", "Close friends"),
So that I can focus on a specific group of my circle without scrolling through everyone.

**Acceptance Criteria:**

**Given** Laurus is on `FriendsListScreen` with friends assigned to various category tags
**When** the screen loads
**Then** a horizontal chips bar appears below the screen header displaying all distinct category tags currently assigned across all friend records — derived from `categoryTagsProvider` (a `Provider<List<String>>` reading distinct tag values from the friends stream)
**And** all chips start in a deselected state — the list shows all friends unfiltered

**Given** Laurus taps one or more tag chips
**When** a chip is selected
**Then** the friend list narrows to show only friends who have **at least one** of the selected tags (union / OR logic)
**And** selected chips are visually highlighted using the terracotta primary color; unselected chips use the muted sand style
**And** the filter is applied in-memory via `filteredFriendsProvider` — a derived Riverpod `Provider<List<Friend>>` that combines `allFriendsProvider` + `activeTagFiltersProvider`; no additional SQL query is issued

**Given** one or more chips are selected and Laurus taps a selected chip again
**When** the chip is deselected
**Then** the selection is removed; if no chips remain selected, the full list is shown again

**Given** the filtered list
**When** zero friends match the selected tags
**Then** the same warm empty-state widget is shown: "No friends with these tags yet."

**Given** `activeTagFiltersProvider` is a `StateProvider<Set<String>>`
**Then** its state is scoped to the session only — not persisted to `shared_preferences`; on next app launch the full unfiltered list is shown
**And** no orphaned-tag risk is introduced: tag chip values come from live friend data, not a separate stored list — if a tag is renamed or deleted from all friends, it disappears from the chips bar automatically

**Given** all interactive chip elements
**Then** each chip meets 48×48dp minimum touch target (NFR15) and has a TalkBack content description: `'Filter by [tag name], [selected/not selected]'` (NFR17)

---

### Story 8.2: Search Friend List by Name

As Laurus,
I want to search my friend list by typing a name,
So that I can instantly find any friend in a large circle without scrolling.

**Acceptance Criteria:**

**Given** Laurus is on `FriendsListScreen`
**When** he taps the search icon in the app bar
**Then** an inline search text field expands within the app bar (no navigation, no new screen) — keyboard appears automatically
**And** the search icon is replaced by a clear (✕) icon while the field is active

**Given** Laurus types one or more characters into the search field
**When** any character is entered
**Then** the friend list filters in real-time to show only friends whose `name` contains the typed string (case-insensitive, leading/trailing whitespace ignored)
**And** filtering is performed in-memory in a derived `searchFilteredFriendsProvider` — no new Drift query; operates on the already-loaded `allFriendsProvider` stream
**And** tag filters (Story 8.1) and search filters compose: if tags are selected AND search is active, the result is friends matching BOTH constraints (intersection)

**Given** the search yields zero results
**Then** the warm empty state shows: "No friend named '[typed text]' in your circle."

**Given** Laurus taps the clear (✕) icon or presses the Android back button while search is active
**When** search is cleared
**Then** the search field collapses, the full (or tag-filtered) list is restored, `searchQueryProvider` resets to empty string

**Given** the search field is active
**Then** the field has `keyboardType: TextInputType.name` and TalkBack label: `'Search friends by name'` (NFR17)
**And** the search field is not persisted — cleared on navigation away from `FriendsListScreen`

---

### Story 8.3: Filter Friend List by Status

As Laurus,
I want to filter my friend list by relationship status — friends with an active concern, friends with an overdue event, or friends with no recent contact,
So that I can triage quickly and give attention to the people who need it most from within the full list.

**Acceptance Criteria:**

**Given** Laurus is on `FriendsListScreen`
**When** he taps a "Filter" icon (funnel icon, top bar)
**Then** a filter bottom sheet (`StatusFilterSheet`) opens with three toggle options:
  - **Active concern** — friends where `is_concern_active = true`
  - **Overdue event** — friends with at least one unacknowledged event past its due date or cadence interval
  - **No recent contact** — friends whose most recent acquittement `logged_at` is more than 30 days ago (configurable constant `kNoRecentContactDays = 30`)

**Given** Laurus toggles one or more status filters
**When** the sheet is dismissed (tap outside or close button)
**Then** the friend list reflects the active status filters immediately — applied in-memory via `statusFilteredFriendsProvider`
**And** status filters compose with tag filters (Story 8.1) and search (Story 8.2): all three constraints are applied as an intersection

**Given** a status filter is active
**Then** a subtle badge or indicator on the "Filter" icon signals that filters are active (e.g., filled funnel icon + count badge)

**Given** Laurus taps "Clear all filters" in the sheet
**Then** all status filters are reset; the full unfiltered list is shown

**Given** a "No recent contact" filter is active
**Then** the threshold uses the last acquittement `logged_at` date from the `acquittements` table — a Drift query `maxLoggedAtForFriend(friendId)` is used if not already available; result is joined into the friends stream at the provider level
**And** friends who have never been contacted (no acquittements) are included in "No recent contact" results

**Given** status filters
**Then** they are session-only (not persisted); each chip/toggle meets 48×48dp (NFR15)

---

### Story 8.4: "Last Contact" Display on Card and List Tile

As Laurus,
I want to see when I last reached out to each friend directly on the list tile and on their card,
So that I have instant context about the recency of each relationship without needing to open the contact history.

**Acceptance Criteria:**

**Given** a friend has at least one logged acquittement
**When** `FriendCardTile` renders in `FriendsListScreen`
**Then** the tile displays a "Last contact" line below the friend's name in the secondary text style: e.g., `"Last contact: 3 weeks ago"` — using a human-readable relative format via `intl` `DateFormat` (`"3 days ago"`, `"2 weeks ago"`, `"3 months ago"`)
**And** the date is the `MAX(logged_at)` from `acquittements` WHERE `friend_id = X` — derived from an extended friend stream that joins the latest acquittement per friend

**Given** a friend has no acquittements
**When** `FriendCardTile` renders
**Then** the tile shows no "Last contact" line — the field is absent rather than showing "Never" (avoid guilt framing per UX principles)

**Given** Laurus opens `FriendCardScreen`
**When** the screen loads
**Then** the "Last contact" date is displayed below the friend's name / action buttons in the same relative format
**And** it updates reactively when a new acquittement is logged (e.g., immediately after closing the `AcquittementSheet`)

**Given** the `allFriendsProvider` stream
**Then** it is extended (or a new `friendsWithLastContactProvider` is created) to include the `lastContactAt` value per friend — computed via a Drift `watchAllWithLastContact()` query using a LEFT JOIN or subquery on `acquittements`; this is the only SQL change required for this story

**Given** the "Last contact" text
**Then** it uses the `color.text.secondary` (`#8C7B70` warm greige) token — never primary ink; never alarming; meets WCAG AA contrast (NFR16)
**And** TalkBack reads it as part of the tile's combined content description: `'[name], last contact [relative date]'` (NFR17)

---

## Epic 9: Smart Concern Cadence _(Phase 2)_

When Laurus marks a friend as going through something difficult, Spetaka automatically creates a check-in cadence so that friend stays actively top-of-mind with no manual follow-up setup required. The default cadence interval is user-configurable in settings. The cadence is automatically removed when the concern is cleared.

### Story 9.1: Auto-Create Concern Follow-Up Cadence on Flag Activation

As Laurus,
I want Spetaka to automatically create a recurring check-in cadence when I set a concern flag on a friend,
So that a friend going through a difficult time is automatically surfaced in my daily view without me needing to manually add a cadence.

**Acceptance Criteria:**

**Given** Laurus sets a concern flag on a friend (via `FriendCardScreen` "Set concern" flow from Story 2.9)
**When** `FriendRepository.setConcern(friendId, concernNote)` is called
**Then** `FriendRepository` automatically creates a new `Event` record for that friend with: `type = 'Regular check-in'`, `is_recurring = true`, `cadence_days` = the value from `ConcernCadenceSettingsProvider` (default: 7), `is_acknowledged = false`, and a `comment` of `'Auto-created — concern follow-up'`
**And** the event creation and the concern flag update are performed atomically in a single Drift transaction — either both succeed or neither does
**And** the new cadence event becomes immediately visible in the events list on `FriendCardScreen` labeled: `"Regular check-in — every 7 days (concern follow-up)"`
**And** the cadence event appears in the priority engine's surface window on the next daily view load, subject to the standard overdue/window logic

**Given** Laurus clears the concern flag on a friend (via `FriendCardScreen` "Clear concern" flow from Story 2.9)
**When** `FriendRepository.clearConcern(friendId)` is called
**Then** the automatically-created cadence event (identified by its `comment = 'Auto-created — concern follow-up'` marker) is deleted from the `events` table in the same atomic transaction as the concern flag clear
**And** only the auto-created concern cadence is deleted — any other manually-added cadences on the friend are untouched
**And** if no auto-created concern cadence exists for this friend (e.g., it was manually deleted earlier), the clear operation succeeds without error

**Given** a friend already has an auto-created concern cadence and Laurus sets the concern flag again (re-activate after clearing)
**When** `setConcern` is called
**Then** a new cadence event is created with the current `ConcernCadenceSettingsProvider` interval — no duplicate detection needed (previous cadence was already deleted on clear)

**Given** the concern cadence auto-creation
**Then** it reads the interval from `ConcernCadenceSettingsProvider` (Story 9.2), not a hardcoded value — the default is 7 if no user setting has been saved

**Given** `flutter test test/repositories/friend_repository_test.dart`
**Then** tests pass including: set concern → verify auto-cadence event created with `cadence_days = 7`; clear concern → verify auto-cadence event deleted and other events untouched; set concern with custom settings interval of 14 → verify `cadence_days = 14`

---

### Story 9.2: Configurable Concern Cadence Interval in Settings

As Laurus,
I want to configure the default interval for the automatic concern follow-up cadence from the Settings screen,
So that the cadence matches how frequently I want to check in on friends going through difficult times.

**Acceptance Criteria:**

**Given** Laurus navigates to `SettingsScreen`
**When** the screen loads
**Then** a "Concern follow-up cadence" section is displayed with a label showing the current default interval (e.g., "Every 7 days — default")
**And** tapping the setting opens a selector (bottom sheet or inline dropdown) with options: Every 3 days, Every 5 days, Every 7 days (default), Every 10 days, Every 14 days, Every 21 days, Every 30 days — presented as human-readable labels

**Given** Laurus selects an interval
**When** the selector is dismissed
**Then** the new interval is immediately saved to `shared_preferences` under the key `'concern_cadence_days'` as an integer
**And** `ConcernCadenceSettingsProvider` — a Riverpod `StreamProvider<int>` reading from `shared_preferences` — emits the new value; all downstream consumers react immediately
**And** the settings screen label updates to reflect the selected interval

**Given** the setting is changed
**Then** existing auto-created concern cadences already in the `events` table are **not** retroactively updated — the new interval applies only to concern flags set after the change
**And** this behaviour is clearly noted in the UI: `"Applies to new concern flags — existing cadences are not changed."`

**Given** no value has been saved to `shared_preferences`
**Then** `ConcernCadenceSettingsProvider` defaults to `7` — no null handling required by consumers; always returns a valid integer

**Given** the selector
**Then** all options meet 48×48dp touch targets (NFR15); TalkBack reads: `'Concern cadence: Every [N] days, [selected/not selected]'` (NFR17)

---

## Epic 10: On-Device LLM & Message Assistance _(Phase 2)_

Laurus can tap "Suggest message" on any event in a friend card and receive ≥ 3 warm, contextualised WhatsApp or SMS message variants generated entirely on his device — no network connection, no API key, no passphrase required. He can edit, copy, and send directly via `ContactActionService`. The daily greeting line is enriched by the LLM when a model is available, with a static fallback ensuring zero degraded UX. The friend card form auto-saves draft state in memory during the session, recovered transparently on return.

> **Backlog — Story 10.5 & 10.6 (added 2026-03-30, from brainstorming-session-2026-03-30):**
> **Story 10.5** (ready-for-dev) : Enriched prompt + context header + "✦ Message" Daily View button (P2-A + P2-B + P2-C)
> **Story 10.6** (backlog, after 10.5) : UserVoiceProfile — on-device learning of style vectors (P2-D + P2-E)
>
> _Note: HuggingFace token story remains tracked in `sprint-status.yaml` > `p2-llm-hf-token-user-provided-secure-storage` (phase-2-brainstorm-backlog)._

### Story 10.1: LLM Capability Check, Model Download Gate & Infrastructure

As a developer,
I want the `lib/core/ai/` module fully in place — capability checking, model state machine, and `LlmInferenceService` — so that all LLM-dependent features (10.2, 10.3) can be built on a tested, isolated foundation.

**Acceptance Criteria:**

**Given** `flutter_gemma: ^1.x.x` is added to `pubspec.yaml` dependencies
**When** the app is built
**Then** `flutter analyze` and `flutter test` pass cleanly; no new permissions beyond `INTERNET` (already added for WebDAV) are introduced

**Given** the AI module is implemented
**Then** `lib/core/ai/` contains: `ai_capability_checker.dart`, `model_manager.dart`, `llm_inference_service.dart`, `prompt_templates.dart`, `greeting_service.dart` — each as a distinct file

**Given** `AiCapabilityChecker.isSupported()` is called at runtime
**Then** it returns `true` only if Android API level ≥ 29 AND available RAM ≥ 4 GB; returns `false` otherwise
**And** the result is exposed via `@riverpod AiCapabilityChecker aiCapabilityChecker(...)` and cached for the session — not re-checked on every build

**Given** hardware is unsupported (`isSupported() = false`)
**Then** all LLM feature entry points (`"Suggest message"` button on events, LLM greeting) are **hidden entirely** — not greyed out, not disabled with a tooltip; the UI is identical to a non-LLM build for this device
**And** no `ModelDownloadScreen` is ever shown on an unsupported device

**Given** hardware is supported AND `ModelManager.isModelReady = false`
**When** Laurus taps any LLM feature entry point
**Then** he is navigated to `ModelDownloadScreen` (route: `/model-download`) before any LLM UI is shown
**And** `ModelDownloadScreen` displays: required storage (`~2 GB`), a "Download model" button, a linear progress indicator during download, a "Cancel" button, and an error state with retry option on network failure
**And** `ModelManager` exposes `Stream<ModelDownloadState>` with states: `idle / downloading(progress: double) / ready / error(message: String)`
**And** downloaded model is stored at `{appDocumentsDir}/spetaka_llm/gemma3n_e2b_it_int4.bin` — inaccessible to other apps

**Given** hardware is supported AND model is ready (`ModelManager.isModelReady = true`)
**Then** LLM feature entry points are visible and active; `ModelDownloadScreen` is never shown

**Given** `LlmInferenceService.infer(String prompt)`
**Then** inference executes in a `Dart Isolate` via `Isolate.run()` — the UI thread is never blocked
**And** a 30-second timeout is enforced: on timeout, the method returns an empty `List<String>` — callers handle empty list gracefully (fallback to static content or user-visible message)
**And** `LlmInferenceService` is a singleton exposed via Riverpod; multiple concurrent inference calls are queued, not parallelised

**Given** `flutter test test/unit/ai/`
**Then** unit tests pass: `AiCapabilityChecker` returns correct values for mocked API level/RAM combinations; `ModelManager` transitions through states correctly given mocked download events; `LlmInferenceService` returns empty list on timeout without throwing

---

### Story 10.2: Message Suggestion — DraftMessageSheet with ≥ 3 LLM Variants

As Laurus,
I want to tap "Suggest message" on an event in a friend card and receive ≥ 3 warm, contextualised WhatsApp or SMS message variants — generated on my device — so that I can pick, edit, and send the right message in seconds without composing from scratch.

**Acceptance Criteria:**

**Given** `ModelManager.isModelReady = true` and Laurus is on `FriendCardScreen` viewing an event
**When** he taps "Suggest message" on any event
**Then** `DraftMessageSheet` opens as a bottom sheet in `AsyncLoading` state — a subtle loading indicator is shown (no spinner filling the full sheet; a small terracotta progress bar at the top suffices)
**And** `DraftMessageNotifier.requestSuggestions(friendId: ..., event: ..., channel: 'whatsapp')` is called immediately

**Given** `LlmMessageRepository.generateSuggestions(...)` runs
**Then** it reads friend `name` from `FriendRepository` (read-only, decrypted)
**And** builds a prompt using `PromptTemplates.messageSuggestion(friendName: ..., eventType: ..., eventContext: ..., channel: ...)` — the prompt is a constant template in `prompt_templates.dart`, never constructed ad-hoc in the repository
**And** calls `LlmInferenceService.infer(prompt)` in an Isolate
**And** parses the numbered-list response (`1. ... 2. ... 3. ...`) into a `List<String>` of ≥ 3 trimmed variants; if fewer than 3 are parsed, the sheet shows what was returned (minimum 1) plus a "Generate more" button

**Given** inference completes successfully
**When** `DraftMessageSheet` transitions to `AsyncData` state
**Then** the sheet displays:
  - An event context header (e.g., `"For Sophie — Birthday in 3 days"`)
  - Exactly 3 (or more) selectable variant cards — tapping one highlights it in the terracotta primary style
  - An editable text field pre-filled with the selected variant; Laurus can freely edit
  - A channel selector (WhatsApp / SMS) — defaults to WhatsApp if the friend has a valid number
  - A `"Copy & Send via [channel]"` button (terracotta, full-width)
  - A `"Discard"` text button

**Given** Laurus taps `"Copy & Send via WhatsApp"`
**Then** the selected / edited text is copied to the system clipboard
**And** `ContactActionService.whatsapp(friend.mobile)` fires the WhatsApp intent (existing behaviour)
**And** `DraftMessageNotifier.clear()` is called — the draft is discarded from in-memory state
**And** `AppLifecycleService` records the pending acquittement as it would for any WhatsApp action (standard flow — acquittement sheet will appear on return)

**Given** Laurus taps `"Discard"` or dismisses the sheet
**Then** `DraftMessageNotifier.clear()` is called — no data is written to SQLite; the draft evaporates

**Given** inference returns an empty list (timeout or parse failure)
**Then** `DraftMessageSheet` shows an error state: `"Couldn't generate suggestions right now. You can write your own message below."` with an empty editable field and the same `"Copy & Send"` button — Laurus can still compose manually

**Given** `DraftMessage` domain model
**Then** it is a pure in-memory Dart class — **never persisted to SQLite**; no Drift table or schema migration is introduced by this story

**Given** all interactive elements in `DraftMessageSheet`
**Then** they meet 48×48dp touch targets (NFR15) and TalkBack labels (NFR17): variant cards labelled `'Message option [N]: [first 20 chars]...'`; confirm button labelled `'Copy and send via [channel]'`

---

### Story 10.3: LLM-Enriched Daily Greeting Line

As Laurus,
I want the daily view greeting line to be dynamically generated by the on-device LLM when the model is available — reflecting my actual relationship state at that moment,
So that opening Spetaka feels genuinely personal rather than cycling through a static rotation.

**Acceptance Criteria:**

**Given** `DailyViewScreen` loads (or re-enters foreground)
**When** the `GreetingLineWidget` renders
**Then** it immediately displays a static fallback greeting from a hardcoded pool in `GreetingService.staticFallback(context)` — no loading spinner, no blank space, no delay; the UI is immediately complete

**Given** `ModelManager.isModelReady = true`
**When** the static greeting is shown
**Then** `GreetingService.generateAsync()` is called in the background (non-blocking, no `await` on the render path):
  - Context passed to the prompt: urgent friend count, concern flag count, approximate care score average
  - Prompt template from `PromptTemplates.greetingLine(urgentCount, concernCount, userName)` — a constant in `prompt_templates.dart`
  - Calls `LlmInferenceService.infer(prompt)` in an Isolate (30s timeout)
  - On response: `greetingLineProvider` state is updated with the LLM result
  - `GreetingLineWidget` reacts via Riverpod and smoothly cross-fades (300ms `easeInOutCubic`) from the static greeting to the LLM greeting

**Given** `ModelManager.isModelReady = false` OR the Isolate times out
**Then** the static greeting remains — no update, no error shown; the experience is identical to the pre-LLM version
**And** the static pool contains at minimum 8 greeting variants covering: 0 urgent, 1 urgent, 2+ urgent, concern-flagged friend present — all in coach tone, never metric-framed

**Given** `greetingLineProvider`
**Then** it is a `@riverpod class GreetingLineNotifier` returning `String` (never null/async from the widget's perspective — always has a valid value); the static fallback is the initial value set in `build()`

**Given** the cross-fade animation between static and LLM greetings
**Then** it runs at 60fps on Samsung S25 using `AnimatedSwitcher` with `FadeTransition` child — no `AnimatedContainer` resize (greeting line height stays constant)
**And** TalkBack reads the most recent greeting text; transition does not cause focus jump (NFR17)

---

### Story 10.4: Session-Draft Auto-Save for Friend Form

As Laurus,
I want the friend form to automatically save my in-progress edits in memory during the session — and restore them transparently if I navigate away and return,
So that I never lose a partially-filled friend card due to an accidental back gesture or app switch.

**Acceptance Criteria:**

**Given** Laurus opens `FriendFormScreen` (new friend creation or editing an existing friend)
**When** the screen initialises
**Then** `FriendFormDraftNotifier` state is checked via `ref.read(friendFormDraftProvider)`:
  - If `null` → blank form (or edit form pre-filled from the existing friend record as normal)
  - If non-null → form fields are pre-filled from the draft AND a dismissible "Resuming your draft" banner appears at the top of the form (`InfoBannerWidget`, sage color, `"Resuming your draft — [Discard]"`)

**Given** Laurus types in any field on the form
**When** a field value changes (via `onChanged` callback)
**Then** a 300ms debounced `Timer` fires and calls `FriendFormDraftNotifier.update(FriendFormDraft(...currentFormState...))`
**And** the debounce is implemented inline in `FriendFormScreen` using Flutter's `Timer` — no shared `Debouncer` utility class is created (single use case)

**Given** Laurus taps "Save" with a valid form
**When** `FriendRepository.save(friend)` or `FriendRepository.update(friend)` completes successfully
**Then** `FriendFormDraftNotifier.clear()` is called immediately after save — the draft is discarded

**Given** Laurus taps "Discard" or explicitly dismisses the "Resuming your draft" banner's Discard action
**Then** `FriendFormDraftNotifier.clear()` is called; the form resets to empty (new) or the current persisted values (edit)

**Given** Laurus switches apps or Spetaka is backgrounded while the form is open
**When** Laurus returns to Spetaka with the form still in the navigation stack
**Then** the form fields still show the in-progress values — Riverpod state survives `AppLifecycleState.paused`/`resumed` as long as the process is alive; `AppLifecycleService` does not emit a draft-clearing event

**Given** Android kills the Spetaka process (memory pressure or device restart) while the form has unsaved content
**Then** `FriendFormDraftNotifier` state is lost — this is intentional per architecture addendum decision Q5; no data is ever written to SQLite for session drafts; on next open the form is blank (new) or the last persisted state (edit)

**Given** `FriendFormDraft` domain class
**Then** it lives in `lib/features/friends/domain/friend_form_draft.dart` with nullable fields: `name`, `mobile`, `notes`, `List<String> categoryTags`, `bool isConcernActive`, `concernNote`
**And** `FriendFormDraftNotifier` lives in `lib/features/friends/providers/friend_form_draft_provider.dart` — a `@riverpod class` extending `_$FriendFormDraftNotifier`, returning `FriendFormDraft?`
**And** no Drift table is created; no `schemaVersion` is incremented by this story

**Given** `flutter test test/widgets/friend_form_test.dart`
**Then** tests pass: open form → type name → navigate away → navigate back → draft banner shown → name field pre-filled; save success → draft cleared; discard banner → form reset

---

### Story 10.5: Enriched Prompt + Context Visible + "✦ Message" Button in Daily View _(Phase 2, added 2026-03-30)_

As Laurus,
I want the LLM message suggestions to leverage the event comment as a tonal modifier, to see the full event context while I choose a variant, and to launch the suggestion from the Daily View action row directly,
so that each suggestion feels tuned to the real emotional weight of the moment, and I can reach it without navigating away from my daily list.

**Source:** Brainstorming session 2026-03-30 — P2-A (prompt dynamique), P2-B (contexte visible), P2-C (bouton Daily View).

**Acceptance Criteria:**

**Given** `PromptTemplates.messageSuggestion()` is called with `eventNote` non-null and non-empty
**When** the prompt is constructed
**Then** the prompt includes `"Contexte important : [eventNote]. Adapte le ton de tes messages en conséquence."` — the comment acts as a tonal modifier (not just concatenation)
**And** fallback: if `eventNote` is absent → behavior unchanged from Story 10.2

**Given** Laurus opens `DraftMessageSheet` for an event with a comment
**When** the sheet is in data or error state
**Then** the event context header shows a second line: `"✎ [commentaire]"` (bodySmall, italic, onSurfaceVariant, truncated at 80 chars)
**And** if no comment → single-line header unchanged

**Given** the LLM is supported and the model is ready AND `entry.nearestEvent != null`
**Given** Laurus is on DailyViewScreen, a card is expanded
**When** the action row renders
**Then** a 4th button appears: icon `Icons.auto_awesome_outlined`, label `"✦ Message"` (French: `context.l10n.suggestMessageDailyAction`)
**And** tapping it calls `showDraftMessageSheet(context, ref, friendId, nearestEvent)` — zero additional navigation

**Given** LLM unsupported OR model not ready OR no nearest event
**Then** the 4th button is hidden — action row shows 3 buttons unchanged

**Given** `DailyViewEntry`
**Then** it gains an optional `Event? nearestEvent` field populated by `buildDailyView` (no breaking change)

**Given** this story
**Then** zero new Drift tables, zero `schemaVersion` increment

---

### Story 10.6: UserVoiceProfile — On-Device Implicit Style Learning _(Phase 2, planned)_

As Laurus,
I want the app to learn my writing style implicitly — tone level, preferred length, recurring keywords — so that the 3 LLM variants match my voice rather than generic ChatGPT output.

**Source:** Brainstorming session 2026-03-30 — P2-D + P2-E. Depends on Story 10.5 being done.

**Planned scope:** `UserVoiceProfile` (Dart class, SQLite persisted) storing formality (0–10), preferred length (word count avg), frequent keywords. Fed automatically on each "Copy & Send" from `DraftMessageSheet` by observing the delta between selected variant and sent text. Injected into prompt as style constraints. Included in the encrypted local backup (Story 6.5 payload).

_Full acceptance criteria to be defined when Story 10.5 is done._

