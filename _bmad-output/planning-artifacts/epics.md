---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/architecture.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
---

# Spetaka - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Spetaka, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

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
FR11: User can add an event to a friend card with a date, type, and optional free-text comment
FR12: User can add a recurring check-in cadence to a friend card with a configurable interval
FR13: User can edit or delete any event on a friend card
FR14: User can view the list of event types and edit it (add, rename, delete, reorder)
FR15: System provides 5 default event types at first launch: birthday, wedding anniversary, important life event, regular check-in, important appointment
FR16: User can manually mark an event as acknowledged (acquitted) from the friend card
FR17: User can open a daily view showing friends who need attention today
FR18: System surfaces overdue unacknowledged events, today's events, and events within the next 3 days in the daily view
FR19: System orders the daily view by a dynamic priority score weighted by: event type importance, days overdue, friend category, active concern flag (×2), and low care score
FR20: System displays a heart briefing at the top of the daily view: 2 urgent entries and 2 important entries
FR21: User can tap any entry in the daily view to open the corresponding friend card
FR22: User can initiate a phone call to a friend with one tap from their card
FR23: User can initiate an SMS to a friend with one tap from their card
FR24: User can open a WhatsApp conversation with a friend with one tap from their card
FR25: System detects when the user returns to the app after a communication action and presents the friend's card pre-focused for acquittement and note-taking
FR26: User can log an acquittement on a friend card specifying the action type (call, SMS, WhatsApp message, voice message, seen in person)
FR27: User can add a free-text note to an acquittement describing what was discussed or any relevant context
FR28: System pre-fills the acquittement prompt with the detected action type and current timestamp when triggered by post-action return
FR29: User can confirm the pre-filled acquittement in one tap
FR30: System maintains a chronological contact history log per friend card (acquittements with type, date, note)
FR31: System updates the friend's care score after each acquittement is logged
FR32: User can configure a WebDAV server connection (URL, username, password, encryption passphrase)
FR33: User can test the WebDAV connection before enabling sync
FR34: System encrypts all data with the user's passphrase before transmitting to WebDAV
FR35: System syncs data to WebDAV automatically when network is available and sync is configured
FR36: User can restore all data from WebDAV after reinstall by re-entering their passphrase
FR37: User can export all data to an encrypted local file as a standalone backup
FR38: User can import and restore data from a previously exported encrypted file
FR39: User can view and edit all app settings from a dedicated settings screen
FR40: User can update or reset their WebDAV sync configuration including passphrase
FR41: System operates with full functionality when no network connection is available

### NonFunctional Requirements

NFR1: The daily view loads and renders its full content within 1 second on the primary target device (Samsung S25)
NFR2: Priority score recomputation completes within 500ms — the daily view never shows a loading state for ranking
NFR3: Tapping a 1-tap action button (Call, SMS, WhatsApp) launches the target app within 500ms
NFR4: Friend card opens within 300ms of tap from any screen
NFR5: WebDAV sync runs as a background operation with no perceptible UI impact
NFR6: All on-device data is encrypted at rest using AES-256 with a key derived from the user's passphrase (PBKDF2 or Argon2)
NFR7: All data transmitted to WebDAV is encrypted client-side before leaving the device — the server never receives plaintext
NFR8: The user's passphrase is never stored, transmitted, or logged — only the in-memory derived key is used during an active session
NFR9: The app requests only READ_CONTACTS and INTERNET permissions, each requested at first point of use, not at install
NFR10: No analytics, telemetry, crash reporting, or advertising SDKs are included — zero data transmitted to any third-party service
NFR11: The local SQLite database is the single source of truth — no data loss after any unexpected app termination or device restart
NFR12: WebDAV sync failures must not corrupt or partially overwrite local data — all sync operations are atomic or safely resumable
NFR13: A full restore from WebDAV reproduces all friend cards, events, acquittements, and settings without data loss
NFR14: The exported backup file is a complete, self-contained snapshot restorable to any device
NFR15: All interactive elements meet the minimum touch target size of 48×48dp (Android Material Design baseline)
NFR16: Text content meets WCAG AA contrast ratio (4.5:1 minimum for normal text)
NFR17: Core flows (daily view, friend card, acquittement) are navigable with Android TalkBack screen reader

### Additional Requirements

**From Architecture — Technical Setup (impacts Epic 1 Story 1):**
- STARTER TEMPLATE: `flutter create --org dev.spetaka --platforms android spetaka` — project initialization is the first implementation story
- Feature-first clean architecture: `lib/core/`, `lib/features/`, `lib/shared/` directory structure as defined in architecture document
- State management: Riverpod v3.2.1 with `@riverpod` code generation — manual providers forbidden
- Local persistence: Drift v2.31.0 — single `AppDatabase`, reactive stream-based queries
- Navigation: GoRouter v14.6.3 with declarative typed route tree
- Encryption library: `encrypt ^5.0.3` — AES-256-GCM mode; PBKDF2 (100,000 iterations, SHA-256) via `dart:crypto` for key derivation
- WebDAV client: `webdav_client ^3.0.1` behind `SyncRepository` abstraction interface
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

### FR Coverage Map

FR1: Epic 2 - Import fiche depuis contacts téléphoniques
FR2: Epic 2 - Création manuelle fiche (nom + mobile)
FR3: Epic 2 - Assignation de tags de catégorie
FR4: Epic 2 - Notes libres contextuelles sur la fiche
FR5: Epic 2 - Liste de toutes les fiches
FR6: Epic 2 - Ouverture fiche complète avec détails + historique
FR7: Epic 2 - Édition de tout champ d'une fiche
FR8: Epic 2 - Suppression de fiche
FR9: Epic 2 - Flag préoccupation active avec note descriptive
FR10: Epic 2 - Effacement du flag préoccupation
FR11: Epic 3 - Ajout événement avec date, type, commentaire optionnel
FR12: Epic 3 - Cadence récurrente avec intervalle configurable
FR13: Epic 3 - Édition ou suppression d'événement
FR14: Epic 3 - Édition de la liste des types d'événements (ajout, renommage, suppression, réordre)
FR15: Epic 3 - 5 types d'événements par défaut au premier lancement
FR16: Epic 3 - Acquittement manuel d'un événement depuis la fiche
FR17: Epic 4 - Vue quotidienne — amis qui nécessitent attention aujourd'hui
FR18: Epic 4 - Surface overdue + aujourd'hui + +3 jours dans la vue quotidienne
FR19: Epic 4 - Score de priorité dynamique (importance type, jours overdue, catégorie, flag ×2, care score bas)
FR20: Epic 4 - Briefing cœur 2+2 (2 urgents + 2 importants) en tête de vue quotidienne
FR21: Epic 4 - Tap sur entrée vue quotidienne → ouvre la fiche ami
FR22: Epic 5 - 1-tap appel téléphonique depuis la fiche
FR23: Epic 5 - 1-tap SMS depuis la fiche
FR24: Epic 5 - 1-tap ouverture WhatsApp depuis la fiche
FR25: Epic 5 - Détection retour app post-action + présentation fiche pré-focalisée pour acquittement
FR26: Epic 5 - Acquittement avec type d'action (call, SMS, WhatsApp, voice, seen in person)
FR27: Epic 5 - Note libre descriptive sur l'acquittement
FR28: Epic 5 - Pré-remplissage type d'action + horodatage au retour app
FR29: Epic 5 - Confirmation acquittement pré-rempli en 1 tap
FR30: Epic 5 - Log chronologique d'historique de contacts par fiche
FR31: Epic 5 - Mise à jour du care score après chaque acquittement
FR32: Epic 6 - Configuration connexion WebDAV (URL, user, password, passphrase)
FR33: Epic 6 - Test de connexion WebDAV avant activation sync
FR34: Epic 6 - Chiffrement client-side AES-256 avant transmission WebDAV
FR35: Epic 6 - Sync automatique WebDAV dès réseau disponible
FR36: Epic 6 - Restore complet depuis WebDAV après réinstallation
FR37: Epic 6 - Export données vers fichier local chiffré
FR38: Epic 6 - Import et restore depuis fichier local chiffré
FR39: Epic 7 - Écran paramètres complet éditable
FR40: Epic 7 - Mise à jour ou reset de la configuration WebDAV + passphrase
FR41: Epic 7 - Fonctionnement complet sans connexion réseau

## Epic List

### Epic 1: Project Foundation & Core Infrastructure
Laurus (and any developer) can initialize the full Spetaka project scaffold with all cross-cutting infrastructure in place — Drift database, AES-256 encryption service, sensitive field encryption at the repository layer (NFR6), AppLifecycle detection, phone number normalization, GoRouter navigation, dark-mode-aware design token system, and GitHub Actions CI/CD — creating a solid, architecture-compliant foundation that unblocks all feature epics.
**FRs covered:** None (technical foundation — unblocks FR1–FR41)
**Additional requirements:** flutter create scaffold, Drift AppDatabase + DAOs skeleton, EncryptionService (AES-256-GCM + PBKDF2), sensitive field encryption at repository layer (NFR6 — Story 1.7), AppLifecycleService, PhoneNormalizer, ContactActionService skeleton, GoRouter route tree, app_tokens.dart + AppTheme (light + warm dark mode), GitHub Actions CI/CD (analyze → test → build APK)

### Epic 2: Friend Cards & Circle Management
Laurus can build and manage his full relational circle — create friend cards by importing from phone contacts or manually, assign category tags, add contextual notes, set concern/préoccupation flags, and browse his complete list — giving the app its core data model and making every subsequent feature meaningful.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR10

### Epic 3: Events & Cadences
Laurus can define what matters for each friend — birthdays, anniversaries, important life events, regular check-ins — and set recurring cadence intervals. The event type list is fully personalized. Events are the raw material the priority engine consumes to surface the right people at the right moment.
**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR16

### Epic 4: Daily View & Priority Engine
Laurus has a warm, intelligent daily view that tells him exactly who deserves his care today — powered by a dynamic priority score, the 2+2 heart briefing, a coach-tone greeting line, density control, and a virtual friend "Sophie" on first launch. This is the heart of the Spetaka ritual.
**FRs covered:** FR17, FR18, FR19, FR20, FR21

### Epic 5: Actions & Acquittement — The Care Loop
Laurus can contact any friend in one tap and close the care loop with a warm, frictionless acquittement. The complete gesture — from intention to action to logged contact — happens in seconds. This epic delivers the defining Spetaka experience.
**FRs covered:** FR22, FR23, FR24, FR25, FR26, FR27, FR28, FR29, FR30, FR31

### Epic 6: Sync, Backup & Privacy
Laurus can protect and restore all his relational data with end-to-end AES-256 encryption on his own WebDAV server — no plaintext ever leaves the device. A local encrypted file export/import provides a complete fallback. His data is his, always.
**FRs covered:** FR32, FR33, FR34, FR35, FR36, FR37, FR38

### Epic 7: Settings, Offline Resilience & Play Store Release
Laurus has a complete, accessible settings screen, a fully verified offline-first experience, and a Play Store release track ready for 4 weeks of personal validation — then public distribution. Accessibility audit (NFR15–17) and zero-notification architecture verification complete the release readiness checklist.
**FRs covered:** FR39, FR40, FR41

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
**And** `lib/core/router/app_router.dart` defines the complete typed route tree: `/` → `DailyViewScreen`, `/friends` → `FriendsListScreen`, `/friends/new` → `FriendFormScreen`, `/friends/:id` → `FriendCardScreen`, `/settings` → `SettingsScreen`, `/settings/sync` → `WebDavSetupScreen` — each screen is a placeholder widget with a title `Text` for now
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
**And** `friends.name`, `friends.mobile`, `friends.tags`, and all non-narrative fields are stored as plaintext — these are required for search, sorting, and phone number operations
**And** encryption and decryption logic is centralized in `FriendRepository` and `AcquittementRepository` — Drift DAO classes are NOT encryption-aware; they receive and return raw stored values
**And** if decryption fails for any field (e.g., session key not yet initialized), a typed `AppError.sessionExpired` is thrown — the app prompts the user to re-enter their passphrase
**And** `flutter test test/repositories/field_encryption_test.dart` passes:
  - Write `FriendRecord` with non-empty `notes` → read back → `notes` equals original plaintext
  - Inspect raw Drift DAO value for the same record → confirms the stored value is NOT the plaintext (it is ciphertext)
  - Write `AcquittementRecord` with a `note` → read back → `note` equals original plaintext
  - Attempt read without initialized `EncryptionService` key → returns `AppError.sessionExpired`

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

## Epic 6: Sync, Backup & Privacy

Laurus can protect and restore all his relational data with end-to-end AES-256 encryption on his own WebDAV server. No plaintext ever leaves the device. A local encrypted file export/import provides a complete fallback.

### Story 6.1: WebDAV Configuration UI & Connection Test

As Laurus,
I want to configure my WebDAV server connection and test it before enabling sync,
So that I know my server is reachable and my credentials are correct before trusting it with my data.

**Acceptance Criteria:**

**Given** Laurus navigates to `/settings/sync` (`WebDavSetupScreen`)
**When** the screen renders
**Then** the form displays: server URL, username, password (masked), encryption passphrase (masked) — all using `shared_preferences` for persistence of URL/username/password (never passphrase)
**And** a "Test connection" button sends a `PROPFIND` request to the WebDAV root via `webdav_client ^3.0.1` using the entered credentials
**And** on success: "Connection successful ✓" is shown and a "Enable sync" toggle becomes active
**And** on failure: a specific error message from `error_messages.dart` is shown — distinguishing "Connection refused / URL unreachable", "Authentication failed (401)", "Not a WebDAV server" cases
**And** the passphrase field includes clear copy: "Your passphrase encrypts everything before it leaves your device. It is never sent to the server. If you lose it, your data cannot be recovered."
**And** the passphrase is never stored or logged — only used in-session by `EncryptionService`
**And** the `INTERNET` permission is consumed here (requested at runtime point-of-use if not already granted — NFR9)

### Story 6.2: WebDAV Sync — Encrypt & Upload

As Laurus,
I want all my data to be encrypted with my passphrase and uploaded to my WebDAV server,
So that my relational data lives on my own infrastructure — encrypted end-to-end, not on any third-party server.

**Acceptance Criteria:**

**Given** Laurus has a valid WebDAV configuration and sync is enabled
**When** a sync is triggered (manually via "Sync now" button or automatically — Story 6.3)
**And** `SyncRepository` serializes all `friends`, `events`, `acquittements`, `event_types`, and app settings (WebDAV URL/username, density preference, encryption salt) to JSON (via `toJson()` on each model — ISO 8601 timestamps in JSON); demo friends (`is_demo = true`) are excluded from the payload
**And** the full JSON payload is encrypted by `EncryptionService.encrypt()` before any WebDAV call — the server never receives plaintext
**And** the encrypted payload is uploaded to the WebDAV server as a single file (e.g., `spetaka_backup.enc`) via `webdav_client`
**And** if the upload fails, local SQLite data is untouched — no partial overwrite, no data loss (NFR12)
**And** `SyncStatusProvider` updates sync state: idle / syncing / success / error — consumed by a subtle non-blocking indicator in the UI
**And** sync errors are surfaced as a dismissible banner, not a modal

### Story 6.3: Automatic Background WebDAV Sync

As Laurus,
I want sync to happen automatically in the background when network is available,
So that my data is always protected without me having to remember to sync manually.

**Acceptance Criteria:**

**Given** Laurus has sync enabled and a network connection is available
**When** the app launches or resumes from background
**Then** `SyncRepository.sync()` is triggered as a fire-and-forget background operation — never awaited by the UI (NFR5)
**And** sync does not block or delay any UI interaction — the daily view, friend cards, and acquittement sheet all function normally during sync
**And** if no network is available (`INTERNET` permission granted but no connectivity), sync is silently skipped — no error shown, no retry countdown visible
**And** if WebDAV is unavailable (server error, wrong credentials), a dismissible banner notifies Laurus — local data is intact
**And** the last successful sync timestamp is stored in `shared_preferences` and displayed in `WebDavSetupScreen`

### Story 6.4: Full Restore from WebDAV After Reinstall

As Laurus,
I want to restore all my data from WebDAV after reinstalling the app,
So that I never lose my relationship data — reinstalling is a non-event, not a catastrophe.

**Acceptance Criteria:**

**Given** Laurus has reinstalled Spetaka and navigates to `/settings/sync`
**When** he enters his WebDAV credentials and passphrase and taps "Restore from server"
**Then** `SyncRepository` downloads the encrypted backup file from WebDAV
**And** `EncryptionService.decrypt()` decrypts the payload using the entered passphrase
**And** all `friends`, `events`, `acquittements`, `event_types`, and settings are restored to SQLite and `shared_preferences` (for non-sensitive settings) from the decrypted JSON — IDs are preserved (UUID, no conflicts)
**And** if decryption fails (wrong passphrase), a clear error from `error_messages.dart` is shown: "Passphrase incorrect — unable to decrypt backup. Check your passphrase and try again." — no data is written
**And** after successful restore, the daily view reflects the restored data within one Drift stream emission
**And** the restore is complete and lossless: 100% of friends, events, acquittements, and settings reproduced (NFR13)

### Story 6.5: Encrypted Local File Export & Import

As Laurus,
I want to export all my data to an encrypted file saved on my device, and import it back if needed,
So that I have a self-contained backup independent of WebDAV — usable even if I change WebDAV server or need to transfer to a new device.

**Acceptance Criteria:**

**Given** Laurus navigates to the backup section of settings
**When** he taps "Export backup"
**Then** all data (friends, events, acquittements, event_types, settings) is serialized to JSON, encrypted with the passphrase via `EncryptionService`, and saved to device storage as `spetaka_backup_YYYYMMDD.enc`; demo friends (`is_demo = true`) are excluded
**And** the exported file is a complete, self-contained snapshot — restorable to any Android device with Spetaka installed (NFR14)
**And** when Laurus taps "Import backup", a file picker opens; he selects a `.enc` file and enters his passphrase
**And** on successful decryption and import, all data is restored to SQLite — identical to the WebDAV restore flow (Story 6.4)
**And** if the file is corrupted or the passphrase is wrong, a typed error from `error_messages.dart` is shown — no partial data is written
**And** export and import operations show a loading state via Riverpod `AsyncValue` while in progress

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
**Then** the screen displays organized sections: "Sync & Backup" (link to `/settings/sync`, last sync time, manual sync trigger), "Data" (export backup, import backup), "Display" (density preference toggle — synced with daily view toggle), "Event Types" (link to event type editor from Epic 3)
**And** all settings changes take immediate effect — no "Save" button required for toggle-type settings
**And** the WebDAV configuration link opens `WebDavSetupScreen` where Laurus can update URL, credentials, or passphrase (FR40)
**And** a "Reset WebDAV configuration" option clears stored WebDAV URL/username/password from `shared_preferences` and disables sync — with a confirmation dialog
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
**And** the Play Store data safety form is completed: contacts data read but not shared externally; no data transmitted to third parties; encryption in transit (WebDAV, user-controlled)
**And** the APK passes `flutter analyze --fatal-infos` and `flutter test` with zero failures
**And** the app is submitted to the Internal testing track and confirmed installable on Samsung S25 before any wider release
**And** the release track progression plan is documented: Internal → Closed testing (Laurus's circle) → Production (after 4-week gate + zero data-loss validation)


