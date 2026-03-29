// GreetingLineNotifier — Story 10.3
//
// Riverpod notifier that:
//   1. Immediately returns a static fallback greeting (never blocks render).
//   2. On first AsyncData arrival, fires a background LLM call via microtask.
//   3. Updates state with the LLM result when available; silently keeps the
//      static fallback on timeout or model-not-ready.
//
// Auto-disposes on every daily view visit — greeting refreshes on each open.

import 'dart:developer' as dev;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/ai/greeting_service.dart';
import '../../../core/ai/llm_inference_service.dart';
import '../../../core/ai/model_manager.dart';
import '../../../core/ai/prompt_templates.dart';
import '../../settings/data/pseudo_provider.dart';
import '../domain/priority_engine.dart';
import 'daily_view_provider.dart';

part 'greeting_line_provider.g.dart';

@riverpod
class GreetingLineNotifier extends _$GreetingLineNotifier {
  String? _lastRequestedContextKey;
  int _requestVersion = 0;

  @override
  String build() {
    final dailyAsync = ref.watch(watchDailyViewProvider);
    final modelState = ref.watch(modelManagerProvider);
    final userName = ref.watch(pseudoProvider);
    final entries = dailyAsync.asData?.value ?? [];

    final urgentCount = entries
        .where((e) => e.prioritized.tier == UrgencyTier.urgent)
        .length;
    final concernCount = entries
        .where((e) => e.friend.isConcernActive)
        .length;
    final contextKey = '$urgentCount|$concernCount|$userName';

    // Fire LLM when the prompt context changes or when the model becomes ready.
    if (dailyAsync is AsyncData &&
        modelState is ModelReady &&
        _lastRequestedContextKey != contextKey) {
      _lastRequestedContextKey = contextKey;
      final requestVersion = ++_requestVersion;
      Future.microtask(
        () => _generateAsync(
          requestVersion: requestVersion,
          urgentCount: urgentCount,
          concernCount: concernCount,
          userName: userName,
        ),
      );
    }

    return GreetingService(userName: userName).staticFallback(
      urgentCount: urgentCount,
      concernCount: concernCount,
    );
  }

  Future<void> _generateAsync({
    required int requestVersion,
    required int urgentCount,
    required int concernCount,
    required String userName,
  }) async {
    try {
      final modelState = ref.read(modelManagerProvider);
      if (modelState is! ModelReady) return;

      final prompt = PromptTemplates.greetingLine(
        userName: userName,
        urgentCount: urgentCount,
        concernCount: concernCount,
      );

      final results =
          await ref.read(llmInferenceServiceProvider).infer(prompt);
      final normalizedGreeting = _normalizeGreeting(results);
      if (normalizedGreeting != null && requestVersion == _requestVersion) {
        state = normalizedGreeting;
      }
    } catch (e) {
      dev.log(
        'GreetingLineNotifier: LLM error — $e',
        name: 'ai.greeting',
      );
    }
  }

  String? _normalizeGreeting(List<String> results) {
    if (results.isEmpty) {
      return null;
    }

    final firstLine = results.first
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return null;
    }

    final normalized = firstLine
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final unquoted = _stripWrappingQuotes(normalized);

    if (unquoted.isEmpty || RegExp(r'\d').hasMatch(unquoted)) {
      return null;
    }

    if (unquoted.split(' ').length > 15) {
      return null;
    }

    return unquoted;
  }

  String _stripWrappingQuotes(String value) {
    var normalized = value.trim();
    while (normalized.length >= 2) {
      final startsWithQuote =
          normalized.startsWith('"') || normalized.startsWith("'");
      final endsWithQuote =
          normalized.endsWith('"') || normalized.endsWith("'");
      if (!startsWithQuote || !endsWithQuote) {
        break;
      }
      normalized = normalized.substring(1, normalized.length - 1).trim();
    }
    return normalized;
  }
}
