// LlmMessageRepositoryProvider — Story 10.2 (AC2)
//
// Riverpod provider for LlmMessageRepository.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/ai/llm_inference_service.dart';
import '../../../features/friends/data/friend_repository_provider.dart';
import 'llm_message_repository.dart';

part 'llm_message_repository_provider.g.dart';

/// Riverpod provider for [LlmMessageRepository].
///
/// keepAlive: true — the repository wraps long-lived singleton services and
/// must survive navigation (matches the keepAlive pattern used by other
/// infrastructure providers).
@Riverpod(keepAlive: true)
LlmMessageRepository llmMessageRepository(Ref ref) {
  return LlmMessageRepository(
    friendRepository: ref.watch(friendRepositoryProvider),
    llmInferenceService: ref.watch(llmInferenceServiceProvider),
  );
}
