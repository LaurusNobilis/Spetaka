// LlmInferenceService — Story 10.1 (AC7)
//
// Singleton wrapper around flutter_gemma inference.
// - 30-second timeout — returns empty list on timeout, never throws.
// - Concurrent calls are serialized via Completer queue.
// - Air-gapped: zero network calls (NFR19).

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'llm_inference_service.g.dart';

/// On-device LLM inference service.
///
/// A 30-second timeout is enforced: on timeout the method returns an empty
/// `List<String>`.
///
/// Multiple concurrent [infer] calls are queued (serialized), not
/// parallelised — only one inference runs at a time.
class LlmInferenceService {
  LlmInferenceService({
    Future<List<String>> Function(String prompt)? inferenceRunner,
    Duration timeout = const Duration(seconds: 30),
  })  : _inferenceRunner = inferenceRunner,
        _timeout = timeout;

  final Future<List<String>> Function(String prompt)? _inferenceRunner;
  final Duration _timeout;

  /// Cached model instance — reused across calls to avoid reloading the 2 GB
  /// model from disk on every inference (H1 fix).
  InferenceModel? _model;

  /// Lock to serialize concurrent inference calls.
  Completer<void>? _lock;

  /// Runs inference with the given [prompt] and returns suggested responses.
  ///
  /// Returns an empty list on timeout or error — callers handle empty list
  /// gracefully (fallback to static content).
  ///
  /// Never throws.
  Future<List<String>> infer(String prompt) async {
    // Wait for any ongoing inference to complete.
    while (_lock != null && !_lock!.isCompleted) {
      await _lock!.future;
    }

    _lock = Completer<void>();

    try {
      final result = await _runInference(prompt).timeout(
        _timeout,
        onTimeout: () {
          dev.log(
            'LlmInferenceService: inference timed out after ${_timeout.inSeconds}s',
            name: 'ai.inference',
          );
          return <String>[];
        },
      );
      return result;
    } catch (e) {
      dev.log(
        'LlmInferenceService: inference error — $e',
        name: 'ai.inference',
      );
      return <String>[];
    } finally {
      _lock?.complete();
    }
  }

  Future<List<String>> _runInference(String prompt) async {
    final inferenceRunner = _inferenceRunner;
    if (inferenceRunner != null) {
      return inferenceRunner(prompt);
    }

    try {
      // Reuse cached model — avoids reloading the 2 GB file on every call.
      _model ??= await FlutterGemma.getActiveModel();
      final chat = await _model!.createChat();
      await chat.addQuery(Message.text(text: prompt, isUser: true));

      final response = await chat.generateChatResponse();
      if (response is! TextResponse) {
        return <String>[];
      }

      final text = response.token.trim();
      if (text.isEmpty) {
        return <String>[];
      }

      return <String>[text];
    } catch (e) {
      dev.log(
        'LlmInferenceService: active model inference failed — $e',
        name: 'ai.inference',
      );
      // Reset cached model on error so it is recreated on the next call.
      await _model?.close();
      _model = null;
      return <String>[];
    }
  }

  /// Releases the cached model. Called by the Riverpod provider on dispose.
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

/// Riverpod singleton provider — keepAlive prevents disposal.
@Riverpod(keepAlive: true)
LlmInferenceService llmInferenceService(Ref ref) {
  final service = LlmInferenceService();
  ref.onDispose(service.dispose);
  return service;
}
