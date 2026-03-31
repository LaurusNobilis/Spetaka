import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../domain/pending_action_state.dart';
import 'acquittement_sheet.dart';

/// OEM fallback button — allows the user to log a contact acquittement
/// manually when the auto-detection flow is unavailable (e.g. expired state,
/// VoIP call not tracked, OEM app-kill).
///
/// Story 5-2 AC5/AC6: visible on [FriendCardScreen]; tapping opens
/// [AcquittementSheet] with [AcquittementOrigin.unknown] and actionType
/// 'manual' pre-filled. The user can adjust the type inside the sheet.
class ManualAcquittementButton extends ConsumerWidget {
  const ManualAcquittementButton({
    super.key,
    required this.friendId,
  });

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: OutlinedButton.icon(
          key: const Key('manual_acquittement_button'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(context.l10n.logContactTitle),
          onPressed: () => showAcquittementSheet(
            context: context,
            ref: ref,
            pendingState: PendingActionState(
              friendId: friendId,
              origin: AcquittementOrigin.unknown,
              actionType: 'manual',
              timestamp: DateTime.now(),
            ),
          ),
        ),
      ),
    );
  }
}
