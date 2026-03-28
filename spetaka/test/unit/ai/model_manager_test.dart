// Story 10.1 — Unit tests for ModelManager (AC8).

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/model_manager.dart';

void main() {
  group('ModelManager state classes — Story 10.1 AC8', () {
    test('idle state type', () {
      const state = ModelDownloadIdle();
      expect(state, isA<ModelDownloadState>());
    });

    test('downloading carries progress', () {
      const state = ModelDownloading(progress: 0.42);
      expect(state.progress, 0.42);
    });

    test('ready state type', () {
      const state = ModelReady();
      expect(state, isA<ModelDownloadState>());
    });

    test('error carries message', () {
      const state = ModelDownloadError(message: 'network failed');
      expect(state.message, 'network failed');
    });
  });

  group('ModelManager state transitions — Story 10.1 AC8', () {
    test('initial state is idle', () {
      final manager = ModelManager(
        installManagedModel: _unusedInstall,
        activateModelPath: _noopActivate,
        modelFileResolver: _missingModelFile,
      );

      expect(manager.currentState, isA<ModelDownloadIdle>());
      expect(manager.isModelReady, isFalse);
    });

    test('idle → downloading → ready', () async {
      final tempDir = await Directory.systemTemp.createTemp('model-manager-ready');
      addTearDown(() => tempDir.delete(recursive: true));

      final downloadedFile = File('${tempDir.path}/downloaded.task')
        ..writeAsStringSync('model');
      final targetFile = File('${tempDir.path}/spetaka_llm/gemma3n_e2b_it_int4.bin');
      String? activatedPath;

      final manager = ModelManager(
        installManagedModel: ({required cancelToken, required onProgress}) async {
          onProgress(25);
          onProgress(100);
          return downloadedFile.path;
        },
        activateModelPath: (path) async {
          activatedPath = path;
        },
        modelFileResolver: () async => targetFile,
      );

      final states = <ModelDownloadState>[];
      final sub = manager.stateStream.listen(states.add);
      addTearDown(sub.cancel);

      await manager.startDownload();

      expect(manager.currentState, isA<ModelReady>());
      expect(manager.isModelReady, isTrue);
      expect(targetFile.existsSync(), isTrue);
      expect(downloadedFile.existsSync(), isFalse);
      expect(activatedPath, equals(targetFile.path));
      // Stream events are async; wait for them to be delivered before asserting
      await pumpEventQueue();
      expect(states.whereType<ModelDownloading>().isNotEmpty, isTrue);
      expect(states.last, isA<ModelReady>());
    });

    test('downloading → error → retry → downloading → ready', () async {
      final tempDir = await Directory.systemTemp.createTemp('model-manager-retry');
      addTearDown(() => tempDir.delete(recursive: true));

      var attempts = 0;
      final targetFile = File('${tempDir.path}/spetaka_llm/gemma3n_e2b_it_int4.bin');

      final manager = ModelManager(
        installManagedModel: ({required cancelToken, required onProgress}) async {
          attempts += 1;
          onProgress(10);
          if (attempts == 1) {
            throw StateError('network timeout');
          }

          final downloadedFile = File('${tempDir.path}/downloaded-$attempts.task')
            ..writeAsStringSync('model');
          onProgress(100);
          return downloadedFile.path;
        },
        activateModelPath: (_) async {},
        modelFileResolver: () async => targetFile,
      );

      await manager.startDownload();
      expect(manager.currentState, isA<ModelDownloadError>());
      expect(manager.isModelReady, isFalse);

      await manager.retry();
      expect(manager.currentState, isA<ModelReady>());
      expect(manager.isModelReady, isTrue);
      expect(attempts, 2);
    });

    test('downloading → idle on cancel', () async {
      final tempDir = await Directory.systemTemp.createTemp('model-manager-cancel');
      addTearDown(() => tempDir.delete(recursive: true));

      final targetFile = File('${tempDir.path}/spetaka_llm/gemma3n_e2b_it_int4.bin');
      final downloadStarted = Completer<void>();

      final manager = ModelManager(
        installManagedModel: ({required cancelToken, required onProgress}) async {
          onProgress(5);
          downloadStarted.complete();
          await cancelToken.whenCancelled;
          cancelToken.throwIfCancelled();
          return '${tempDir.path}/should-not-exist.task';
        },
        activateModelPath: (_) async {},
        modelFileResolver: () async => targetFile,
      );

      final future = manager.startDownload();
      await downloadStarted.future;
      await manager.cancelDownload();
      await future;

      expect(manager.currentState, isA<ModelDownloadIdle>());
      expect(manager.isModelReady, isFalse);
    });

    test('checkExistingModel activates persisted model and becomes ready', () async {
      final tempDir = await Directory.systemTemp.createTemp('model-manager-existing');
      addTearDown(() => tempDir.delete(recursive: true));

      final targetFile = File('${tempDir.path}/spetaka_llm/gemma3n_e2b_it_int4.bin');
      targetFile.parent.createSync(recursive: true);
      targetFile.writeAsStringSync('persisted-model');

      var activatedPath = '';
      final manager = ModelManager(
        installManagedModel: _unusedInstall,
        activateModelPath: (path) async {
          activatedPath = path;
        },
        modelFileResolver: () async => targetFile,
      );

      await manager.checkExistingModel();

      expect(activatedPath, targetFile.path);
      expect(manager.currentState, isA<ModelReady>());
      expect(manager.isModelReady, isTrue);
    });
  });
}

Future<String> _unusedInstall({
  required Object cancelToken,
  required void Function(int progress) onProgress,
}) async {
  throw UnimplementedError();
}

Future<void> _noopActivate(String _) async {}

Future<File> _missingModelFile() async => File('${Directory.systemTemp.path}/missing-model.bin');
