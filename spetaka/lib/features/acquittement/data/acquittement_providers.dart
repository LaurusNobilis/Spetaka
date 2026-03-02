import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'acquittement_repository_provider.dart';

/// Watches acquittements for [friendId] in reverse chronological order.
///
/// Emits on every DB change; notes are decrypted by [AcquittementRepository].
///
/// Used by Story 5-4 (contact history log in [FriendCardScreen]).
final watchAcquittementsProvider =
    StreamProvider.autoDispose.family<List<Acquittement>, String>(
  (ref, friendId) =>
      ref.watch(acquittementRepositoryProvider).watchByFriendId(friendId),
  name: 'watchAcquittementsProvider',
);
