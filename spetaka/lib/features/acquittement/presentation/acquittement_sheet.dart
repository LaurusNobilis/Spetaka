import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lifecycle/app_lifecycle_service.dart';
import '../domain/pending_action_state.dart';

/// Shows the acquittement bottom sheet for the given [pendingState].
///
/// Clears the pending action state from [AppLifecycleService] as soon as it
/// mounts (AC3 — clear on open).
///
/// The [isBackground] flag controls whether the route below is still
/// visible (transparent barrier when true).
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

/// Bottom sheet that captures a contact acquittement.
///
/// **Story 5-2 stub** — displays the pending state; interaction is wired in
/// Story 5-3 which replaces this widget body with the full implementation
/// (type selector, optional note, one-tap confirm, Drift persistence).
class AcquittementSheet extends StatelessWidget {
  const AcquittementSheet({
    super.key,
    required this.pendingState,
  });

  final PendingActionState pendingState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Log contact',
            key: const Key('acquittement_sheet_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Action: ${pendingState.actionType}',
            key: const Key('acquittement_sheet_action_type'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Placeholder — replaced in Story 5-3 with full AcquittementSheet.
          FilledButton(
            key: const Key('acquittement_sheet_confirm'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
