import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/lifecycle/app_lifecycle_service.dart';
import '../../../features/settings/data/category_tags_provider.dart';
import '../data/acquittement_repository_provider.dart';
import '../domain/pending_action_state.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Ordered list of selectable action types for [AcquittementSheet].
const _kActionTypes = ['call', 'sms', 'whatsapp', 'vocal', 'in_person'];

/// Human-readable labels for each action type.
const _kTypeLabels = <String, String>{
  'call': 'Appel',
  'sms': 'SMS',
  'whatsapp': 'WhatsApp',
  'vocal': 'Message vocal',
  'in_person': 'Vu en personne',
};

/// Icons for each action type.
const _kTypeIcons = <String, IconData>{
  'call': Icons.phone_outlined,
  'sms': Icons.sms_outlined,
  'whatsapp': Icons.chat_outlined,
  'vocal': Icons.mic_none_outlined,
  'in_person': Icons.people_outline,
};

// ---------------------------------------------------------------------------
// Top-level helper (kept from 5-2 stub — API unchanged)
// ---------------------------------------------------------------------------

/// Shows the acquittement bottom sheet for the given [pendingState].
///
/// Clears the pending action state from [AppLifecycleService] as soon as it
/// mounts (AC3 — clear on open).
Future<void> showAcquittementSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PendingActionState pendingState,
}) {
  // AC3: clear pending state as soon as the sheet is opened.
  ref.read(appLifecycleServiceProvider).clearActionState();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AcquittementSheet(pendingState: pendingState),
  );
}

// ---------------------------------------------------------------------------
// AcquittementSheet — Story 5-3 full implementation
// ---------------------------------------------------------------------------

/// Bottom sheet that captures a contact acquittement in one tap.
///
/// **AC coverage (Story 5-3):**
/// - AC1: `acquittements` table exists (created in Story 1.7, schema v7).
/// - AC2: Pre-fills action type from [PendingActionState.actionType]; timestamp = now.
/// - AC3: Type selector allows call / SMS / WhatsApp / vocal / vu en personne.
/// - AC4: Confirm = 1 tap → saves acquittement → warm micro-feedback.
/// - AC5: Note field is optional.
class AcquittementSheet extends ConsumerStatefulWidget {
  const AcquittementSheet({
    super.key,
    required this.pendingState,
  });

  final PendingActionState pendingState;

  @override
  ConsumerState<AcquittementSheet> createState() => _AcquittementSheetState();
}

class _AcquittementSheetState extends ConsumerState<AcquittementSheet> {
  static const _uuid = Uuid();

  late String _selectedType;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // AC2: pre-fill action type from pending state.
    // Map raw actionType to selector value (default 'call' for 'manual'/unknown).
    _selectedType = _normalizeType(widget.pendingState.actionType);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Maps raw actionType to a type present in [_kActionTypes].
  String _normalizeType(String raw) {
    return _kActionTypes.contains(raw) ? raw : 'call';
  }

  Future<void> _handleConfirm() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final note = _noteController.text.trim();
      final entry = Acquittement(
        id: _uuid.v4(),
        friendId: widget.pendingState.friendId,
        type: _selectedType,
        note: note.isNotEmpty ? note : null,
        createdAt: now,
      );

      final catWeights = ref.read(categoryWeightsMapProvider);
      await ref.read(acquittementRepositoryProvider).insertAndUpdateCareScore(
        entry,
        categoryWeights: catWeights,
      );

      if (mounted) {
        Navigator.of(context).pop();
        // Warm micro-feedback as a SnackBar after sheet closes.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  context.l10n.contactLoggedFeedback,
                  key: const Key('acquittement_success_snackbar'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.couldNotSave),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      // Ensure sheet rises above keyboard when note field is focused.
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle (decorative — excluded from a11y tree) ────────
          ExcludeSemantics(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────────────
          Text(
            context.l10n.confirmContactLog,
            key: const Key('acquittement_sheet_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ── AC3: Type selector ───────────────────────────────────────────
          Text(
            context.l10n.typeLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kActionTypes.map((type) {
              final selected = _selectedType == type;
              final icon = _kTypeIcons[type] ?? Icons.contact_phone_outlined;
              final label = _kTypeLabels[type] ?? type;
              return ChoiceChip(
                key: Key('type_chip_$type'),
                avatar: Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface,
                  fontSize: 13,
                ),
                selectedColor: colorScheme.secondaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Optional note ────────────────────────────────────────────────
          Text(
            context.l10n.noteOptionalLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('acquittement_note_field'),
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleConfirm(),
            decoration: InputDecoration(
              hintText: context.l10n.howDidItGo,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── AC4: One-tap confirm ─────────────────────────────────────────
          Semantics(
            label: context.l10n.logContactTitle,
            hint: context.l10n.savesContactHistory,
            button: true,
            child: FilledButton(
              key: const Key('acquittement_sheet_confirm'),
              onPressed: _saving ? null : _handleConfirm,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.logContactTitle),
            ),
          ),
        ],
      ),
    );
  }
}
