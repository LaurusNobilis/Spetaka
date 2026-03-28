// Story 10.1 — Unit tests for LlmInferenceService (AC8).

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/llm_inference_service.dart';

void main() {
  group('LlmInferenceService timeout behavior — Story 10.1 AC8', () {
    test('timeout returns empty list', () async {
      final service = LlmInferenceService(
        inferenceRunner: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <String>['late'];
        },
        timeout: const Duration(milliseconds: 10),
      );

      final result = await service.infer('hello');
      expect(result, isEmpty);
    });

    test('timeout does not throw', () async {
      final service = LlmInferenceService(
        inferenceRunner: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <String>['late'];
        },
        timeout: const Duration(milliseconds: 10),
      );

      expect(() => service.infer('hello'), returnsNormally);
      final result = await service.infer('hello');
      expect(result, isA<List<String>>());
    });
  });

  group('LlmInferenceService queueing — Story 10.1 AC8', () {
    test('second call waits for first to finish', () async {
      final started = <String>[];
      final completed = <String>[];

      final service = LlmInferenceService(
        inferenceRunner: (prompt) async {
          started.add(prompt);
          if (prompt == 'first') {
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
          completed.add(prompt);
          return <String>[prompt];
        },
        timeout: const Duration(seconds: 1),
      );

      final firstFuture = service.infer('first');
      final secondFuture = service.infer('second');

      final firstResult = await firstFuture;
      final secondResult = await secondFuture;

      expect(firstResult, <String>['first']);
      expect(secondResult, <String>['second']);
      expect(started, <String>['first', 'second']);
      expect(completed, <String>['first', 'second']);
    });

    test('errors return empty list and release queue', () async {
      final service = LlmInferenceService(
        inferenceRunner: (prompt) async {
          if (prompt == 'boom') {
            throw StateError('failure');
          }
          return <String>[prompt];
        },
        timeout: const Duration(seconds: 1),
      );

      final first = await service.infer('boom');
      final second = await service.infer('ok');

      expect(first, isEmpty);
      expect(second, <String>['ok']);
    });
  });
}
