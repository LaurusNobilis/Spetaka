# Story P2-Security: HuggingFace Token — User-Provided, Secure Storage

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Laurus,
I want to enter my own personal HuggingFace token once when I first set up the AI model download,
so that the app never embeds any third-party credentials in its binary and complies with Play Store developer policies and the Gemma model license terms.

## Context & Rationale

**Security / Compliance trigger (2026-03-29):**

The current implementation reads the HF token from `String.fromEnvironment('SPETAKA_HF_TOKEN')` in two places:
- `lib/main.dart` — passed to `FlutterGemma.initialize(huggingFaceToken: ...)`
- `lib/core/ai/model_manager.dart:69` — `static const String _huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');` used in `_defaultInstallManagedModel()`

This creates two hard violations:

1. **Play Store Developer Policy**: Embedding credentials (tokens, API keys) in an app binary is a policy violation and grounds for removal from the store.
2. **Gemma / HuggingFace license**: The Gemma model Terms of Service require each individual user to accept the license — a single embedded developer token would let all users download the model under one developer account, circumventing the per-user acceptance requirement.

**Solution chosen (Option C from architecture analysis):**
Each user enters their own HF token in a minimal setup step inside `ModelDownloadScreen` the first time they initiate a model download. The token is stored in `flutter_secure_storage` (Android Keystore / iOS Keychain backing), never in `shared_preferences`, Drift, or the app binary.

**Scope (as defined in sprint-status.yaml):**
> `HfTokenService` (~30 lines) + `needsToken` step in `ModelDownloadScreen` + 1 line `ModelManager`

None of stories 10.2, 10.3, 10.4, 10.5, 10.6 are functionally modified. The LLM feature surface is unchanged.

## Acceptance Criteria

### AC1 — `flutter_secure_storage` added to `pubspec.yaml`

**Given** the story is implemented
**When** `flutter pub get` runs
**Then** `flutter_secure_storage: ^9.0.0` is present in `dependencies` (not `dev_dependencies`)
**And** `flutter pub get` completes without conflicts
**And** `flutter analyze` reports no issues on the changed files

### AC2 — `HfTokenService` created

**Given** `lib/core/ai/hf_token_service.dart` is created
**Then** it exposes exactly three public methods:
  - `Future<String?> getToken()` — reads key `spetaka_hf_token` from `FlutterSecureStorage`
  - `Future<void> saveToken(String token)` — writes the token; `token` must be non-empty (assert or ArgumentError)
  - `Future<void> clearToken()` — deletes the key
**And** the constructor accepts an optional `FlutterSecureStorage? storage` parameter for testability
**And** the default storage instance uses `const FlutterSecureStorage()` (Android options default = Keystore, iOS = Keychain)
**And** the file is ~30 lines — no over-engineering, no Riverpod provider needed in this file (it is instantiated directly where used)

### AC3 — `ModelManager` no longer uses `String.fromEnvironment`

**Given** `lib/core/ai/model_manager.dart` is updated
**Then** the line `static const String _huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');` is removed entirely
**And** in `_defaultInstallManagedModel`, the `token:` argument to `.fromNetwork(...)` becomes:
  ```dart
  token: await HfTokenService().getToken(),
  ```
  (creates a short-lived transient `HfTokenService` instance — acceptable since it is just a thin wrapper over `FlutterSecureStorage`)
**And** no other changes are made to `ModelManager` — state machine, constructor, other methods are untouched
**And** existing `test/unit/ai/model_manager_test.dart` passes without modification (tests inject `installManagedModel` directly, bypassing `_defaultInstallManagedModel`)

### AC4 — `main.dart` uses `HfTokenService` at startup

**Given** `lib/main.dart` is updated
**Then** `const huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');` is removed
**And** the token passed to `FlutterGemma.initialize(huggingFaceToken: ...)` is read at runtime:
  ```dart
  final hfToken = await HfTokenService().getToken();
  await FlutterGemma.initialize(huggingFaceToken: hfToken);
  ```
**And** `WidgetsFlutterBinding.ensureInitialized()` already precedes this call (existing — no change needed)
**And** if no token is stored yet (fresh install), `hfToken` is `null` — `FlutterGemma.initialize` receives `null`, which is valid (no crash; download will require token entry via AC5)

### AC5 — `ModelDownloadScreen` adds `needsToken` step before first download

**Given** `lib/features/drafts/presentation/model_download_screen.dart` is updated
**Then** it is converted from `ConsumerWidget` to `ConsumerStatefulWidget` / `_ModelDownloadScreenState extends ConsumerState`
**And** the state holds:
  - `bool _awaitingTokenEntry = false`
  - `final _tokenController = TextEditingController()` (disposed in `dispose()`)
  - `String? _tokenError` (inline validation error message)

**Given** `ModelDownloadState` is `ModelDownloadIdle` AND `_awaitingTokenEntry == false`
**When** the user taps "Download model"
**Then** `HfTokenService().getToken()` is awaited:
  - If token is already stored → `notifier.startDownload()` is called immediately (existing flow — no change visible to user)
  - If no token stored → `setState(() => _awaitingTokenEntry = true)` — token entry UI is shown

**Given** `_awaitingTokenEntry == true`
**Then** the body area below the storage-requirement text shows the `_TokenEntryContent` widget:
  - Explanatory text (1–2 sentences): what the HF token is and where to get it
  - A URL hint pointing to `https://huggingface.co/settings/tokens` (plain text — not tappable; `url_launcher` is already in pubspec but not required for this minimal step)
  - A `TextField` with `_tokenController`, `obscureText: true`, label: `l10n.hfTokenFieldLabel`, `textInputAction: TextInputAction.done`
  - If `_tokenError != null`: display error message in red below the field (standard `InputDecoration.errorText`)
  - A full-width, 48dp "Save & Download" `FilledButton`

**Given** the user taps "Save & Download"
**When** `_tokenController.text.trim()` is empty
**Then** `setState(() => _tokenError = l10n.hfTokenErrorEmpty)` — no network call

**Given** the user taps "Save & Download"
**When** `_tokenController.text.trim()` is non-empty
**Then** `await HfTokenService().saveToken(_tokenController.text.trim())` is called
**And** `setState(() { _awaitingTokenEntry = false; _tokenError = null; })`
**And** `notifier.startDownload()` is called immediately after
**And** the screen transitions to the standard `ModelDownloading` state (progress bar)

**Given** the token entry UI is visible
**And** the `ModelDownloadState` changes (e.g. error from a prior attempt)
**Then** `_awaitingTokenEntry` state is handled gracefully — `_buildStateContent` switch remains driven by `ModelDownloadState`; `_awaitingTokenEntry` only gates the path inside `ModelDownloadIdle`

**Accessibility:**
- Token field TalkBack label: `l10n.hfTokenFieldLabel`
- "Save & Download" button TalkBack label: derived from text (default Flutter behavior — no extra Semantics needed)
- Touch target: 48dp FilledButton (existing pattern)

### AC6 — `String.fromEnvironment('SPETAKA_HF_TOKEN')` fully eliminated

**Given** the story is complete
**Then** `grep -r 'SPETAKA_HF_TOKEN' lib/` returns zero matches
**And** no CI `--dart-define=SPETAKA_HF_TOKEN` flags appear in `_bmad-output/implementation-artifacts/1-6-github-actions-ci-cd-pipeline.md` or any other workflow file (if they exist, remove them)
**And** `flutter analyze lib/` reports zero issues

### AC7 — Unit tests for `HfTokenService`

**Given** `test/unit/ai/hf_token_service_test.dart` is created
**Then** it contains a mock for `FlutterSecureStorage` (use `package:mockito` or hand-written fake — see existing patterns in `test/unit/ai/`)
**And** covers:
  1. `getToken()` returns `null` when storage has no value for `spetaka_hf_token`
  2. `saveToken('my-token')` + `getToken()` returns `'my-token'`
  3. `clearToken()` after `saveToken` → `getToken()` returns `null`
  4. `saveToken('')` throws `ArgumentError` (or asserts — match whichever AC2 implements)
**And** `flutter test test/unit/ai/hf_token_service_test.dart` passes

### AC8 — Existing tests unaffected

**Given** the story is implemented
**Then** `flutter test test/unit/ai/model_manager_test.dart` passes without modification
**And** `flutter test` (full suite) passes (or any pre-existing failures are not caused by this story)

## Tasks / Subtasks

- [x] Task 1: Add `flutter_secure_storage` dependency (AC1)
  - [x] 1.1 Add `flutter_secure_storage: ^9.0.0` to `dependencies` in `pubspec.yaml`
  - [x] 1.2 Run `flutter pub get` — verify no conflicts
  - [x] 1.3 Run `flutter analyze lib/` — verify clean

- [x] Task 2: Create `HfTokenService` (AC2)
  - [x] 2.1 Create `lib/core/ai/hf_token_service.dart` with `getToken()`, `saveToken()`, `clearToken()`
  - [x] 2.2 Constructor accepts optional `FlutterSecureStorage? storage` for testability
  - [x] 2.3 Validate: token must be non-empty in `saveToken()` (ArgumentError)

- [x] Task 3: Update `ModelManager` (AC3)
  - [x] 3.1 Remove `static const String _huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');`
  - [x] 3.2 Replace `token: _huggingFaceToken.isEmpty ? null : _huggingFaceToken` with `token: await const HfTokenService().getToken()` in `_defaultInstallManagedModel`
  - [x] 3.3 Verify existing `model_manager_test.dart` still passes

- [x] Task 4: Update `main.dart` (AC4)
  - [x] 4.1 Remove `const huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');`
  - [x] 4.2 Replace with `final hfToken = await const HfTokenService().getToken();`
  - [x] 4.3 Pass `hfToken` to `FlutterGemma.initialize(huggingFaceToken: hfToken);`

- [x] Task 5: Update `ModelDownloadScreen` — add `needsToken` step (AC5)
  - [x] 5.1 Convert to `ConsumerStatefulWidget`; add `_awaitingTokenEntry`, `_tokenController`, `_tokenError` state fields
  - [x] 5.2 `dispose()`: call `_tokenController.dispose()`
  - [x] 5.3 In `_IdleContent` callback path: check stored token before calling `startDownload()`
  - [x] 5.4 Create `_TokenEntryContent` private widget or inline block: explainer text, URL hint, obscured TextField, "Save & Download" FilledButton, error message
  - [x] 5.5 Wire up token save → `notifier.startDownload()` flow
  - [x] 5.6 Add l10n keys (see Dev Notes §L10n below)

- [x] Task 6: Add i18n strings (AC5)
  - [x] 6.1 Add to `lib/l10n/app_en.arb` (see keys in Dev Notes §L10n)
  - [x] 6.2 Add to `lib/l10n/app_fr.arb`
  - [x] 6.3 Run `flutter pub get` to re-generate `l10n` — or it auto-generates on build

- [x] Task 7: Eliminate all `SPETAKA_HF_TOKEN` references (AC6)
  - [x] 7.1 Run `grep -r 'SPETAKA_HF_TOKEN' .` (from `spetaka/`) — must return zero results
  - [x] 7.2 Check CI pipeline file if `--dart-define` flag exists; remove it

- [x] Task 8: Write unit tests for `HfTokenService` (AC7)
  - [x] 8.1 Create `test/unit/ai/hf_token_service_test.dart`
  - [x] 8.2 Implement mock `FlutterSecureStorage` (in-memory fake is simplest)
  - [x] 8.3 Cover all 4 test cases in AC7
  - [x] 8.4 Run `flutter test test/unit/ai/hf_token_service_test.dart` — all pass

## Dev Notes

### Architecture Overview

```
lib/core/ai/
├── ai_capability_checker.dart     (Story 10.1 — untouched)
├── hf_token_service.dart          ← NEW (this story)
├── llm_inference_service.dart     (untouched)
├── model_manager.dart             ← MODIFY: remove _huggingFaceToken const, 1-line change
├── model_manager.g.dart           (generated — untouched)
├── prompt_templates.dart          (untouched)
└── greeting_service.dart          (untouched)

lib/features/drafts/presentation/
└── model_download_screen.dart     ← MODIFY: ConsumerStatefulWidget + token entry step

lib/main.dart                      ← MODIFY: HfTokenService().getToken() at startup
pubspec.yaml                       ← MODIFY: add flutter_secure_storage
test/unit/ai/
└── hf_token_service_test.dart     ← NEW
```

### `HfTokenService` — Reference Implementation (~30 lines)

```dart
// lib/core/ai/hf_token_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's HuggingFace access token in the device's secure keystore.
///
/// Android: Android Keystore (API 23+ — our minSdk = 26, so always available).
/// iOS: Keychain.
///
/// The token is NEVER embedded in the binary. Each user provides their own.
class HfTokenService {
  const HfTokenService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'spetaka_hf_token';

  final FlutterSecureStorage _storage;

  Future<String?> getToken() => _storage.read(key: _key);

  Future<void> saveToken(String token) {
    if (token.isEmpty) throw ArgumentError.value(token, 'token', 'must not be empty');
    return _storage.write(key: _key, value: token);
  }

  Future<void> clearToken() => _storage.delete(key: _key);
}
```

### `ModelManager` — Exact Change

**File**: `lib/core/ai/model_manager.dart`

Remove (line ~68–69):
```dart
  static const String _huggingFaceToken =
      String.fromEnvironment('SPETAKA_HF_TOKEN');
```

In `_defaultInstallManagedModel` (line ~241), replace:
```dart
      token: _huggingFaceToken.isEmpty ? null : _huggingFaceToken,
```
with:
```dart
      token: await HfTokenService().getToken(),
```

Add import at top of file:
```dart
import 'hf_token_service.dart';
```

That is exactly the "1 ligne ModelManager" change referenced in the sprint backlog note.

### `main.dart` — Exact Change

Replace:
```dart
  const huggingFaceToken = String.fromEnvironment('SPETAKA_HF_TOKEN');
  await FlutterGemma.initialize(
    huggingFaceToken: huggingFaceToken.isEmpty ? null : huggingFaceToken,
  );
```
with:
```dart
  final hfToken = await HfTokenService().getToken();
  await FlutterGemma.initialize(huggingFaceToken: hfToken);
```
Add import: `import 'core/ai/hf_token_service.dart';`

`WidgetsFlutterBinding.ensureInitialized()` is already the first call in `main()` (existing) — the `await HfTokenService().getToken()` is safe.

### `ModelDownloadScreen` — Structural Change

The screen must be converted to `ConsumerStatefulWidget` to hold local token-entry UI state.

**Key design decisions:**
- `_awaitingTokenEntry` is a local bool, NOT a new `ModelDownloadState` variant — the state machine in `ModelManager` is unchanged
- The `_buildStateContent` switch is still driven by `ModelDownloadState`; `_awaitingTokenEntry` is an overlay that activates only when `state is ModelDownloadIdle`
- `_TokenEntryContent` can be a private `StatelessWidget` in the same file receiving callbacks

**`_buildStateContent` modification:**
```dart
// Inside _ModelDownloadScreenState:
Widget _buildStateContent(...) {
  return switch (state) {
    ModelDownloadIdle() => _awaitingTokenEntry
        ? _TokenEntryContent(
            controller: _tokenController,
            errorText: _tokenError,
            onSaveAndDownload: _saveTokenAndStartDownload,
          )
        : _IdleContent(
            l10n: l10n,
            onDownload: _onDownloadPressed,  // ← new async handler
          ),
    ModelDownloading(:final progress) => _DownloadingContent(...),
    ModelReady() => _ReadyContent(...),
    ModelDownloadError(:final message) => _ErrorContent(...),
  };
}

Future<void> _onDownloadPressed() async {
  final token = await HfTokenService().getToken();
  if (token != null && token.isNotEmpty) {
    ref.read(modelManagerProvider.notifier).startDownload();
  } else {
    setState(() => _awaitingTokenEntry = true);
  }
}

Future<void> _saveTokenAndStartDownload() async {
  final raw = _tokenController.text.trim();
  if (raw.isEmpty) {
    setState(() => _tokenError = context.l10n.hfTokenErrorEmpty);
    return;
  }
  await HfTokenService().saveToken(raw);
  setState(() { _awaitingTokenEntry = false; _tokenError = null; });
  ref.read(modelManagerProvider.notifier).startDownload();
}
```

**Important**: `_IdleContent.onDownload` was `VoidCallback` — change its type to `VoidCallback` but wire through a sync wrapper calling the `async` method (Fire-and-forget pattern already used in this codebase: `onPressed: () => _onDownloadPressed()` with async method; Flutter OK with this).

### L10n Keys Required

Add to `lib/l10n/app_en.arb`:
```json
"hfTokenSectionTitle": "HuggingFace Access Token",
"@hfTokenSectionTitle": { "description": "Section heading in ModelDownloadScreen for token entry" },
"hfTokenExplainer": "To download the AI model, you need a free HuggingFace account token. Visit huggingface.co/settings/tokens to generate one (read-only access is sufficient).",
"@hfTokenExplainer": { "description": "Explanation text shown when user needs to enter their HF token" },
"hfTokenFieldLabel": "HuggingFace token",
"@hfTokenFieldLabel": { "description": "Label for the HuggingFace token text field" },
"hfTokenSaveAndDownload": "Save & Download",
"@hfTokenSaveAndDownload": { "description": "Button that saves the HF token and starts model download" },
"hfTokenErrorEmpty": "Please enter your HuggingFace token before downloading.",
"@hfTokenErrorEmpty": { "description": "Validation error when token field is empty" }
```

Add corresponding French translations to `lib/l10n/app_fr.arb`:
```json
"hfTokenSectionTitle": "Token d'accès HuggingFace",
"hfTokenExplainer": "Pour télécharger le modèle IA, vous avez besoin d'un token HuggingFace (compte gratuit). Rendez-vous sur huggingface.co/settings/tokens pour en générer un (accès lecture seule suffisant).",
"hfTokenFieldLabel": "Token HuggingFace",
"hfTokenSaveAndDownload": "Enregistrer et télécharger",
"hfTokenErrorEmpty": "Veuillez saisir votre token HuggingFace avant de télécharger."
```

**Note on `@` annotation entries in `app_fr.arb`**: `app_fr.arb` does NOT include `@` metadata entries (only `app_en.arb` does). Add French strings without `@` blocks.

### Testing Pattern for `HfTokenService`

Use an in-memory fake for `FlutterSecureStorage` (same pattern as StorageService mocks elsewhere in the test suite):

```dart
// In-memory fake — no platform channel needed
class _FakeSecureStorage implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read({required String key, ...}) async => _store[key];

  @override
  Future<void> write({required String key, required String? value, ...}) async {
    if (value == null) { _store.remove(key); } else { _store[key] = value; }
  }

  @override
  Future<void> delete({required String key, ...}) async => _store.remove(key);

  // Other methods can throw UnimplementedError or return null
}
```

Check `lib/core/encryption/` or existing test fakes for similar patterns in the codebase.

### Key Constraints & Guardrails

1. **Do NOT create a Riverpod provider for `HfTokenService`** — it is instantiated transiently where needed. Over-engineering was explicitly excluded in the sprint note ("~30 lines").

2. **Do NOT change `ModelDownloadState`** — no new `ModelNeedsToken` state. The token-entry UI is local state in the `Screen` widget.

3. **Do NOT modify existing `ModelManagerNotifier.build()`** — the provider constructor chain is unchanged.

4. **Do NOT add a `tokenProvider` injectable to `ModelManager` constructor** — the "1 ligne" change means `_defaultInstallManagedModel` calls `HfTokenService().getToken()` inline. If the dev wants testability for that specific static method, the existing injection of `installManagedModel` callback already covers it in tests.

5. **`flutter_secure_storage` Android configuration**: With `minSdk = 26`, the default Android Keystore encryption is automatically selected by `flutter_secure_storage`. No `AndroidOptions` customization is needed.

6. **Do NOT add INTERNET or KEYSTORE permissions to `AndroidManifest.xml`** — `flutter_secure_storage` does not require extra permissions beyond what is already there; INTERNET is already present (Story 10.1).

7. **`build_runner` is NOT required** for this story — no new Riverpod providers, no new Drift tables.

8. **`ModelDownloadScreen` is located at** `lib/features/drafts/presentation/model_download_screen.dart` — the `drafts/` feature folder is correct (it was created for Story 10.1, which established the LLM infrastructure under that folder).

### Previous Story Learnings (10.6)

From the last story (10.6) and commit history:
- Pattern for small services in `lib/core/ai/`: minimal class, no Riverpod annotation if not needed
- `ConsumerStatefulWidget` pattern used elsewhere (e.g., `_PassphraseDialog`, `_PseudoSection` in `settings_screen.dart`)
- `TextEditingController` must be disposed in `dispose()` — enforce this
- `unawaited(...)` for fire-and-forget async calls (already imported via `dart:async`)
- Commits of 10.5/10.6 used `fix:` prefix for follow-up corrections — prefer `feat:` for this story

### Project Structure Notes

- **Alignment with feature-first architecture**: Security services live in `lib/core/` (not in a feature folder). `hf_token_service.dart` → `lib/core/ai/` is correct (AI infrastructure family).
- **No new Drift migration**: no `schemaVersion` bump, no `onUpgrade` changes. This story is pure Dart/platform-keystore.
- **No new routes**: `ModelDownloadScreen` already has its route `/model-download` in `app_router.dart`. No change needed.

### References

- Sprint backlog note: `_bmad-output/implementation-artifacts/sprint-status.yaml` → `phase-2-brainstorm-backlog.p2-llm-hf-token-user-provided-secure-storage`
- Current `main.dart` (lines 11–14): `String.fromEnvironment('SPETAKA_HF_TOKEN')` — to be removed
- Current `lib/core/ai/model_manager.dart` (lines 68–69 and ~241): token constant and usage — to be changed
- Current `lib/features/drafts/presentation/model_download_screen.dart`: `ModelDownloadScreen` — to be converted to stateful
- `flutter_secure_storage` pub.dev: [Source: pubspec.yaml — add ^9.0.0]
- Existing AI tests: `test/unit/ai/model_manager_test.dart` — must remain green (no modification)
- minSdk = 26: `spetaka/android/app/build.gradle:37` — Keystore backing guaranteed

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

- `flutter analyze lib/` → No issues found (all modified files clean)
- `flutter test test/unit/ai/hf_token_service_test.dart` → 7/7 passed
- `flutter test test/unit/ai/model_manager_test.dart` → 9/9 passed (no regression)
- `flutter test` (full suite) → 576/576 passed (zero regressions)
- `grep -r 'SPETAKA_HF_TOKEN' lib/` → zero matches (AC6 PASS)
- `grep -r 'SPETAKA_HF_TOKEN' .github/workflows/` → zero matches (CI cleaned)

### Completion Notes List

- AC1: `flutter_secure_storage: ^9.0.0` added to pubspec.yaml; `flutter pub get` successful; generated l10n files auto-updated on pub get
- AC2: `lib/core/ai/hf_token_service.dart` created (~26 lines). Constructor uses `const` to allow `const HfTokenService()` at callsites. `saveToken('')` throws `ArgumentError`. Storage key: `spetaka_hf_token`
- AC3: `ModelManager` — removed `_huggingFaceToken` static const; replaced token usage with `await const HfTokenService().getToken()`. Added `import 'hf_token_service.dart'`. All 9 `model_manager_test.dart` tests still pass
- AC4: `main.dart` — replaced `String.fromEnvironment` block with `final hfToken = await const HfTokenService().getToken()`. No crash on null (fresh install)
- AC5: `ModelDownloadScreen` converted from `ConsumerWidget` to `ConsumerStatefulWidget`. New `_awaitingTokenEntry` bool gates token entry UI inside `ModelDownloadIdle` branch. `_TokenEntryContent` private widget: explainer, URL hint, obscured TextField, "Save & Download" FilledButton, inline error. Fire-and-forget async pattern via `unawaited()` for `onPressed` callbacks
- AC6: Zero `SPETAKA_HF_TOKEN` occurrences in `lib/` and `.github/workflows/ci.yml`. `docs/release-process.md` updated to remove `--dart-define` instructions and document the new user-provided token flow
- AC7: `test/unit/ai/hf_token_service_test.dart` — 7 tests. Uses `TestFlutterSecureStoragePlatform` (official in-memory test helper provided by `flutter_secure_storage`) via `FlutterSecureStoragePlatform.instance` injection. Covers all 4 AC7 cases + bonus edge cases
- AC8: Full `flutter test` suite — 576 tests, 0 failures, 0 regressions

### File List

- `spetaka/pubspec.yaml` (modified — added flutter_secure_storage: ^9.0.0)
- `spetaka/pubspec.lock` (modified — auto-updated by flutter pub get)
- `spetaka/lib/core/ai/hf_token_service.dart` (new)
- `spetaka/lib/core/ai/model_manager.dart` (modified — removed _huggingFaceToken const, added HfTokenService import, updated token in _defaultInstallManagedModel)
- `spetaka/lib/main.dart` (modified — replaced String.fromEnvironment with HfTokenService().getToken())
- `spetaka/lib/features/drafts/presentation/model_download_screen.dart` (modified — ConsumerStatefulWidget, token entry step, _TokenEntryContent widget)
- `spetaka/lib/l10n/app_en.arb` (modified — added 5 hfToken* keys)
- `spetaka/lib/l10n/app_fr.arb` (modified — added 5 hfToken* French translations)
- `spetaka/lib/core/l10n/app_localizations.dart` (modified — 5 new abstract getters, auto-generated)
- `spetaka/lib/core/l10n/app_localizations_en.dart` (modified — 5 new English implementations, auto-generated)
- `spetaka/lib/core/l10n/app_localizations_fr.dart` (modified — 5 new French implementations, auto-generated)
- `spetaka/test/unit/ai/hf_token_service_test.dart` (new)
- `.github/workflows/ci.yml` (modified — removed --dart-define=SPETAKA_HF_TOKEN from APK and AAB build steps)
- `docs/release-process.md` (modified — removed SPETAKA_HF_TOKEN secret row and --dart-define build instructions; documented user-provided token approach)

### Change Log

- 2026-03-30: Implemented p2-llm-hf-token story — HuggingFace token is now user-provided and stored in Android Keystore / iOS Keychain via flutter_secure_storage. `SPETAKA_HF_TOKEN` fully eliminated from binary and CI. `ModelDownloadScreen` adds token entry step on first download. 576 tests pass.
