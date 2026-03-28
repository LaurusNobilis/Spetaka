---
status: 'complete'
completedAt: '2026-03-25'
date: '2026-03-25'
project_name: 'Spetaka'
user_name: 'Laurus'
parentArchitecture: '_bmad-output/planning-artifacts/architecture.md'
addendumScope:
  - 'on-device-llm'
  - 'session-draft-storage'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
decisionsRecorded:
  - Q1-use-cases: 'daily-greeting-line + whatsapp-sms-message-suggestion-per-event'
  - Q2-deployment: 'on-device-only-no-cloud-ever'
  - Q3-unavailability: 'unsupported-hardware→disable-with-message; model-not-downloaded→hard-gate'
  - Q4-draft-surfaces: 'friend-card-form-only'
  - Q5-draft-lifetime: 'session-only-in-memory'
---

# Architecture Phase 2 Addendum

_Addendum to [architecture.md](_bmad-output/planning-artifacts/architecture.md) (Phase 1, completed 2026-02-26).
All Phase 1 decisions remain authoritative and unchanged. This document extends them for two Phase 2 concerns only:_

1. **On-device LLM inference** — Gemma-based greeting line generation and WhatsApp/SMS message suggestions
2. **Session-draft storage** — In-memory auto-save for the friend card form

---

## Phase 2 Requirements Scope

### Functional Requirements Addressed

| FR | Description | Scope |
|---|---|---|
| FR44 | User can create a draft message on a friend card — free-text template contextualised for that friend | Message generation UI |
| FR45 | User can request the on-device LLM to generate ≥ 3 alternative phrasings for a draft message | LLM inference service |
| FR46 | LLM inference runs entirely on-device with no network call; triggered only by explicit user action | `LlmInferenceService` constraint |
| FR47 | User can edit, save, or discard any draft message or LLM-suggested variant before use | `DraftMessageSheet` UX |
| _Addendum_ | Daily greeting line generated dynamically by LLM (coach-tone, contextualised to current relationship state) | `GreetingService` |

### Non-Functional Requirements Addressed

| NFR | Description |
|---|---|
| NFR18 | LLM inference on-device only (Gemma-3n-E2B-it or equivalent); no prompt or output ever transmitted |
| NFR19 | No `INTERNET` permission used for LLM inference; feature works in airplane mode |
| NFR20 | Bundled/downloaded model ≤ 4 GB device storage |
| NFR21 | LLM inference triggered only by explicit user action; no background or auto-inference |

**Note on INTERNET permission:** Phase 2 already adds `INTERNET` for WebDAV sync. The model download (one-time, user-initiated) uses this same permission. No new permission category is introduced.

**Out of scope for this addendum:** WebDAV sync (already in Phase 1 architecture as deferred to Phase 2), friend list filters (FR11–13), last contact display (FR14), concern follow-up auto-cadence (FR21/FR51). Those require separate architecture work.

---

## Part 1: On-Device LLM Architecture

### Use Cases

**UC1 — Daily Greeting Line:**
Each time the daily view loads, if the LLM is available, `GreetingService` generates a single coach-tone greeting line contextualised to the current relationship state (overdue count, concern flags, care scores). If LLM is unavailable, falls back silently to a static hardcoded pool.

**UC2 — Message Suggestion per Event:**
On a friend card, the user taps "Suggest message" on a specific event (e.g. "Birthday in 3 days"). The LLM generates ≥ 3 WhatsApp/SMS message variants contextualised to that friend and event. The user selects or copies one, then launches it via `ContactActionService` (existing component — no change needed).

Both use cases are **explicit user action** or foreground view load only — no background inference.

---

### Technology Decision: Flutter Integration Layer

**Selected: `flutter_gemma`**

| Option | Assessment |
|---|---|
| **`flutter_gemma`** | Official Google Flutter package wrapping the MediaPipe Tasks GenAI API for Gemma models on Android. Dart-native API, isolate-compatible, production-quality as of Phase 2 time horizon. **Selected.** |
| Raw MediaPipe Flutter bindings | Lower-level, less stable Dart API surface, more maintenance burden for the same capability |
| Platform channel to native MediaPipe SDK | Maximum control but requires Kotlin/Java maintenance alongside Dart; unjustified for a solo developer |

**Model: Gemma-3n-E2B-it** (Edge 2B, instruction-tuned)
- Storage footprint: ~2 GB (INT4 quantised) — well within 4 GB NFR20 constraint
- Runs on CPU with optional GPU/NPU acceleration (Snapdragon 8 Gen 2+, Tensor G3+)
- Downloaded once to `getApplicationDocumentsDirectory()` internal storage, never bundled in APK
- Zero network call at inference time (NFR19 compliant)

---

### Device Capability Strategy

Two independent gates — both must pass for LLM features to be active:

**Gate 1 — Hardware Support Check (`AiCapabilityChecker`):**
- Checks Android API level ≥ 29 and available RAM ≥ 4 GB at runtime
- If unsupported → LLM features permanently disabled; user sees banner:
  _"Les fonctionnalités IA nécessitent un appareil compatible (Android 10+ / 4 Go RAM minimum)."_
  Feature UI is hidden, not just greyed — no dead UI elements on unsupported devices.

**Gate 2 — Model Download Check (`ModelManager`):**
- If hardware is supported but model not downloaded → hard gate:
  User sees `ModelDownloadScreen` with storage requirement, download button, progress indicator.
  LLM feature entry points are locked behind `ModelManager.isModelReady`.
- Downloaded model stored at: `{appDocumentsDir}/spetaka_llm/gemma3n_e2b_it_int4.bin`
- `ModelManager` exposes a `Stream<ModelDownloadState>` (idle / downloading / ready / error)

---

### Core AI Module: `lib/core/ai/`

```
lib/core/ai/
  llm_inference_service.dart   # flutter_gemma wrapper; inference runs in Dart Isolate
  model_manager.dart           # Download, storage, capability state machine
  ai_capability_checker.dart   # Hardware + API level detection
  prompt_templates.dart        # All LLM prompt templates (greeting, message suggestion)
  greeting_service.dart        # UC1: daily greeting generation, static fallback pool
```

**`LlmInferenceService`:**
- Singleton, initialised lazily on first inference request
- All `infer(String prompt)` calls execute in a `Dart Isolate` via `Isolate.run()` — UI thread never blocked
- Returns `Future<List<String>>` (list of generated variants, trimmed and validated)
- Internal timeout: 30 seconds per inference; on timeout → returns empty list, greeting falls back to static

**`PromptTemplates`:**
All prompts are constant strings in this file. No AI-generated prompts are constructed at runtime outside this file. This centralises the "prompt surface" for review and testing.

```dart
// Example — message suggestion prompt
static String messageSuggestion({
  required String friendName,
  required String eventType,
  required String eventContext,
  required String channel, // 'WhatsApp' or 'SMS'
}) => '''
Tu es un assistant qui aide à maintenir des liens sincères avec ses proches.
Génère 3 courts messages $channel pour $friendName à l'occasion de : $eventType — $eventContext.
Les messages doivent être chaleureux, personnels, et naturels.
Formate ta réponse comme une liste numérotée (1. 2. 3.)
''';
```

**`GreetingService`:**
- On `DailyViewScreen` load: checks `ModelManager.isModelReady` → if ready, calls `LlmInferenceService.infer(greeting prompt)` asynchronously
- While awaiting: shows static greeting from hardcoded pool (no loading spinner for greeting line — zero degraded UX)
- On LLM response: updates `greetingLineProvider` state → widget reacts via Riverpod
- Greeting prompt context: overdue count, concern flag count, last care score average

---

### Draft Messages Feature Module: `lib/features/drafts/`

```
lib/features/drafts/
  domain/
    draft_message.dart           # Data class: friendId, eventContext, variants, selectedVariant
  data/
    llm_message_repository.dart  # Builds prompts, calls LlmInferenceService, parses response
  providers/
    draft_providers.dart         # @riverpod DraftMessageNotifier (in-memory session state)
    draft_providers.g.dart       # generated
  presentation/
    draft_message_sheet.dart     # Bottom sheet: event context + 3 variants + copy/edit/send
    model_download_screen.dart   # Download gate screen (progress, storage info, cancel)
```

**`DraftMessage` (domain model — not a Drift table):**
```dart
class DraftMessage {
  final String friendId;
  final String eventContext;   // Event type + description
  final String channel;        // 'whatsapp' | 'sms'
  final List<String> variants; // ≥3 LLM-generated phrasings
  String? editedText;          // User's edited/custom version
}
```
This is a pure in-memory object. It is not persisted to SQLite (session-only — dies with the process).

**`LlmMessageRepository`:**
- Single method: `Future<DraftMessage> generateSuggestions({required String friendId, required Event event, required String channel})`
- Loads friend name from `FriendRepository` (read-only)
- Constructs prompt via `PromptTemplates.messageSuggestion(...)`
- Calls `LlmInferenceService.infer(prompt)`
- Parses numbered-list response into `List<String>` variants
- Returns `DraftMessage` instance

**`DraftMessageNotifier` (Riverpod):**
```dart
@riverpod
class DraftMessageNotifier extends _$DraftMessageNotifier {
  @override
  AsyncValue<DraftMessage?> build() => const AsyncData(null);

  Future<void> requestSuggestions({required String friendId, required Event event, required String channel}) async { ... }
  void updateEditedText(String text) { ... }
  void clear() => state = const AsyncData(null); }
```

**`DraftMessageSheet` (presentation):**
- Bottom sheet opened from `FriendCardScreen` when user taps "Suggest message" on an event
- Shows: event context header, 3 variant cards (tap to select), editable text field pre-filled with selection, "Copy & Send via WhatsApp/SMS" button, "Discard" option
- "Copy & Send" → copies to clipboard + calls `ContactActionService` to launch intent
- No saving to SQLite — sheet dismissal clears the draft

---

### Rewired Data Flows

**Daily Greeting Line (UC1):**
```
DailyViewScreen.build()
  → ref.watch(greetingLineProvider)   [shows static fallback immediately]
  → GreetingService.generateAsync()
      → ModelManager.isModelReady?
          No  → return (static shown, no update)
          Yes → LlmInferenceService.infer(greeting prompt) [in Isolate]
                → greetingLineProvider updated → widget reacts
```

**Message Suggestion (UC2):**
```
User taps "Suggest message" on event in FriendCardScreen
  → ModelManager.isModelReady?
      Hardware unsupported → show snackbar "Appareil non compatible"
      Not downloaded       → navigate to ModelDownloadScreen
      Ready                → open DraftMessageSheet (AsyncLoading state)
                              → DraftMessageNotifier.requestSuggestions()
                                  → LlmMessageRepository.generateSuggestions()
                                      → LlmInferenceService.infer() [Isolate]
                                  → DraftMessageSheet shows variants
  User selects variant → edits → taps "Copy & Send via WhatsApp"
  → ContactActionService.openWhatsApp(friend.mobile, selectedText)
  → DraftMessageNotifier.clear()
```

---

### Riverpod Providers (AI)

```dart
// Model state — all LLM gates depend on this
@riverpod
Stream<ModelDownloadState> modelManager(ModelManagerRef ref) =>
    ref.watch(modelManagerInstanceProvider).stateStream;

// Greeting line — session-scoped, refreshes on daily view load
@riverpod
class GreetingLineNotifier extends _$GreetingLineNotifier {
  @override
  String build() => GreetingService.staticFallback(); // immediate non-null value
  // GreetingService updates this async post-inference
}

// Message drafts per friend card — cleared on sheet close
@riverpod
class DraftMessageNotifier extends _$DraftMessageNotifier { ... }
```

---

### pubspec.yaml Additions (Phase 2 LLM)

```yaml
dependencies:
  # --- Phase 2: On-device LLM ---
  flutter_gemma: ^1.x.x          # Gemma on-device inference via MediaPipe Tasks GenAI
  # Note: flutter_gemma uses INTERNET only for model download (same permission as WebDAV)
  # All inference is fully offline; no API key or cloud endpoint configured

dev_dependencies:
  # No new dev dependencies for LLM
```

**Model download mechanism:** `ModelManager` uses `flutter_gemma`'s built-in download API which fetches the model from a user-configured or Google-hosted URL to app-internal storage. The URL is configured in `PromptTemplates` constants, not hardcoded in `ModelManager`. Model is stored in app-internal storage (`getApplicationDocumentsDirectory()`), inaccessible to other apps.

---

### AndroidManifest.xml Changes (Phase 2 LLM)

```xml
<!-- Already added by Phase 2 WebDAV work: -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- No additional permissions for LLM inference or model storage -->
```

No new permissions required beyond the `INTERNET` already added for WebDAV.

---

## Part 2: Session-Draft Storage Architecture

### Decision Summary

| Decision | Choice | Rationale |
|---|---|---|
| Persistence strategy | **Session-only in-memory (Riverpod state)** | Simplicity; no schema migration; no encryption needed; acceptable for a personal app where the user is the only actor |
| Affected surfaces | **Friend card form only** (create + edit) | Only FR surface where partial data loss is a meaningfully disruptive UX problem |
| Storage mechanism | **Riverpod `@riverpod` notifier** | Consistent with all other state in the app; zero new infrastructure |
| Encryption | **None required** | Data never leaves RAM; in-memory state is cleared on process kill; aligns with minimal-surface security posture |
| Drift table | **None** | Session-only means no persistence layer — avoids `schemaVersion` bump |

### What Changes in Existing Modules

**New file: `lib/features/friends/domain/friend_form_draft.dart`**
```dart
class FriendFormDraft {
  final String? name;
  final String? mobile;
  final String? notes;
  final List<String> categoryTags;
  final bool isConcernActive;
  final String? concernNote;
  // All nullable — a draft is always partial
}
```

**New file: `lib/features/friends/providers/friend_form_draft_provider.dart`**
```dart
@riverpod
class FriendFormDraftNotifier extends _$FriendFormDraftNotifier {
  @override
  FriendFormDraft? build() => null; // null = no active draft

  void update(FriendFormDraft draft) => state = draft;
  void clear() => state = null;
}
```

**Modified: `lib/features/friends/presentation/friend_form_screen.dart`** (Phase 2)
- On `initState` equivalent: check `ref.read(friendFormDraftProvider)` — if non-null, pre-fill form fields and show "Resuming your draft" banner with a dismiss/discard option
- Each field `onChanged` callback: debounced 300ms → calls `ref.read(friendFormDraftProvider.notifier).update(...)` with current form state
- On successful save: calls `ref.read(friendFormDraftProvider.notifier).clear()`
- On explicit discard: calls `.clear()` and pops screen

### Draft Lifecycle

```
User opens FriendFormScreen (new or edit)
  → DraftNotifier state is null?  → Nothing shown, blank form
  → DraftNotifier state is non-null? → Pre-fill + "Resuming draft" banner

User types in any field
  → 300ms debounce fires
  → DraftNotifier.update(currentFormState)

User taps "Save" (valid form)
  → FriendRepository.save(friend)  ← existing path unchanged
  → DraftNotifier.clear()

User taps "Discard"
  → DraftNotifier.clear()
  → Navigator pops

User switches apps / app backgrounded
  → Riverpod state preserved in RAM (WidgetRef still alive)
  → On return: form still pre-filled (AppLifecycle.resumed triggers no special draft logic)

Android kills the process (memory pressure / device restart)
  → Riverpod state lost — intentional, as per Q5 decision
  → On next open: blank form, no draft banner
```

### No Debouncer Utility Needed

The 300ms debounce is implemented inline in `FriendFormScreen` using Flutter's standard `Timer` pattern. No shared `Debouncer` utility class is introduced — this is the only use case (avoids over-engineering per project implementation discipline).

---

## New Directory Structure Additions

The following files are added to the Phase 1 directory tree:

```
lib/
  core/
    ai/                                     ← NEW module
      llm_inference_service.dart
      model_manager.dart
      ai_capability_checker.dart
      prompt_templates.dart
      greeting_service.dart
  features/
    drafts/                                 ← NEW feature
      domain/
        draft_message.dart
      data/
        llm_message_repository.dart
      providers/
        draft_providers.dart
        draft_providers.g.dart
      presentation/
        draft_message_sheet.dart
        model_download_screen.dart
    friends/
      domain/
        friend_form_draft.dart              ← NEW file (existing module)
      providers/
        friend_form_draft_provider.dart     ← NEW file (existing module)
        friend_form_draft_provider.g.dart   ← generated
      presentation/
        friend_form_screen.dart             ← MODIFIED (draft pre-fill + debounce)
    daily_view/
      presentation/
        widgets/
          greeting_line_widget.dart         ← MODIFIED (LLM-reactive via greetingLineProvider)
    friends/ (friend card)
      presentation/
        friend_card_screen.dart             ← MODIFIED (adds "Suggest message" per event row)
```

**Total new files:** 13 new files, 3 modified existing files from Phase 1.

---

## Implementation Patterns — Phase 2 Additions

These patterns extend the Phase 1 enforcement rules without replacing any of them.

---

### LLM Inference Patterns

**Always run inference in a Dart Isolate — never on the main thread:**
```dart
// ✅ CORRECT
final result = await Isolate.run(() => _gemmaSession.generateResponse(prompt));

// ❌ WRONG — blocks UI thread
final result = await _gemmaSession.generateResponse(prompt);
```

**Always gate on ModelManager before showing LLM UI:**
```dart
// ✅ CORRECT
final modelState = ref.watch(modelManagerProvider);
return switch (modelState) {
  AsyncData(value: ModelDownloadState.ready) => SuggestMessageButton(...),
  AsyncData(value: ModelDownloadState.unsupported) => const SizedBox.shrink(),
  AsyncData(_) => DownloadModelPrompt(...),
  _ => const SizedBox.shrink(),
};

// ❌ WRONG — showing LLM UI without checking availability
return SuggestMessageButton(...);
```

**Prompts live exclusively in `prompt_templates.dart`:**
- No inline prompt strings in repositories or services
- `PromptTemplates` is the single auditable surface for all LLM input

**Inference timeout is mandatory:**
- All `infer()` calls have a 30-second `Future.timeout()`
- On timeout: caller receives an empty list; UI shows "Génération échouée — réessayer?" option

---

### Draft Form Patterns

**Draft state is Riverpod-only — no local state in the widget:**
```dart
// ✅ CORRECT
onChanged: (value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    ref.read(friendFormDraftProvider.notifier).update(_buildDraft());
  });
}

// ❌ WRONG — storing draft in widget setState
setState(() => _localDraft = value);
```

**Always clear draft on save or discard — never leave stale draft in state:**
- Save path: clear after `FriendRepository.save()` confirms success
- Discard path: clear before `context.pop()`
- Error path: do NOT clear on save failure — preserve draft so user doesn't lose work

---

### Enforcement Guidelines — Phase 2 Additions

All Phase 1 enforcement rules remain in force. Additionally:

**All AI agents MUST:**
9. Route ALL LLM inference through `LlmInferenceService` — never call `flutter_gemma` directly from a repository or widget
10. Check `ModelManager.isModelReady` before any LLM-powered UI element is rendered
11. Place ALL prompt strings in `PromptTemplates` — no inline prompts anywhere else
12. Use `Isolate.run()` for all `LlmInferenceService.infer()` calls
13. Clear `FriendFormDraftNotifier` state on successful save AND on explicit discard

**Anti-patterns (forbidden — Phase 2 additions):**
- Calling `flutter_gemma` API directly outside `LlmInferenceService`
- Storing `LlmInferenceService` results in SQLite (inference output is session-only)
- Calling `infer()` without a `Future.timeout()` guard
- Showing LLM suggestion UI on devices where `AiCapabilityChecker.isDeviceSupported()` returns false
- Adding any network call inside `LlmInferenceService` (inference must be air-gapped)

---

## Validation

### Requirements Coverage

| Requirement | Covered by |
|---|---|
| FR44 — draft message on friend card | `DraftMessageSheet` + `DraftMessageNotifier` |
| FR45 — ≥3 LLM variants | `LlmMessageRepository.generateSuggestions()` + prompt template |
| FR46 — on-device, explicit action only | `LlmInferenceService` (no network) + explicit tap gate |
| FR47 — edit/save/discard variant | `DraftMessageSheet` edit field + discard button |
| UC1 — greeting line | `GreetingService` + static fallback pool |
| NFR18 — no remote transmission | inference entirely within `Isolate.run()` + no network call in `LlmInferenceService` |
| NFR19 — no INTERNET for inference | `INTERNET` used only for model download; inference offline-capable |
| NFR20 — model ≤ 4 GB | Gemma-3n-E2B-it INT4 ≈ 2 GB — within constraint |
| NFR21 — explicit trigger only | Both UC1 (view load, not background) and UC2 (user tap) comply |
| Q4 draft surface (form only) | `FriendFormDraftNotifier` scoped to `FriendFormScreen` only |
| Q5 draft lifetime (session-only) | Riverpod in-memory state; no Drift table |

### Coherence Check

| Concern | Status |
|---|---|
| `flutter_gemma` compatible with Flutter 3.41.2 / Android API 26+ | ✅ |
| LLM module imports Phase 1 `FriendRepository` (read-only) | ✅ — allowed; `lib/core/ai/` may import repositories via Riverpod injection |
| `ContactActionService` reused for WhatsApp/SMS send after suggestion | ✅ — zero duplication |
| Draft module does NOT introduce new Drift schema | ✅ — session-only in-memory |
| INTERNET permission already granted by Phase 2 WebDAV work | ✅ — no new permission category |
| Zero third-party analytics or telemetry SDKs added | ✅ — `flutter_gemma` is offline-only |
| `DraftMessage` not encrypted (in-memory only) | ✅ — consistent with NFR6 scope (field encryption for persisted PII only) |

### Gap Analysis

**Critical gaps:** None.

**Known risks:**

| Risk | Mitigation |
|---|---|
| `flutter_gemma` API surface may change between now and Phase 2 implementation | `LlmInferenceService` is the single adapter — only one file to update if API changes |
| Gemma-3n-E2B-it prompt quality for French message generation | Prompt templates in `PromptTemplates` are centralized — easy to iterate without touching architecture |
| Model download failure (network interruption) | `ModelManager` state machine includes `error` state → retry button in `ModelDownloadScreen` |
| Low-RAM devices failing mid-inference | 30-second timeout in `LlmInferenceService` + empty-list fallback + "Génération échouée" UI |

---

## Implementation Handoff — Phase 2 LLM + Drafts

**AI Agent Guidelines (Phase 2 additions):**
- `lib/core/ai/` is infrastructure — it has no knowledge of features, same contract as `lib/core/encryption/`
- `lib/features/drafts/` owns the presentation and session state for LLM message suggestions — it does not own the inference engine
- `GreetingService` is the only component allowed to call `LlmInferenceService` for greeting generation — daily view widgets do not call it directly
- `FriendFormDraftNotifier` is scoped to the friend card form context only — do not reuse it for any other form
- The debounce timer in `FriendFormScreen` is a `Timer?` field on the widget's `State` — dispose it in `dispose()` to prevent memory leaks

**Implementation sequence recommendation:**
1. `AiCapabilityChecker` + `ModelManager` (state machine + download UI) — gates everything else
2. `LlmInferenceService` (Isolate wrapper around `flutter_gemma`) — core inference plumbing
3. `PromptTemplates` (prompt design + testing in isolation against model)
4. `GreetingService` + `GreetingLineWidget` update (UC1)
5. `LlmMessageRepository` + `DraftMessageNotifier` + `DraftMessageSheet` (UC2)
6. `FriendFormDraftNotifier` + `FriendFormScreen` debounce (draft UX)

---

_This addendum is authoritative for Phase 2 LLM and draft-storage implementation. All Phase 1 architecture decisions in [architecture.md](_bmad-output/planning-artifacts/architecture.md) remain binding and unchanged._
