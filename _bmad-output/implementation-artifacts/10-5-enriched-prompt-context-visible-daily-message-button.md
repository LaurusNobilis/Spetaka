# Story 10.5: Enriched Prompt + Context Header + "✦ Message" Button in Daily View

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Laurus,
I want the LLM message suggestions to leverage the event comment as a tonal modifier, to see the full event context while I choose a variant in `DraftMessageSheet`, and to launch the suggestion directly from the Daily View action row,
so that each suggestion feels tuned to the real emotional weight of the moment, and I can reach it without navigating away from my daily list.

## Context & Rationale

Derived from brainstorming session 2026-03-30 — ideas P2-A, P2-B, P2-C (all "Phase 2 — faisable maintenant").

**Bob's recommendation (SM):** Start Story 10.5 first. It is the highest-impact change (every suggestion call benefits), it is fully self-contained (Story 10.2 infra done, no dependency on 10.6), and it delivers a visible UX win in the Daily View. Story 10.6 (UserVoiceProfile) can wait for 10.5 to be done so the team benefits from real-usage feedback on the prompt quality before designing the learning layer.

**Three bundled improvements (P2-A + P2-B + P2-C):**
- **P2-A — Prompt dynamique :** `PromptTemplates.messageSuggestion()` calcule un `eventTone` en combinant le type d'événement ET le commentaire libre. Un anniversaire sans commentaire → festif. Un anniversaire avec commentaire "a perdu son père il y a 3 mois" → douceur, no blague.
- **P2-B — Contexte visible dans DraftMessageSheet :** Le header affiche `[type d'événement] · [date relative] · "[commentaire]"` si un commentaire existe — l'utilisateur voit exactement pourquoi il écrit pendant qu'il choisit une variante.
- **P2-C — 4e bouton "✦ Message" dans la rangée Actions de la Daily View :** `[📞 Appeler] [💬 SMS] [🟢 WA] [✦ Message]` — un tap ouvre directement `DraftMessageSheet` avec l'événement actif pré-chargé, zéro navigation supplémentaire.

## Acceptance Criteria

### AC1 — Prompt enrichi : commentaire agit comme modificateur de tonalité (P2-A)
**Given** `PromptTemplates.messageSuggestion()` is called with `eventNote` non-null and non-empty
**When** the prompt is constructed
**Then** the system-instruction section includes a `contextHint` line derived from both `eventType` AND `eventNote` — not just a concatenation, but a semantic modifier framing the emotional register:
  - If `eventNote` is null or empty → prompt uses `eventType` alone, no change from current behavior
  - If `eventNote` is non-null → prompt prepends an instruction: `"Contexte important : [eventNote]. Adapte le ton de tes messages en conséquence."`
**And** the three generated variants reflect the emotional weight of the comment (LLM-determined)
**And** no regression to existing behavior when `eventNote` is absent

### AC2 — Header enrichi dans DraftMessageSheet : commentaire visible (P2-B)
**Given** `DraftMessageSheet` opens for an event WITH a non-null, non-empty `event.comment`
**When** the sheet is in `AsyncData` or `AsyncError` state
**Then** the event context header (currently `"Pour [name] — [type] [date relative]"`) is extended to append `· "[commentaire]"` beneath or inline:
  - Layout: two-line header — line 1: `"Pour [name] — [type] [date relative]"` ; line 2 (if comment): `"✎ [commentaire]"` in `bodySmall` onSurfaceVariant style
  - The comment is displayed verbatim (truncated at 80 chars with `…` if longer)
**And** when `event.comment` is null or empty → header renders exactly as before (single line), no change

### AC3 — 4e bouton "✦ Message" dans la rangée action de la Daily View (P2-C)
**Given** `ModelManager.isModelReady = true` AND `AiCapabilityChecker.isSupported() = true`
**Given** Laurus is on `DailyViewScreen`, a friend card is expanded (`_ExpandedContent`)
**When** the action row renders
**Then** a 4th `_ActionButton` appears to the right of WhatsApp: icon `Icons.auto_awesome_outlined`, label `context.l10n.suggestMessageDailyAction` (e.g. `"Message IA"`)
**And** the 4 buttons share the horizontal space evenly (no overflow on typical screens — 4 × icon+label layout)

**Given** Laurus taps the "✦ Message" button
**When** the tap is handled
**Then** `showDraftMessageSheet(context: context, ref: ref, friendId: friend.id, event: trigger_event)` is called, where `trigger_event` is the nearest unacknowledged in-window event for this friend (the same event that caused this card to surface — `entry.prioritized.daysUntilNextEvent` nearest match from `eventsByFriend`)
**And** the `DraftMessageSheet` opens pre-filled with that event's type AND comment already injected into the prompt

**Given** `AiCapabilityChecker.isSupported() = false` OR the LLM gate is not ready
**Then** the "✦ Message" button is hidden entirely (same `LlmFeatureGuard` logic as `FriendCardScreen`) — the action row shows only 3 buttons, unchanged

### AC4 — Nearest trigger event resolution for Daily View button
**Given** the Daily View exposes `DailyViewEntry` per friend card
**When** the "✦ Message" button is tapped for a friend
**Then** the `event` passed to `showDraftMessageSheet` is the **nearest unacknowledged in-window event** for that friend
**And** this event is derived from `entry.prioritized.daysUntilNextEvent` — the engine already computes the nearest event; the dev must pass the matching `Event` DB record, not a stub
**And** if no event is found (edge case), the button is hidden (same `SizedBox.shrink()` as unsupported gate)

### AC5 — DailyViewEntry carries the trigger Event record
**Given** `DailyViewEntry` currently has `friend`, `prioritized`, `nextEventLabel`
**When** Story 10.5 is implemented
**Then** `DailyViewEntry` gains a new optional field: `Event? nearestEvent` — the Drift `Event` record for the nearest unacknowledged in-window event
**And** `buildDailyView` in `daily_view_provider.dart` populates `nearestEvent` using the same `unack.first` logic already used for `nextEventLabel` (the lists are already sorted by proximity)
**And** no breaking change to existing widgets consuming `DailyViewEntry` (field is nullable)

### AC6 — No new Drift table, no schema migration
**Given** this story
**Then** zero new Drift tables are created; `schemaVersion` remains at 9; no `build_runner` drift step needed beyond the existing `.g.dart` regeneration for Riverpod

### AC7 — Accessibility and touch targets
**Given** the new "✦ Message" `_ActionButton` in Daily View
**Then** it meets 48×48dp minimum touch target (NFR15)
**And** TalkBack semantic label: `context.l10n.suggestMessageDailySemantics` (e.g. `"Compose un message suggéré par le LLM pour [nom]"`)

**Given** the enriched header in DraftMessageSheet
**Then** the comment line uses `Semantics(label: 'Contexte : [commentaire]')` for TalkBack

## Tasks / Subtasks

- [x] **Task 1 — Enrich `PromptTemplates.messageSuggestion()` with tonal modifier (AC: 1)**
  - [x] Open `lib/core/ai/prompt_templates.dart`
  - [x] Update `messageSuggestion()` body: add a `contextHint` local variable:
    ```dart
    static String messageSuggestion({
      required String friendName,
      required String eventType,
      String? eventNote,
      String language = 'fr',
    }) {
      final eventContext = eventNote != null && eventNote.isNotEmpty
          ? '$eventType — $eventNote'
          : eventType;
      final toneInstruction = eventNote != null && eventNote.isNotEmpty
          ? '\nContexte important : $eventNote. Adapte le ton de tes messages en conséquence.'
          : '';
      return '''Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.$toneInstruction
Génère 3 courts messages $language chaleureux pour $friendName à l'occasion de : $eventContext.
Les messages doivent être chaleureux, personnels, naturels, et adaptés à un envoi par $language.
Formate ta réponse comme une liste numérotée :
1. [premier message]
2. [deuxième message]
3. [troisième message]
Ne génère rien d'autre.''';
    }
    ```
  - [x] Signature is identical — no call-site change needed (all callers already pass `eventNote: event.comment`)
  - [x] Verify no test hardcodes the exact prompt string (unit tests use mocked `LlmInferenceService` — prompt content is not asserted)

- [x] **Task 2 — Extend `DraftMessageSheet` header to show the event comment (AC: 2, 7)**
  - [x] Open `lib/features/drafts/presentation/draft_message_sheet.dart`
  - [x] In `_DraftMessageSheetContentState._eventHeaderContext()` (currently returns `"${event.type} ${_asSentenceFragment(relativeDate)}"`): no change needed — this is the first line of the header
  - [x] Add a new helper `String? _eventCommentLine()` returning the event comment if non-null and non-empty, otherwise null
  - [x] In `_DataBody.build()`, after the existing `draftMessageEventHeader(...)` text widget, add:
    ```dart
    if (widget.event.comment != null && widget.event.comment!.isNotEmpty) ...[
      const SizedBox(height: 4),
      Semantics(
        label: 'Contexte : ${widget.event.comment}',
        child: Text(
          '✎ ${_truncate(widget.event.comment!, 80)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    ],
    ```
  - [x] **CRITICAL:** `_DataBody` is a `StatelessWidget` — it does NOT have access to `widget.event`. It receives the `DraftMessage draft` object. The event comment must either:
    - **Option A (preferred):** Pass `event.comment` through `_DataBody` as a new `String? eventComment` parameter, set in `_DraftMessageSheetContentState.build()` where `_DataBody` is constructed
    - **Option B:** Store the comment in `DraftMessage` domain model as an optional `eventComment` field (pure Dart no-persist, safe)
    - → Use **Option A**: add `String? eventComment` to `_DataBody` constructor and `const _DataBody({..., this.eventComment})`, then read it in build
  - [x] Same comment display in `_ErrorBody` (AC2 says "AsyncData or AsyncError state") — add identically
  - [x] Helper `String _truncate(String s, int maxChars)`: `s.length <= maxChars ? s : '${s.substring(0, maxChars)}…'`

- [x] **Task 3 — Extend `DailyViewEntry` with `nearestEvent` field (AC: 5)**
  - [x] Open `lib/features/daily/data/daily_view_provider.dart`
  - [x] Add field to `DailyViewEntry`:
    ```dart
    class DailyViewEntry {
      const DailyViewEntry({
        required this.friend,
        required this.prioritized,
        this.nextEventLabel,
        this.nearestEvent,        // NEW — Story 10.5
      });
      final Friend friend;
      final PrioritizedFriend prioritized;
      final String? nextEventLabel;
      final Event? nearestEvent;  // NEW — Story 10.5
    }
    ```
  - [x] In `buildDailyView`, the `unack.first` loop (lines ~175-185) already computes the nearest event for `nextEventLabelByFriend` — extract the `Event` record alongside the label:
    ```dart
    final nearestEventByFriend = <String, Event?>{};
    for (final entry in eventsByFriend.entries) {
      final unack = entry.value.where((e) => !e.isAcknowledged).toList();
      if (unack.isEmpty) continue;
      unack.sort((a, b) { ... });          // same sort as before
      nextEventLabelByFriend[entry.key] = unack.first.type;
      nearestEventByFriend[entry.key] = unack.first;  // NEW
    }
    ```
  - [x] Pass it in the DailyViewEntry constructor: `nearestEvent: nearestEventByFriend[p.friendId]`
  - [x] No breaking change — field is optional with a default of null

- [x] **Task 4 — Refactor `_ExpandedContent` to ConsumerStatefulWidget + add "✦ Message" button (AC: 3, 4, 7)**
  - [x] Open `lib/features/daily/presentation/daily_view_screen.dart`
  - [x] `_ExpandedContent` is currently a `StatefulWidget` (for `_actionError` state) — it does NOT watch Riverpod providers directly. To gate the new button behind `aiCapabilityCheckerProvider` + `modelManagerProvider`, convert it to `ConsumerStatefulWidget`:
    ```dart
    class _ExpandedContent extends ConsumerStatefulWidget { ... }
    class _ExpandedContentState extends ConsumerState<_ExpandedContent> { ... }
    ```
    All existing logic (`_handleCall`, `_handleSms`, `_handleWhatsApp`, `_actionError`) remains on the state unchanged. Only `build` gains `ref`.
  - [x] In state, add handler:
    ```dart
    Future<void> _handleSuggestMessage(BuildContext context) async {
      final event = widget.entry.nearestEvent;
      if (event == null) return;
      setState(() => _actionError = null);
      await showDraftMessageSheet(
        context: context,
        ref: ref,
        friendId: widget.entry.friend.id,
        event: event,
      );
    }
    ```
  - [x] Add import for `showDraftMessageSheet` from `lib/features/drafts/presentation/draft_message_sheet.dart` and `LlmFeatureGuard` imports
  - [x] In `build()`, gate the new button via `aiCapabilityCheckerProvider` + `modelManagerProvider` (replicate guard logic from `LlmFeatureGuard` inline — avoids widget-wrapping the button since we need conditional inclusion in a Row):
    ```dart
    final isLlmSupported = ref.watch(aiCapabilityCheckerProvider);
    final modelState = ref.watch(modelManagerProvider);
    final isModelReady = modelState is ModelReady;
    final showMessageButton = isLlmSupported && isModelReady && widget.entry.nearestEvent != null;
    ```
  - [x] In the action row `Row`, add the button conditionally:
    ```dart
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _ActionButton(key: Key('action_call_${friend.id}'), ...),
          _ActionButton(key: Key('action_sms_${friend.id}'), ...),
          _ActionButton(key: Key('action_wa_${friend.id}'), ...),
          if (showMessageButton)
            _ActionButton(
              key: Key('action_llm_${friend.id}'),
              icon: Icons.auto_awesome_outlined,
              label: context.l10n.suggestMessageDailyAction,
              onPressed: () => _handleSuggestMessage(context),
            ),
        ],
      ),
    ),
    ```
  - [x] Pass `context` to `_handleSuggestMessage` — `build(BuildContext context)` provides it normally
  - [x] **IMPORTANT:** `_ActionButton.onPressed` is `Future<void> Function()` — `_handleSuggestMessage(context)` must match this type. Use: `onPressed: () => _handleSuggestMessage(context)`

- [x] **Task 5 — Localization keys (AC: 3, 7)**
  - [x] Open `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`
  - [x] Add:
    ```json
    "suggestMessageDailyAction": "Message IA",
    "@suggestMessageDailyAction": { "description": "Label for the AI message suggestion button in daily view action row" },
    "suggestMessageDailySemantics": "Compose an AI-suggested message for {name}",
    "@suggestMessageDailySemantics": {
      "placeholders": { "name": { "type": "String" } }
    }
    ```
  - [x] FR: `"suggestMessageDailyAction": "✦ Message"`, `"suggestMessageDailySemantics": "Compose un message suggéré pour {name}"`
  - [x] Add abstract getters/methods to `lib/core/l10n/app_localizations.dart`
  - [x] Implement in `app_localizations_en.dart` and `app_localizations_fr.dart`
  - [x] Run `flutter gen-l10n` (or let it auto-run on build) to regenerate l10n classes

- [x] **Task 6 — Unit tests (AC: 1)**
  - [x] Open `test/unit/drafts/llm_message_repository_test.dart`
  - [x] Add a test group: `'PromptTemplates.messageSuggestion — tonal modifier'`
    - [x] Test: with `eventNote = null` → prompt does NOT contain `'Contexte important'`
    - [x] Test: with `eventNote = ''` → prompt does NOT contain `'Contexte important'`
    - [x] Test: with `eventNote = 'a perdu son père'` → prompt DOES contain `'Contexte important : a perdu son père'`
    - [x] Test: prompt always contains `'Génère 3 courts messages'` (smoke test for no regression)

- [x] **Task 7 — Widget tests (AC: 2, 3)**
  - [x] Open `test/widget/draft_message_sheet_test.dart`
  - [x] Add test: event with comment → `DraftMessageSheet` shows comment line prefixed with `'✎'`
  - [x] Add test: event with no comment → header shows single line (no `'✎'` finder)
  - [x] Open or create `test/widget/daily_view_expanded_card_test.dart`
  - [x] Add test: when `isAiSupported=true, isModelReady=true, nearestEvent!=null` → `action_llm_*` key is visible
  - [x] Add test: when `isAiSupported=false` → `action_llm_*` key absent
  - [x] Add test: when `nearestEvent=null` → `action_llm_*` key absent

- [x] **Task 8 — Code generation and integration validation**
  - [x] `dart run build_runner build --delete-conflicting-outputs`
  - [x] `flutter analyze` — zero new warnings
  - [x] `flutter test` — full suite passes (no regressions)

## Dev Notes

### Architecture Constraints (MUST FOLLOW)

- **Prompt centralization:** ALL prompt modifications must stay in `lib/core/ai/prompt_templates.dart`. Never construct prompts inline in `LlmMessageRepository` or anywhere else. [Source: architecture-phase2-addendum.md#Enforcement Guidelines]
- **`PromptTemplates.messageSuggestion()` signature is unchanged:** Same named params (`friendName`, `eventType`, `eventNote`, `language`). All existing call sites in `LlmMessageRepository` already pass `eventNote: event.comment` — no change needed there. [Source: lib/features/drafts/data/llm_message_repository.dart#L52]
- **No new Drift tables, no `schemaVersion` increment:** This story adds no persistence. `schemaVersion` stays at 9. [Source: app_database.dart line 45]
- **`_ExpandedContent` refactor to ConsumerStatefulWidget:** This is the minimum invasive change. Existing `_handleCall`, `_handleSms`, `_handleWhatsApp`, `_actionError` logic stays intact. Only `extends StatefulWidget` → `extends ConsumerStatefulWidget`, `State<_ExpandedContent>` → `ConsumerState<_ExpandedContent>`, and `build(context)` gains access to `ref`. [Source: lib/features/daily/presentation/daily_view_screen.dart]
- **`_ActionButton` async callback:** `onPressed` is typed `Future<void> Function()`. All existing handlers (`_handleCall`, etc.) are already `Future<void>`. `_handleSuggestMessage(context)` must also be `Future<void>`. [Source: daily_view_screen.dart#_ActionButton]
- **Inline guard vs `LlmFeatureGuard`:** Do NOT wrap `_ActionButton` in `LlmFeatureGuard` widget — the Row cannot conditionally include a `LlmFeatureGuard` child easily. Replicate the 2-condition check inline (`isSupported && isModelReady`) as a local bool `showMessageButton`. This is the same approach used in `FriendCardScreen._EventsSection`. [Source: 10-2 dev notes, lib/features/friends/presentation/friend_card_screen.dart#L1062]
- **`DailyViewEntry.nearestEvent` is nullable:** Added as optional field. All existing `DailyViewEntry(friend: ..., prioritized: ..., nextEventLabel: ...)` constructors compile without change (Dart named optional params with default). Do not add `required`. [Source: daily_view_provider.dart]
- **No data passed from `_ExpandedContent` to parent:** The "✦ Message" tap opens the bottom sheet directly (async, await) — same pattern as `_handleCall`/`_handleWhatsApp`. The sheet handles its own lifecycle.
- **Localization:** Every user-facing string via `context.l10n.*`. `"✦ Message"` or `"Message IA"` as per French l10n key. [Source: architecture.md#Localization]
- **Theme tokens:** `Theme.of(context).colorScheme.*` only — never hard-code hex. [Source: Story 10.1/10.2 dev notes]

### Anti-Patterns (FORBIDDEN)

- ❌ Constructing prompts inline in `LlmMessageRepository` or `_ExpandedContent`
- ❌ Adding a Drift table or incrementing `schemaVersion`
- ❌ Using `print()` — use `dart:developer log()`
- ❌ Hard-coding hex colors
- ❌ Creating a new `LlmInferenceService` instance — always via `llmInferenceServiceProvider`
- ❌ Calling `flutter_gemma` API directly
- ❌ Wrapping `_ActionButton` in `LlmFeatureGuard` widget (layout issue in Row)
- ❌ Making `DailyViewEntry.nearestEvent` required (would break all existing constructors)
- ❌ Storing `event.comment` in SQLite or `DraftMessage` persistence layer (already none)

### Project Structure — Files to Modify

```
lib/core/ai/prompt_templates.dart                         # Task 1 — tonal modifier in messageSuggestion()
lib/features/drafts/presentation/draft_message_sheet.dart  # Task 2 — comment line in header (_DataBody + _ErrorBody)
lib/features/daily/data/daily_view_provider.dart          # Task 3 — nearestEvent field on DailyViewEntry + buildDailyView
lib/features/daily/presentation/daily_view_screen.dart    # Task 4 — _ExpandedContent → ConsumerStatefulWidget + button
lib/l10n/app_en.arb                                       # Task 5 — suggestMessageDailyAction + suggestMessageDailySemantics
lib/l10n/app_fr.arb                                       # Task 5 — French translations
lib/core/l10n/app_localizations.dart                      # Task 5 — abstract getter/method
lib/core/l10n/app_localizations_en.dart                   # Task 5 — EN impl
lib/core/l10n/app_localizations_fr.dart                   # Task 5 — FR impl
test/unit/drafts/llm_message_repository_test.dart         # Task 6 — PromptTemplates tonal modifier tests
test/widget/draft_message_sheet_test.dart                 # Task 7 — comment header display tests
```

### New Files to Create

```
test/widget/daily_view_expanded_card_test.dart            # Task 7 — AI button gating tests
```

### Existing Code Patterns to Follow

- **`_ActionButton` usage:** See `lib/features/daily/presentation/daily_view_screen.dart` — `_ExpandedContent.build()` action row section (lines ~616-635). Add the 4th button to this exact Row.
- **`showDraftMessageSheet` call:** See `lib/features/friends/presentation/friend_card_screen.dart#L1062` for the inline LLM guard + `showDraftMessageSheet` invocation pattern.
- **`aiCapabilityCheckerProvider` + `modelManagerProvider` imports:** Already in `lib/features/drafts/presentation/llm_feature_guard.dart` — copy import paths from there.
- **`ConsumerStatefulWidget` pattern:** See `lib/features/daily/presentation/daily_view_screen.dart#_DailyViewScreenState` for a nearby `ConsumerStatefulWidget` example in the same file.
- **`DailyViewEntry` DailyViewProvider:** `buildDailyView()` top-level function at `lib/features/daily/data/daily_view_provider.dart` — extend the existing `unack.first` loop.
- **`_DataBody` eventComment parameter:** `_DataBody` is defined in `draft_message_sheet.dart`. Add `this.eventComment` as an optional `String?` named param. Pass it from `_DraftMessageSheetContentState.build()` where `_DataBody(...)` is constructed, via `eventComment: widget.event.comment`.
- **Truncation helper:** `String _truncate(String s, int maxChars) => s.length <= maxChars ? s : '${s.substring(0, maxChars)}…';` — add as a private function at file-scope in `draft_message_sheet.dart`.

### DraftMessageSheet Header Change — Before / After

**Before (Story 10.2 as implemented):**
```
Pour Sophie — Anniversaire dans 3 jours
```

**After (Story 10.5, with comment):**
```
Pour Sophie — Anniversaire dans 3 jours
✎ a perdu son père il y a 3 mois             ← bodySmall, italic, onSurfaceVariant
```

**After (Story 10.5, no comment):**
```
Pour Sophie — Anniversaire dans 3 jours      ← unchanged
```

### Daily View Action Row — Before / After

**Before:**
```
[📞 Appeler] [💬 SMS] [🟢 WA]
```

**After (LLM ready + nearestEvent exists):**
```
[📞 Appeler] [💬 SMS] [🟢 WA] [✦ Message IA]
```

**After (LLM not supported or model not ready):**
```
[📞 Appeler] [💬 SMS] [🟢 WA]               ← unchanged
```

### Prompt Change — Before / After

**Before (Story 10.2):**
```
Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.
Génère 3 courts messages fr chaleureux pour Sophie à l'occasion de : Anniversaire.
...
```

**After (Story 10.5, with comment):**
```
Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.
Contexte important : a perdu son père il y a 3 mois. Adapte le ton de tes messages en conséquence.
Génère 3 courts messages fr chaleureux pour Sophie à l'occasion de : Anniversaire — a perdu son père il y a 3 mois.
...
```

**Fallback (no comment — unchanged behavior):**
```
Tu es un assistant bienveillant qui aide à maintenir des liens sincères avec ses proches.
Génère 3 courts messages fr chaleureux pour Sophie à l'occasion de : Anniversaire.
...
```

### Cross-Story Context

- **Story 10.2 (done):** Provides `DraftMessageSheet`, `DraftMessageNotifier`, `LlmMessageRepository`, `showDraftMessageSheet()`, `PromptTemplates.messageSuggestion()`. This story modifies `PromptTemplates.messageSuggestion()` and `DraftMessageSheet` header only — no other 10.2 code is touched.
- **Story 10.1 (done):** Provides `LlmInferenceService`, `ModelManager`, `AiCapabilityChecker`, `LlmFeatureGuard`. The `aiCapabilityCheckerProvider` and `modelManagerProvider` are used here for the inline gate.
- **Story 10.3 (done):** `GreetingLineNotifier` — independent, not touched by this story.
- **Story 10.4 (done):** `FriendFormDraftNotifier` — independent, not touched.
- **Story 10.6 (planned):** `UserVoiceProfile` — depends on 10.5 being done so the team can validate prompt quality before designing the learning layer. 10.6 will further enrich the prompt with learned style vectors (formalité, longueur, mots-clés) injected on top of the tonal modifier from this story.
- **`Event.comment` field:** Confirmed present in `lib/features/events/domain/event.dart` (column `comment TEXT nullable`). The field is already passed to `PromptTemplates.messageSuggestion(eventNote: event.comment)` in `LlmMessageRepository.generateSuggestions()` — no change needed there. [Source: lib/features/drafts/data/llm_message_repository.dart#L52]

### Previous Story Intelligence (Story 10.2 — done, 2026-03-27)

- `DraftMessageSheet._DataBody` is a `StatelessWidget` receiving the `DraftMessage draft` as a constructed object. It does NOT receive the raw `Event` — the event details are embedded in `DraftMessage.eventContext` (string) and in the `_eventHeaderContext()` method of the parent state. To pass `event.comment` to `_DataBody`, add a `String? eventComment` parameter and populate it in `_DraftMessageSheetContentState.build()` via `widget.event.comment`.
- Key Riverpod nuance (Story 10.2): generated provider for `DraftMessageNotifier` is `draftMessageProvider` (suffix `Notifier` stripped).
- `_parseVariants` regex is already in place in `LlmMessageRepository` — no change needed.
- Completion note: `flutter analyze` showed 0 new warnings. Tests use `draftMessageProvider.overrideWith(() => _SpyNotifier(...))` pattern — new tests should follow the same pattern.
- `_ExpandedContent` in `daily_view_screen.dart` currently has `actionService: ref.read(contactActionServiceProvider)` passed as a constructor param (not via `ref` in the state). After the ConsumerStatefulWidget refactor, the `actionService` can continue to be passed via constructor OR read via `ref.read(contactActionServiceProvider)` in the new state — keep constructor approach to minimize diff.

### NFR Compliance Checklist

| NFR | How this story complies |
|-----|------------------------|
| NFR15 | "✦ Message" `_ActionButton` ≥ 48dp via existing `_ActionButton` sizing |
| NFR17 | TalkBack label via `context.l10n.suggestMessageDailySemantics(friend.name)` + comment Semantics wrapper |
| NFR18 | All inference still via `LlmInferenceService` — on-device only; no external call |
| NFR19 | Zero new `INTERNET` permission usage (inference is air-gapped) |
| NFR21 | "✦ Message" requires explicit tap — never automatic |

### FR Traceability

| FR | Coverage in this story |
|----|------------------------|
| FR44 | Enhanced draft message UX — comment visible in DraftMessageSheet header |
| FR45 | Richer tonal context injected into prompt → more contextually adapted variants |
| FR46 | Inference still via existing on-device `LlmInferenceService` — no new network path |
| New | Daily View "✦ Message" action — zero-navigation LLM message entry point |

### References

- [Source: _bmad-output/brainstorming/brainstorming-session-2026-03-30.md#Thème 1 & 3 — P2-A, P2-B, P2-C]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 10]
- [Source: _bmad-output/implementation-artifacts/10-2-message-suggestion-draftmessagesheet-with-3-llm-variants.md#Dev Notes]
- [Source: lib/core/ai/prompt_templates.dart]
- [Source: lib/features/drafts/data/llm_message_repository.dart]
- [Source: lib/features/drafts/presentation/draft_message_sheet.dart]
- [Source: lib/features/daily/presentation/daily_view_screen.dart#_ExpandedContent]
- [Source: lib/features/daily/data/daily_view_provider.dart#buildDailyView]
- [Source: lib/features/events/domain/event.dart#Events.comment]
- [Source: lib/features/drafts/presentation/llm_feature_guard.dart]
- [Source: lib/core/ai/ai_capability_checker.dart]
- [Source: lib/core/ai/model_manager.dart]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

### Completion Notes List

- **Task 1:** `PromptTemplates.messageSuggestion()` enriched with `toneInstruction` variable; when `eventNote` non-null and non-empty, prepends `"Contexte important : [note]. Adapte le ton…"` to the system instruction; `eventContext` combines type + ` — ` + note for the generation line. No call-site changes needed.
- **Task 2:** `_DataBody` and `_ErrorBody` gain optional `String? eventComment` param; `_truncate()` private helper added at file scope; comment shown with `✎` prefix in `bodySmall` italic `onSurfaceVariant` with `Semantics(label: 'Contexte : …')` wrapper when non-null/non-empty. All 3 build sites pass `eventComment: widget.event.comment`.
- **Task 3:** `DailyViewEntry` gains nullable `Event? nearestEvent` optional field (no breaking change); `buildDailyView()` populates `nearestEventByFriend` map alongside existing `nextEventLabelByFriend` in the same `unack.first` sort loop.
- **Task 4:** `_ExpandedContent` converted from `StatefulWidget` → `ConsumerStatefulWidget`; `_ExpandedContentState` → `ConsumerState<_ExpandedContent>`; `_handleSuggestMessage(BuildContext)` added; inline guard `showMessageButton = isLlmSupported && isModelReady && widget.entry.nearestEvent != null`; 4th `_ActionButton` with `key: Key('action_llm_${friend.id}')`, icon `Icons.auto_awesome_outlined`, label `suggestMessageDailyAction`; review fix also preserves `AcquittementOrigin.dailyView`, applies the dedicated TalkBack label, and distributes action buttons evenly with `Expanded`.
- **Task 5:** `suggestMessageDailyAction` (FR: `"✦ Message"`, EN: `"Message AI"`) and `suggestMessageDailySemantics` placeholder keys added to both ARB files; abstract getter/method added to `app_localizations.dart`; EN/FR implementations added manually; review fix aligned the shipped French glyph with the story contract (`✦`, not `✶`).
- **Task 6:** 6 unit tests added to `llm_message_repository_test.dart` covering null note, empty note, non-empty note with tonal instruction, smoke test, eventContext with note, eventContext without note — all 14 tests pass.
- **Task 7:** 2 widget tests added to `draft_message_sheet_test.dart` (with/without comment — overflow fixed via `tester.view.physicalSize = Size(800, 1800)`); new file `test/widget/daily_view_expanded_card_test.dart` with 5 tests (button visible gates, button absent gates, 3 standard buttons always present, semantics label visible) — targeted widget tests pass after review fixes.
- **Task 8:** Review validation rerun on corrected files: targeted `flutter test` suite for Story 10.5 passes and `flutter analyze` on modified files returns 0 issues.

### File List

```
spetaka/lib/core/ai/prompt_templates.dart
spetaka/lib/features/drafts/presentation/draft_message_sheet.dart
spetaka/lib/features/daily/data/daily_view_provider.dart
spetaka/lib/features/daily/presentation/daily_view_screen.dart
spetaka/lib/l10n/app_en.arb
spetaka/lib/l10n/app_fr.arb
spetaka/lib/core/l10n/app_localizations.dart
spetaka/lib/core/l10n/app_localizations_en.dart
spetaka/lib/core/l10n/app_localizations_fr.dart
spetaka/test/unit/drafts/llm_message_repository_test.dart
spetaka/test/widget/draft_message_sheet_test.dart
spetaka/test/widget/daily_view_expanded_card_test.dart  [NEW]
_bmad-output/brainstorming/brainstorming-session-2026-03-30.md
_bmad-output/planning-artifacts/epics.md
_bmad-output/implementation-artifacts/10-5-enriched-prompt-context-visible-daily-message-button.md
_bmad-output/implementation-artifacts/sprint-status.yaml
```

## Senior Developer Review (AI)

### Reviewer

GitHub Copilot (GPT-5.4)

### Outcome

Approved after fixes.

### Review Notes

- Fixed AC2 gap in `AsyncError`: the main event header now renders in `_ErrorBody`, with the comment line preserved underneath.
- Fixed AC7 accessibility gap: the Daily View AI action now uses `suggestMessageDailySemantics(friend.name)` instead of the generic visible label only.
- Fixed Daily View return-flow regression: the AI action now opens `DraftMessageSheet` with `AcquittementOrigin.dailyView`, preserving the post-action acquittement behavior.
- Fixed layout robustness: action buttons in the expanded Daily View row now share space evenly via `Expanded`, reducing overflow risk on smaller widths and larger text settings.
- Fixed documentation drift: the story file list now matches the actual changed files in git, including BMAD planning/brainstorming artifacts.

## Change Log

| Date | Version | Author | Description |
|------|---------|--------|-------------|
| 2026-03-30 | 1.0 | Dev Agent (Claude Sonnet 4.6) | Story 10.5 — P2-A prompt tonal modifier, P2-B DraftMessageSheet comment header, P2-C Daily View ✦ Message button |
| 2026-03-30 | 10.5 | Bob (SM) / GitHub Copilot | Story created from brainstorming-session-2026-03-30 (P2-A + P2-B + P2-C). Ready for dev. |
| 2026-03-30 | 10.5-review | GitHub Copilot (GPT-5.4) | Code review findings fixed: AsyncError header parity, Daily View origin propagation, AI button semantics, equal-width action row, and file-list traceability. |
