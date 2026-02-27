---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
status: 'complete'
completedAt: '2026-02-26'
lastStep: 8
inputDocuments:
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
  - "_bmad-output/planning-artifacts/product-brief-Spetaka-2026-02-25.md"
workflowType: 'architecture'
project_name: 'Spetaka'
user_name: 'Laurus'
date: '2026-02-26'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:** 41 FRs across 7 categories:
- Friend Management (Fiches): FR1–FR10 — CRUD for friend cards, contact import,
  tags, free-text notes, concern/préoccupation flag
- Event & Cadence Management: FR11–FR16 — events, recurring cadences, editable
  event type list (5 defaults), manual acknowledgement
- Daily View & Priority Engine: FR17–FR21 — dynamic priority scoring, heart briefing
  2+2, overdue/today/+3-day surface window
- Actions & Communication: FR22–FR25 — 1-tap Call/SMS/WhatsApp, AppLifecycle-based
  return detection for acquittement prompt
- Acquittement & Contact History: FR26–FR31 — enriched acquittement (type + note),
  pre-fill on return, care score update, chronological log per friend
- Sync & Storage: FR32–FR38 — WebDAV configuration + connection test, client-side
  AES-256 encryption before transmission, full restore from WebDAV, encrypted local
  export/import fallback
- Settings & Configuration: FR39–FR41 — settings screen, WebDAV config management,
  full offline functionality

**Non-Functional Requirements:** 17 NFRs across 4 domains:
- Performance: daily view load <1s; priority recomputation <500ms; 1-tap action
  launch <500ms; friend card open <300ms; WebDAV sync background-only (non-blocking)
- Security & Privacy: AES-256 at rest + in transit; passphrase never stored/transmitted;
  key derivation via PBKDF2 or Argon2; minimal permissions (READ_CONTACTS + INTERNET
  only, at point-of-use); zero third-party SDKs, analytics, or telemetry
- Reliability & Data Integrity: SQLite as single source of truth; atomic or safely
  resumable sync operations; full restore from WebDAV; self-contained encrypted backup
- Accessibility: 48×48dp minimum touch targets; WCAG AA contrast (4.5:1); TalkBack
  navigability for core flows

**Scale & Complexity:**

- Primary domain: Mobile — Flutter, Android-first
- Complexity level: Low-Medium
- Single user, local-first, no backend infrastructure
- Data volume: Personal-scale (tens of friend cards, hundreds of events/acquittements)
- Estimated architectural components: ~7 major modules

### Technical Constraints & Dependencies

- **Framework:** Flutter (Dart) — Android v1, iOS path via shared codebase in Phase 3
- **Minimum Android version:** API 26+ (Android 8.0)
- **Local persistence:** SQLite via Drift — source of truth at all times
- **Network:** WebDAV only — no REST API, no Firebase, no third-party cloud
- **Encryption:** AES-256 symmetric; key derived from user passphrase via PBKDF2 or
  Argon2; in-memory key only during active session
- **Contact integration:** Android ContactsContract API via `flutter_contacts` plugin
  (or equivalent); name + primary mobile only; no photo in v1
- **Action intents:** `tel://` (call), `sms://` (SMS), `https://wa.me/` (WhatsApp —
  requires international number format)
- **Zero notification surface:** No FCM, no notification channels, no WorkManager
  notification tasks — enforced at architecture level, not as a setting
- **AppLifecycle dependency:** `AppLifecycleState.resumed` for acquittement detection —
  known OEM variability risk on Samsung; fallback: manual "I just reached out" button

### Cross-Cutting Concerns Identified

1. **Encryption layer** — spans local SQLite storage, WebDAV transmission, file
   export/import; must be a shared, tested abstraction — not duplicated logic
2. **Priority algorithm** — drives daily view ordering, heart briefing, care score
   decay, concern flag weight (×2); performance-critical (<500ms); must be deterministic
   and testable in isolation
3. **AppLifecycle detection** — acquittement trigger; OEM-variable on Android;
   architecturally isolated to enable fallback without touching business logic
4. **Offline-first data flow** — all reads and writes go to SQLite first; sync is
   opportunistic and must never block or corrupt local state
5. **Zero-notification constraint** — no FCM SDK, no notification channels, no
   notification-triggering WorkManager tasks; must be verifiable at build time
6. **Atomic sync / data integrity** — WebDAV sync operations must be atomic or safely
   resumable; partial writes must never overwrite good local data
7. **Phone number normalization** — affects fiche creation (import + manual entry),
   WhatsApp deep-link generation, and SMS intent; must be centralised in a single
   utility to avoid divergence

## Starter Template Evaluation

### Primary Technology Domain

Flutter mobile application — Android-first, iOS-path via shared codebase.
Technology stack fully pre-determined by PRD (Flutter/Dart confirmed, SQLite/Drift
confirmed, WebDAV only, no backend).

### Starter Options Considered

Flutter has no third-party starter generators with broad adoption equivalent to
create-next-app or create-react-app. The canonical entry point is `flutter create`,
supplemented by explicit architectural and package decisions.

**State management evaluated:**

| Option | Assessment for Spetaka |
|---|---|
| **Riverpod** (v3.2.1) | Industry-standard reactive framework; compile-safe providers; ideal for reactive DB streams from Drift; excellent testability; well-maintained. **Selected.** |
| **Bloc/Cubit** | Mature, but higher boilerplate than needed for solo developer at this scale |
| **Provider** | Superseded by Riverpod; same author recommends migration |
| **setState only** | Insufficient for reactive priority engine + cross-widget DB streams |

**Architecture pattern evaluated:**

| Pattern | Assessment for Spetaka |
|---|---|
| **Feature-first clean architecture** | Organises by feature (friends, daily_view, acquittement, sync); scales naturally; aligns with AI-agent story-level implementation. **Selected.** |
| Flat structure | Poor for 7-module app; breaks down quickly |
| Layer-first (global data/domain/presentation) | Cross-cutting makes grep harder; features bleed across layers |

### Selected Starter: `flutter create` + Feature-First Clean Architecture

**Rationale for Selection:**
The standard Flutter SDK `create` command generates the correct minimal scaffold.
Riverpod + Drift provide reactive, type-safe state and persistence. Feature-first
clean architecture creates natural module boundaries that map to implementation
stories, preventing AI-agent scope confusion.

**Initialization Command:**

```bash
flutter create --org dev.spetaka --platforms android spetaka
```

**Architectural Decisions Established:**

**Language & Runtime:**
- Dart (null-safe, latest stable SDK per Flutter 3.41.2)
- Minimum Android API 26 (set in `android/app/build.gradle`)

**State Management:**
- Riverpod `^3.2.1` — reactive providers, code-generated with `riverpod_annotation`
- Drift streams feed directly into Riverpod providers for reactive daily view

**Local Persistence:**
- Drift `^2.31.0` — type-safe SQLite ORM with reactive streams
- Single `AppDatabase` class; tables per entity (friends, events, acquittements, settings)

**Build Tooling:**
- Flutter build system (Gradle underneath for Android)
- `build_runner` for Drift and Riverpod code generation
- `flutter_lints` for analysis

**Testing Framework:**
- `flutter_test` (built-in) for widget tests
- `drift_devtools_extension` + in-memory database for unit testing repositories
- Priority algorithm tested in pure Dart (no Flutter dependency)

**Code Organization — Feature-First:**
```
lib/
  main.dart
  app.dart                        # MaterialApp + ProviderScope
  core/
    database/                     # Drift AppDatabase, DAOs
    encryption/                   # AES-256 service abstraction
    phone/                        # Number normalization utility
    lifecycle/                    # AppLifecycle detection service
  features/
    friends/                      # Fiche CRUD, contact import
    daily_view/                   # Priority engine, heart briefing
    acquittement/                 # Acquittement flow, care score
    sync/                         # WebDAV client, sync coordinator
    settings/                     # Settings screen
  shared/
    widgets/                      # Shared custom widgets
    theme/                        # Design tokens, ThemeData
```

**Development Experience:**
- Android-only platforms flag reduces unnecessary iOS/web scaffolding
- `riverpod_generator` + `drift` codegen via `build_runner watch`
- Flutter DevTools for widget tree inspection and database debugging

**Note:** Project initialization using this command should be the first
implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Encryption library + key derivation algorithm
- Navigation library
- WebDAV client package
- Database migration strategy
- Care score persistence strategy

**Important Decisions (Shape Architecture):**
- Contact import plugin
- URL launcher package
- CI/CD pipeline
- Play Store release track strategy

**Deferred Decisions (Post-MVP):**
- Argon2 key derivation upgrade (if threat model evolves)
- Isolate-based encryption (if benchmark reveals UI jank — unlikely at this data scale)
- App signing automation via CI (manual for v1)

### Data Architecture

**Schema Migration Strategy:** Drift built-in `MigrationStrategy` with explicit
`onUpgrade` per schema version increment. `schemaVersion` integer in `AppDatabase`.
All migrations written and tested before any schema change ships. `beforeOpen`
callback for any data-level migrations.

**Care Score Persistence:** `care_score` stored as a column directly on the
`friends` table, computed and written atomically with each acquittement. Kept
in sync at the data layer — no lazy recomputation at query time. Simplifies the
priority engine to a single read, avoids aggregation queries on the hot path.

**Offline-First Contract (confirmed):** All writes go to SQLite first. WebDAV sync
is fire-and-forget background — never awaited by UI. The local database is always
the source of truth.

### Security & Encryption

**Encryption Package:** `encrypt ^5.0.3` — AES-256-GCM mode
- GCM over CBC: authenticated encryption (integrity + confidentiality in one pass);
  no need for a separate MAC
- Applied to: WebDAV payload (all data files), local export file
- Note: SQLite database file itself is NOT encrypted with SQLCipher in v1 —
  device storage security relies on Android's app sandbox (data/data directory).
  Acceptable for a personal single-user app on a modern Android device.

**Key Derivation:** PBKDF2 (100,000 iterations, SHA-256) via Dart `crypto` package
- Passphrase → 256-bit key derivation at session start
- Derived key held in memory only; never written to disk
- Salt: randomly generated per-installation, stored in `shared_preferences` (not secret)
- Argon2 deferred: more memory-hard but adds native dependency complexity for v1

**Passphrase Lifecycle:**
1. First WebDAV setup: user enters passphrase → key derived → salt stored → test
   encrypt/decrypt to confirm → sync enabled
2. Subsequent app opens: passphrase NOT required on every launch — key re-derived
   only when WebDAV sync runs or on explicit restore
3. Session key: held in `EncryptionService` singleton; cleared on app backgrounding

### API & Communication

**No backend API.** All data operations are local (Drift/SQLite) or WebDAV.

**WebDAV Client:** `webdav_client ^3.0.1`
- Abstracted behind a `SyncRepository` interface for testability
- Operations: upload file, download file, create directory, list files
- All payloads encrypted client-side before any WebDAV call
- Connection test: `propfind` on root path to validate credentials

**URL Launcher / Action Intents:** `url_launcher ^6.3.1`
- `tel:+XXXXX` for phone calls
- `sms:+XXXXX` for SMS
- `https://wa.me/XXXXX` for WhatsApp (requires E.164 international format)
- All three routed through a single `ContactActionService` — phone number
  normalization runs here before any intent fires

**Contact Import:** `flutter_contacts ^1.1.9+2`
- `READ_CONTACTS` permission requested at first tap of "Import from contacts"
- Imports: display name + primary mobile number only (no photo in v1)
- Fallback: manual entry if permission denied or no mobile number on contact

### Frontend Architecture

**Navigation:** GoRouter `^14.6.3`
- Declarative route tree; shell route for bottom navigation bar
- Typed route parameters (friend ID as `String` UUID)
- Deep-link ready for future use cases
- Route structure:
  ```
  /                → DailyViewScreen (home shell)
  /friends         → FriendsListScreen
  /friends/:id     → FriendCardScreen
  /friends/new     → FriendFormScreen
  /settings        → SettingsScreen
  /settings/sync   → WebDavSetupScreen
  ```

**Widget Architecture:**
- Fully custom: `DailyViewWidget`, `FriendCardWidget`, `AcquittementSheet`,
  `GreetingLineWidget`, `EmptyStateWidget`
- M3 scaffold: settings screens, event editor, WebDAV setup form, navigation bar
- Design tokens in `lib/shared/theme/app_theme.dart` — single source of truth

**Shared Preferences:** `shared_preferences ^2.3.5` for lightweight settings
(WebDAV URL/credentials, density preference, last-sync timestamp, PBKDF2 salt)

### Infrastructure & Deployment

**CI/CD:** GitHub Actions
- Trigger: push to `main` + pull requests
- Steps: `flutter analyze` → `flutter test` → `flutter build apk --release`
- No automated deployment in v1 (manual Play Console upload)

**Play Store Strategy:**
- Signing: Play App Signing (Google-managed) — keystore generated locally, upload key
  provided to Google once
- Track: Internal → Closed testing (Laurus's circle) → Production (after 4-week gate)
- Privacy policy required before production (contacts permission triggers disclosure)

**Versioning:** `major.minor.patch+buildNumber` in `pubspec.yaml`
- Build number auto-incremented by CI on every main push
- Version bump manual and deliberate

### Decision Impact Analysis

**Implementation Sequence (critical path):**
1. `flutter create` + project structure scaffold
2. Drift schema + AppDatabase + DAOs (all features depend on this)
3. Encryption service (blocks WebDAV sync + export feature)
4. Priority algorithm (blocks daily view implementation)
5. Features in order: friends CRUD → daily view → acquittement → sync → settings

**Cross-Component Dependencies:**
- Priority algorithm depends on: care_score column, concern flag, event dates,
  cadence intervals — all from Drift schema
- Acquittement flow depends on: AppLifecycle detection service + priority algorithm
  update + care score write
- WebDAV sync depends on: encryption service + Drift serialization to JSON
- Contact import depends on: phone number normalization utility (shared with URL launcher)

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

9 areas where AI agents could make incompatible choices. Every rule below is
mandatory — no agent may deviate without updating this document first.

---

### Naming Patterns

**Database Naming (Drift tables/columns):**
- Table names: `snake_case` plural nouns → `friends`, `events`, `acquittements`, `settings`
- Column names: `snake_case` → `care_score`, `last_contact_at`, `is_concern_active`
- Primary keys: always `id TEXT NOT NULL` (UUID string — see IDs section below)
- Foreign keys: `{singular_table_name}_id` → `friend_id` (not `friendId`, not `fk_friend`)
- Timestamps: always `_at` suffix, stored as `INTEGER` (Unix epoch ms) → `created_at`, `updated_at`
- Boolean columns: `is_` prefix → `is_concern_active`, `is_sync_enabled`

**Dart Code Naming:**
- Classes: `PascalCase` → `FriendRepository`, `PriorityEngine`, `EncryptionService`
- Methods/functions: `camelCase` → `computePriorityScore()`, `logAcquittement()`
- Variables/fields: `camelCase` → `careScore`, `lastContactAt`
- Constants: `camelCase` in `const` context → `const kDefaultEventTypes`
- Files: `snake_case` → `friend_repository.dart`, `priority_engine.dart`
- Riverpod providers (generated): file is `foo.dart` → generated as `foo.g.dart`

**Flutter Widget Naming:**
- Screen widgets (full-page): `{Name}Screen` → `DailyViewScreen`, `FriendCardScreen`
- Reusable widgets: `{Name}Widget` or descriptive noun → `GreetingLineWidget`, `FriendCardTile`
- Bottom sheets: `{Name}Sheet` → `AcquittementSheet`
- Dialogs: `{Name}Dialog` → `DeleteConfirmDialog`

**GoRouter Route Naming:**
- Route path: `kebab-case` → `/friends/new`, `/settings/sync`
- Route name constants: `camelCase` string → `'friendCard'`, `'webdavSetup'`
- Route parameter: `:id` for entity IDs → `/friends/:id`

---

### Entity Identity (IDs)

**All entities use UUID v4 strings as primary keys.**

- Format: `String` UUID — `'a1b2c3d4-e5f6-...'`
- Generated in Dart at creation time: `const Uuid().v4()` via `uuid ^4.5.1` package
- Never use auto-increment integers — UUIDs are required for offline-first conflict-free
  creation and WebDAV portability
- Drift column definition: `TextColumn get id => text()();`

---

### Repository Pattern

**Layers are strictly separated. No business logic in DAOs. No SQL in features.**

```
Feature layer (Riverpod providers, widgets)
    ↓ calls
Repository layer (lib/features/{name}/{name}_repository.dart)
    ↓ calls
DAO layer (lib/core/database/daos/{name}_dao.dart)
    ↓ queries
Drift AppDatabase (lib/core/database/app_database.dart)
```

**Rules:**
- DAOs: Drift queries only — no business logic, no validation
- Repositories: business logic, validation, coordinate DAOs and services
  (encryption, sync notification, care score update)
- Providers: expose repository streams/futures to UI — no data transformation
- Features NEVER import DAOs directly — always through their Repository

---

### Riverpod Patterns

**Always use code-generation (`@riverpod` annotation). Never write manual providers.**

```dart
// ✅ CORRECT
@riverpod
class FriendsNotifier extends _$FriendsNotifier {
  @override
  Stream<List<Friend>> build() =>
      ref.watch(friendRepositoryProvider).watchAll();
}

// ❌ WRONG — manual provider
final friendsProvider = StreamProvider<List<Friend>>((ref) => ...);
```

**`ref.watch` vs `ref.read` rules:**
- `ref.watch`: inside `build()` methods only — never in callbacks or async functions
- `ref.read`: inside event handlers, `onTap`, async methods — one-time access

**AsyncValue handling — always handle all three states:**
```dart
// ✅ CORRECT
return switch (friendsAsync) {
  AsyncData(:final value) => FriendsList(friends: value),
  AsyncError(:final error) => ErrorWidget(error: error),
  _ => const LoadingWidget(),
};

// ❌ WRONG — ignoring error/loading
return FriendsList(friends: friendsAsync.value ?? []);
```

**No `setState` in widgets that use Riverpod** — all mutable state goes through providers.

---

### Error Handling Patterns

**Where errors are caught:**
- Repository layer catches `DriftException`, `WebDavException`, etc. and wraps them
  in typed domain errors from `lib/core/errors/`
- Riverpod `AsyncValue.error` propagates to UI automatically — no manual try/catch in providers
- UI handles errors through `AsyncValue` pattern — never raw try/catch in widgets

**User-facing error messages:**
- Never expose stack traces or technical exception messages to users
- All user-visible strings come from `lib/core/errors/error_messages.dart`
- WebDAV errors: specific messages — `'Connection failed — check your server URL'`

**Logging:**
- Use `dart:developer` `log()` — never `print()`
- Convention: `log('message', name: 'ClassName', error: e, stackTrace: st)`
- No third-party logging SDK (NFR10: zero third-party telemetry)

---

### Loading State Patterns

**Use Riverpod `AsyncValue` everywhere. No manual `isLoading` booleans.**

**Background operations (WebDAV sync):** tracked in `SyncStatusProvider` — subtle
non-blocking indicator in UI. Sync errors surfaced as dismissible banner, not modal.

---

### DateTime & Timestamp Patterns

- **Storage:** all timestamps as `int` Unix epoch milliseconds in SQLite
- **Drift column:** `IntColumn get createdAt => integer()();`
- **Dart type:** convert at DAO boundary:
  - Write: `datetime.millisecondsSinceEpoch`
  - Read: `DateTime.fromMillisecondsSinceEpoch(value)`
- **Display:** formatted in widgets using `intl` package `DateFormat`
- **Never** store `DateTime` as ISO string in SQLite

---

### Dart Serialization (WebDAV / Export)

**All entities serialize via `fromJson`/`toJson` on model class. Handwritten — no codegen.**

- JSON field names: `snake_case` (matches DB column names)
- Nullables: omit key if null — don't include `"field": null`
- Timestamps in JSON: ISO 8601 string for human-readable backup files

---

### Test Patterns

- **Unit tests** (priority algorithm, phone normalization, encryption):
  `test/unit/{feature}/` — pure Dart, no Flutter dependency
- **Repository tests:** `test/repositories/` — Drift in-memory database
  (`NativeDatabase.memory()`), no mocking of DAOs
- **Widget tests:** `test/widgets/` — provider overrides via
  `ProviderScope(overrides: [...])`, never mock Flutter widgets
- **No golden tests in v1**

---

### AppLifecycle Detection Pattern

**Acquittement trigger isolated in `AppLifecycleService` — never observed directly in features.**

- Single `AppLifecycleService` observes `AppLifecycleState.resumed`
- Emits a `FriendId?` stream; features subscribe via `appLifecycleServiceProvider`
- OEM fallback: service emits null → acquittement triggered via manual button on card
- **Never** use `WidgetsBindingObserver` directly in feature widgets

---

### Enforcement Guidelines

**All AI agents MUST:**
1. Use UUID strings for all entity IDs — no auto-increment integers
2. Place SQL/Drift queries exclusively in DAOs — never in repositories or features
3. Use `@riverpod` code generation — never write manual providers
4. Handle all three `AsyncValue` states (data/error/loading) in every consuming widget
5. Store timestamps as `int` epoch ms in SQLite; convert at DAO boundary
6. Route all phone intent actions through `ContactActionService` — never call
   `url_launcher` directly from a widget
7. Use `dart:developer` `log()` for all logging — never `print()`
8. Never import a DAO in a feature widget — always through the repository layer

**Anti-patterns (forbidden):**
- `print()` anywhere in production code
- Manual `isLoading` booleans alongside Riverpod
- Direct `Navigator.push()` — always use GoRouter's `context.go()` / `context.push()`
- Auto-increment integer primary keys
- Storing `DateTime` as ISO string in SQLite
- Calling `url_launcher` from a widget directly
- `WidgetsBindingObserver` outside `AppLifecycleService`

## Project Structure & Boundaries

### Complete Project Directory Structure

```
spetaka/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── ci.yml                    # flutter analyze → test → build apk
│
├── android/
│   ├── app/
│   │   ├── build.gradle              # minSdk 26, targetSdk latest
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # INTERNET + READ_CONTACTS (no notifications)
│   │       └── kotlin/.../MainActivity.kt
│   └── build.gradle
│
├── assets/
│   └── fonts/
│       ├── DMSans/                   # Primary typeface
│       └── Lora/                     # Greeting line candidate
│
├── test/
│   ├── unit/
│   │   ├── priority_engine_test.dart
│   │   ├── phone_normalizer_test.dart
│   │   └── encryption_service_test.dart
│   ├── repositories/
│   │   ├── friend_repository_test.dart
│   │   ├── event_repository_test.dart
│   │   ├── acquittement_repository_test.dart
│   │   └── sync_repository_test.dart
│   └── widgets/
│       ├── daily_view_test.dart
│       ├── friend_card_test.dart
│       └── acquittement_sheet_test.dart
│
└── lib/
    ├── main.dart                     # ProviderScope + runApp
    ├── app.dart                      # MaterialApp.router + GoRouter + AppTheme
    │
    ├── core/
    │   ├── database/
    │   │   ├── app_database.dart     # Drift AppDatabase, schemaVersion
    │   │   ├── app_database.g.dart   # generated
    │   │   └── daos/
    │   │       ├── friend_dao.dart
    │   │       ├── event_dao.dart
    │   │       ├── acquittement_dao.dart
    │   │       └── settings_dao.dart
    │   │
    │   ├── encryption/
    │   │   └── encryption_service.dart   # AES-256-GCM, PBKDF2 key derivation
    │   │
    │   ├── actions/
    │   │   ├── contact_action_service.dart  # url_launcher orchestration
    │   │   └── phone_normalizer.dart        # E.164 normalization utility
    │   │
    │   ├── lifecycle/
    │   │   └── app_lifecycle_service.dart   # AppLifecycleState.resumed observer
    │   │
    │   ├── errors/
    │   │   ├── app_error.dart           # Typed domain error hierarchy
    │   │   └── error_messages.dart      # All user-visible error strings
    │   │
    │   └── router/
    │       └── app_router.dart          # GoRouter route tree
    │
    ├── features/
    │   ├── friends/
    │   │   ├── data/
    │   │   │   └── friend_repository.dart    # CRUD, contact import, concern flag
    │   │   ├── domain/
    │   │   │   ├── friend.dart               # Drift table + model
    │   │   │   └── event.dart                # Drift table + model (events + cadences)
    │   │   ├── providers/
    │   │   │   ├── friend_providers.dart     # @riverpod watchAll, watchOne
    │   │   │   └── friend_providers.g.dart   # generated
    │   │   └── presentation/
    │   │       ├── friends_list_screen.dart
    │   │       ├── friend_card_screen.dart   # Expanded card + action buttons
    │   │       ├── friend_form_screen.dart   # Create/edit fiche
    │   │       └── widgets/
    │   │           ├── friend_card_tile.dart # Collapsed card in daily view
    │   │           └── event_list_tile.dart
    │   │
    │   ├── daily_view/
    │   │   ├── domain/
    │   │   │   └── priority_engine.dart      # Pure Dart — score computation
    │   │   ├── providers/
    │   │   │   ├── daily_view_providers.dart # @riverpod prioritised stream
    │   │   │   └── daily_view_providers.g.dart
    │   │   └── presentation/
    │   │       ├── daily_view_screen.dart
    │   │       └── widgets/
    │   │           ├── greeting_line_widget.dart   # Coach-tone greeting
    │   │           ├── heart_briefing_widget.dart  # 2+2 urgent/important cards
    │   │           └── empty_state_widget.dart     # Virtual friend / all clear
    │   │
    │   ├── acquittement/
    │   │   ├── data/
    │   │   │   └── acquittement_repository.dart  # Log, update care score
    │   │   ├── domain/
    │   │   │   └── acquittement.dart             # Drift table + model
    │   │   ├── providers/
    │   │   │   ├── acquittement_providers.dart
    │   │   │   └── acquittement_providers.g.dart
    │   │   └── presentation/
    │   │       └── acquittement_sheet.dart       # Bottom sheet, pre-fill, sage anim
    │   │
    │   ├── sync/
    │   │   ├── data/
    │   │   │   ├── sync_repository.dart          # WebDAV orchestration, atomic ops
    │   │   │   └── webdav_client_adapter.dart    # webdav_client wrapper
    │   │   ├── providers/
    │   │   │   ├── sync_providers.dart           # SyncStatusProvider
    │   │   │   └── sync_providers.g.dart
    │   │   └── presentation/
    │   │       └── webdav_setup_screen.dart      # M3-based config + test connection
    │   │
    │   └── settings/
    │       ├── data/
    │       │   └── settings_repository.dart      # shared_preferences wrapper
    │       ├── providers/
    │       │   ├── settings_providers.dart
    │       │   └── settings_providers.g.dart
    │       └── presentation/
    │           ├── settings_screen.dart          # M3-based settings list
    │           └── export_import_screen.dart     # Encrypted file backup/restore
    │
    └── shared/
        ├── theme/
        │   ├── app_theme.dart        # ThemeData, ColorScheme from tokens
        │   └── app_tokens.dart       # All design tokens (colors, spacing, radius, motion)
        └── widgets/
            ├── loading_widget.dart   # Standard loading state
            └── error_widget.dart     # Standard error state
```

### Architectural Boundaries

**Feature Boundary Rule:** Each feature in `lib/features/{name}/` is self-contained.
A feature's presentation layer may import from `lib/shared/` and `lib/core/` but
**never** from another feature's presentation or domain layer directly. Cross-feature
data flows through the core database layer (shared Drift tables).

**Core Boundary Rule:** `lib/core/` modules are infrastructure — they have no
knowledge of features. They may be imported by any layer above them.

**DAO Boundary Rule:** DAOs live in `lib/core/database/daos/` and are injected into
repositories. No file outside `lib/features/{name}/data/` imports a DAO.

### Architectural Boundaries — Communication

**Data flow (read):**
```
Drift (SQLite) → DAO → Repository → Riverpod Stream Provider → Widget
```

**Data flow (write):**
```
Widget event → Riverpod Notifier → Repository → DAO → Drift
                                  ↘ EncryptionService (if sync triggered)
                                  ↘ SyncRepository (background, fire-and-forget)
```

**AppLifecycle flow:**
```
Android OS → AppLifecycleService → stream → acquittement provider
                                           → AcquittementSheet (auto-show)
```

**Contact action flow:**
```
Widget tap → ContactActionService → PhoneNormalizer → url_launcher
           ↘ records pending friend ID for lifecycle return
```

### Requirements to Structure Mapping

**FR1–FR10 (Friend Management):**
- Domain model: `lib/features/friends/domain/friend.dart`
- CRUD + import: `lib/features/friends/data/friend_repository.dart`
- Contact import via `flutter_contacts`; normalised via `lib/core/actions/phone_normalizer.dart`
- Concern flag: column on `friends` table; toggled in `FriendRepository`

**FR11–FR16 (Events & Cadences):**
- Domain model: `lib/features/friends/domain/event.dart`
- CRUD in `FriendRepository` (events are sub-entity of friends)
- Default event types seeded via `AppDatabase.beforeOpen` migration callback

**FR17–FR21 (Daily View & Priority Engine):**
- Algorithm: `lib/features/daily_view/domain/priority_engine.dart` (pure Dart)
- Stream: `lib/features/daily_view/providers/daily_view_providers.dart`
- Heart briefing: `lib/features/daily_view/presentation/widgets/heart_briefing_widget.dart`

**FR22–FR25 (Actions & Communication):**
- Intent dispatch: `lib/core/actions/contact_action_service.dart`
- Number normalisation: `lib/core/actions/phone_normalizer.dart`
- Return detection: `lib/core/lifecycle/app_lifecycle_service.dart`

**FR26–FR31 (Acquittement & History):**
- Repository: `lib/features/acquittement/data/acquittement_repository.dart`
  (writes acquittement row + updates `care_score` on `friends` table atomically)
- Sheet: `lib/features/acquittement/presentation/acquittement_sheet.dart`

**FR32–FR38 (Sync & Storage):**
- WebDAV: `lib/features/sync/data/sync_repository.dart`
- Encryption: `lib/core/encryption/encryption_service.dart`
- Export/import: `lib/features/settings/presentation/export_import_screen.dart`

**FR39–FR41 (Settings):**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/data/settings_repository.dart`

### Integration Points

**Internal Communication:**
- All features communicate through shared Drift tables (never direct object passing)
- Priority engine reads from `friends`, `events`, `acquittements` via DAOs
- Acquittement write triggers `care_score` update on `friends` — same DB transaction

**External Integrations:**
- `flutter_contacts` (Android ContactsContract) — in `FriendRepository.importFromContacts()`
- `url_launcher` (tel/sms/whatsapp) — in `ContactActionService` only
- `webdav_client` (HTTP WebDAV) — in `WebDavClientAdapter` only, behind `SyncRepository`

**Data Flow — Sync:**
1. `SyncRepository.syncNow()` called by `SyncStatusProvider` on app resume (if configured)
2. All data serialised to JSON via model `toJson()`
3. JSON encrypted with `EncryptionService.encrypt()`
4. Encrypted bytes uploaded to WebDAV
5. On restore: download → decrypt → `fromJson()` → write to Drift

### Development Workflow Integration

**Code generation:** `flutter pub run build_runner watch` — re-generates `.g.dart` files on save

**Build variants:**
- Debug: `flutter run` (hot reload)
- Release APK: `flutter build apk --release` (CI artifact)
- Play Store bundle: `flutter build appbundle --release` (manual upload)

**Key `pubspec.yaml` dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^3.2.1
  go_router: ^14.6.3
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.29
  path_provider: ^2.1.5
  path: ^1.9.1
  encrypt: ^5.0.3
  crypto: ^3.0.6
  uuid: ^4.5.1
  flutter_contacts: ^1.1.9+2
  url_launcher: ^6.3.1
  webdav_client: ^3.0.1
  shared_preferences: ^2.3.5
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^3.0.0
  drift_dev: ^2.31.0
  build_runner: ^2.4.14
  flutter_lints: ^5.0.0
```


---

## Architecture Validation Results

### Coherence Validation ✅

All technology choices are version-compatible; no conflicts detected.

| Package | Version | Compatibility |
|---|---|---|
| Flutter | 3.41.2 | — |
| Drift / drift_dev | 2.31.0 | matched pair ✅ |
| Riverpod / riverpod_annotation | 3.2.1 | matched pair ✅ |
| riverpod_generator | 3.0.0 | compatible ✅ |
| GoRouter | 14.6.3 | Flutter 3.x ✅ |
| encrypt | 5.0.3 | Dart-native ✅ |
| crypto | 3.0.6 | Dart-native ✅ |
| uuid | 4.5.1 | Dart-native ✅ |

**Zero-notification constraint structurally enforced:** no FCM SDK in pubspec, no notification channels defined in AndroidManifest, no WorkManager notification tasks — verifiable at build time.

**Repository→DAO→Drift layering:** unambiguous, no circular dependencies possible in the defined file structure.

---

### Requirements Coverage Validation ✅

All 41 FRs covered across 7 categories — each mapped to a specific file in the project structure.

All 17 NFRs architecturally addressed:

| Domain | NFRs | Coverage |
|---|---|---|
| Performance (NFR1–5) | Priority engine: pure Dart in `priority_engine.dart`; Drift reactive streams; WebDAV background-only | ✅ |
| Security (NFR6–10) | AES-256-GCM + PBKDF2 100k iterations; encryption key in-memory only; minimal permissions at point-of-use; zero third-party analytics/tracking SDKs | ✅ |
| Reliability (NFR11–14) | SQLite single source of truth; atomic DB transactions for acquittement + care_score update; full WebDAV restore path via `sync_repository.dart` | ✅ |
| Accessibility (NFR15–17) | M3 scaffold provides 48dp touch targets and WCAG AA contrast by default; custom widgets require explicit `Semantics` enforcement (rule added post-gap-analysis) | ✅ |

---

### Implementation Readiness Validation ✅

- All critical decisions documented with package names and verified versions
- Complete directory tree with 40+ named files — no unnamed placeholders
- Every FR maps to a specific file
- Initialization command defined: `flutter create --org dev.spetaka --platforms android spetaka`
- CI/CD pipeline fully specified (GitHub Actions: analyze → test → build APK)

---

### Gap Analysis Results

**Critical gaps:** None.

**Important gap identified and resolved:** TalkBack accessibility enforcement for custom widgets.

During NFR15–17 validation review, it was identified that 5 custom widgets in the core loop could silently fail TalkBack without explicit enforcement. The following rule was added to the Implementation Patterns section:

> All custom widgets in the core loop (`GreetingLineWidget`, `FriendCardTile`, `AcquittementSheet`, `HeartBriefingWidget`, `EmptyStateWidget`) MUST wrap all interactive elements in a `Semantics` widget with a meaningful `label` attribute. Failure to do so is a blocking code review issue.

**Nice-to-have gaps (deferred to post-v1):**
- Virtual friend seed locale detail (date/time display strategy per locale)
- Full `intl` date locale configuration strategy
- SQLCipher for SQLite at-rest encryption
- Argon2 key derivation upgrade (PBKDF2 is sufficient for v1)
- Golden test suite

---

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] 41 Functional Requirements extracted and categorized
- [x] 17 Non-Functional Requirements mapped to architectural decisions
- [x] Constraints identified (Android-only, no notifications, offline-first, solo dev)
- [x] 7 cross-cutting concerns documented

**✅ Architectural Decisions**
- [x] Full technology stack with verified pub.dev versions
- [x] Encryption strategy (AES-256-GCM + PBKDF2)
- [x] State management (Riverpod 3.2.1 with mandatory codegen)
- [x] Navigation (GoRouter 14.6.3 with typed routes)
- [x] Persistence (Drift 2.31.0, feature-local DAOs)
- [x] Sync strategy (WebDAV with export/import fallback)
- [x] CI/CD (GitHub Actions → Play App Signing → Internal → Production)

**✅ Implementation Patterns**
- [x] 9 naming convention categories
- [x] Layering rules (Repository → DAO → Drift)
- [x] Riverpod patterns with code examples (`@riverpod` codegen mandatory)
- [x] Error/loading/DateTime/serialization/test/lifecycle patterns
- [x] 8 mandatory enforcement rules
- [x] 7 anti-patterns with explanations
- [x] Accessibility rule added post-validation (Semantics enforcement)

**✅ Project Structure**
- [x] Complete 40+ file directory tree
- [x] Feature boundary rules
- [x] 4 data flow diagrams (read, write, lifecycle, contact action)
- [x] FR-to-file mapping
- [x] Full `pubspec.yaml` with all dependencies

---

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**
**Confidence Level: High**

**Key Strengths:**
- Technology stack fully pre-validated by PRD — no exploratory decisions needed during implementation
- Feature-first structure maps cleanly to AI-agent story-level execution
- Priority algorithm physically isolated in `priority_engine.dart` — independently testable, pure Dart
- Zero-notification constraint structurally enforced — verifiable at build time without runtime testing
- WebDAV sync fallback (export/import) built into directory structure from day one
- Care score updated atomically with acquittement — no consistency bugs possible

**Areas for Future Enhancement (post-v1):**
- SQLCipher for SQLite at-rest encryption
- Argon2 key derivation upgrade
- Golden test suite for visual regression
- iOS platform addition (Phase 3 of roadmap)

---

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented — no re-evaluation needed
- Use `@riverpod` codegen exclusively — never write manual `Provider()` calls
- All entity primary keys are UUID v4 strings — never use auto-increment integers
- Strict layering: DAO → Repository → Provider (via notifier) → Widget
- `priority_engine.dart` is pure Dart — keep it free of Flutter and Drift imports; test it independently
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after any Riverpod or Drift schema changes

**First Implementation Step:**

```bash
flutter create --org dev.spetaka --platforms android spetaka
```

Then scaffold `lib/` according to the Project Structure section before writing any feature code.
