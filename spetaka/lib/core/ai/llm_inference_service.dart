// LlmInferenceService — Story 10.1 (AC7)
//
// Singleton wrapper around flutter_gemma inference.
// - 5-minute timeout — returns empty list on timeout, never throws.
//   (Loading the 2 GB model into native memory on first use can take
//   20-40 s on mid-range phones; previous 30 s limit was too aggressive.)
// - warmUp() pre-loads the model in the background so the first inference
//   call is fast.
// - Concurrent calls are serialized via Completer queue.
// - Air-gapped: zero network calls (NFR19).

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'llm_inference_service.g.dart';

/// On-device LLM inference service.
///
/// A 5-minute timeout is enforced: on timeout the method returns an empty
/// `List<String>`.
///
/// Multiple concurrent [infer] calls are queued (serialized), not
/// parallelised — only one inference runs at a time.
class LlmInferenceService {
  LlmInferenceService({
    Future<List<String>> Function(String prompt)? inferenceRunner,
    Duration timeout = const Duration(minutes: 5),
  })  : _inferenceRunner = inferenceRunner,
        _timeout = timeout;

  final Future<List<String>> Function(String prompt)? _inferenceRunner;
  final Duration _timeout;

  /// Cached model instance — reused across calls to avoid reloading the 2 GB
  /// model from disk on every inference (H1 fix).
  InferenceModel? _model;

  /// Lock to serialize concurrent inference calls.
  Completer<void>? _lock;

  /// Pre-loads the native model into memory without running inference.
  ///
  /// Call this as soon as the model file is ready (ModelReady state) so that
  /// the first real [infer] call does not pay the cold-start penalty
  /// (loading a 2 GB file into native memory can take 20-40 s on mid-range
  /// phones).
  ///
  /// Never throws — errors are swallowed and logged.
  Future<void> warmUp() async {
    if (_inferenceRunner != null || _model != null) return;
    try {
      dev.log('LlmInferenceService: warming up model…', name: 'ai.inference');
      _model = await FlutterGemma.getActiveModel();
      dev.log('LlmInferenceService: warm-up complete', name: 'ai.inference');
    } catch (e) {
      dev.log(
        'LlmInferenceService: warm-up failed — $e',
        name: 'ai.inference',
      );
    }
  }

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

  /// Streams delta tokens from on-device LLM inference.
  ///
  /// Each yielded [String] is an incremental token (delta). Callers must
  /// accumulate tokens to obtain the full response.
  ///
  /// A **per-token timeout of 3 minutes** is enforced: if the native backend
  /// produces no token for 3 consecutive minutes the stream is closed
  /// gracefully. This prevents infinite hangs when the LiteRT backend stalls
  /// silently (observed on some devices).
  ///
  /// Serialized with [infer] via the same lock — only one inference runs at
  /// a time. Stream closes on error (never throws).
  Stream<String> inferStream(String prompt) async* {
    // Test shim: if an inferenceRunner is injected, yield its output tokens.
    final inferenceRunner = _inferenceRunner;
    if (inferenceRunner != null) {
      final tokens = await inferenceRunner(prompt);
      yield* Stream.fromIterable(tokens);
      return;
    }

    // Wait for any ongoing inference to complete.
    while (_lock != null && !_lock!.isCompleted) {
      await _lock!.future;
    }
    _lock = Completer<void>();

    try {
      _model ??= await FlutterGemma.getActiveModel();
      final chat = await _model!.createChat();
      await chat.addQuery(Message.text(text: prompt, isUser: true));

      // Per-token timeout: if the native inference engine produces no new
      // token for 3 minutes, close the stream rather than hanging forever.
      await for (final response in chat.generateChatResponseAsync().timeout(
        const Duration(minutes: 3),
        onTimeout: (sink) {
          dev.log(
            'LlmInferenceService: no token for 3 min — closing stream',
            name: 'ai.inference',
          );
          sink.close();
        },
      )) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (e) {
      dev.log(
        'LlmInferenceService: stream inference error — $e',
        name: 'ai.inference',
      );
      await _model?.close();
      _model = null;
    } finally {
      _lock?.complete();
    }
  }
}

/// Riverpod singleton provider — keepAlive prevents disposal.
@Riverpod(keepAlive: true)
LlmInferenceService llmInferenceService(Ref ref) {
  final service = LlmInferenceService();
  ref.onDispose(service.dispose);
  return service;
}
