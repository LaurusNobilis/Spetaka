// ModelManager — Story 10.1 (AC5, AC6)
//
// State machine for LLM model download lifecycle.
// Model stored at {appDocumentsDir}/spetaka_llm/gemma3n_e2b_it_int4.bin.

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'hf_token_service.dart';
import 'llm_inference_service.dart';

part 'model_manager.g.dart';

// ── ModelDownloadState sealed class ────────────────────────────────────────

sealed class ModelDownloadState {
  const ModelDownloadState();
}

class ModelDownloadIdle extends ModelDownloadState {
  const ModelDownloadIdle();
}

class ModelDownloading extends ModelDownloadState {
  const ModelDownloading({required this.progress});
  final double progress; // 0.0 to 1.0
}

class ModelReady extends ModelDownloadState {
  const ModelReady();
}

class ModelDownloadError extends ModelDownloadState {
  const ModelDownloadError({required this.message});
  final String message;
}

// ── ModelManager ───────────────────────────────────────────────────────────

/// Manages LLM model download, storage, and readiness state.
///
/// The model file is stored at:
///   `{appDocumentsDir}/spetaka_llm/gemma3n_e2b_it_int4.bin`
///
/// Inaccessible to other apps (internal storage).
class ModelManager {
  ModelManager({
    Future<String> Function({
      required CancelToken cancelToken,
      required void Function(int progress) onProgress,
    })? installManagedModel,
    Future<void> Function(String path)? activateModelPath,
    Future<File> Function()? modelFileResolver,
  })  : _installManagedModel = installManagedModel ?? _defaultInstallManagedModel,
        _activateModelPath = activateModelPath ?? _defaultActivateModelPath,
        _modelFileResolver = modelFileResolver ?? _defaultModelFile;

  static const String _modelDirName = 'spetaka_llm';
  static const String _modelFileName = 'gemma3n_e2b_it_int4.task';
  static const String _downloadedModelUrl =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/'
      'resolve/main/gemma-3n-E2B-it-int4.task';
  static const String _downloadedModelFilename = 'gemma-3n-E2B-it-int4.task';
  final _controller = StreamController<ModelDownloadState>.broadcast();
  ModelDownloadState _currentState = const ModelDownloadIdle();
  final Future<String> Function({
    required CancelToken cancelToken,
    required void Function(int progress) onProgress,
  }) _installManagedModel;
  final Future<void> Function(String path) _activateModelPath;
  final Future<File> Function() _modelFileResolver;
  CancelToken? _downloadCancelToken;

  /// Reactive stream of download states for UI consumption.
  Stream<ModelDownloadState> get stateStream => _controller.stream;

  /// Current state snapshot.
  ModelDownloadState get currentState => _currentState;

  /// Convenience getter — true only when model file is ready.
  bool get isModelReady => _currentState is ModelReady;

  /// Checks whether the model file already exists on disk.
  ///
  /// Call on startup to avoid re-downloading.
  Future<void> checkExistingModel() async {
    final file = await _modelFile();
    if (!file.existsSync()) {
      _emit(const ModelDownloadIdle());
      return;
    }

    try {
      await _activateModelPath(file.path);
      _emit(const ModelReady());
      dev.log('ModelManager: model already on disk', name: 'ai.model');
    } catch (error, stackTrace) {
      _emit(ModelDownloadError(message: error.toString()));
      dev.log(
        'ModelManager: existing model activation failed — $error',
        name: 'ai.model',
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts the model download via flutter_gemma.
  ///
  /// No-op if already downloading or ready.
  Future<void> startDownload() async {
    if (_currentState is ModelDownloading || _currentState is ModelReady) {
      return;
    }

    final cancelToken = CancelToken();
    _downloadCancelToken = cancelToken;
    _emit(const ModelDownloading(progress: 0.0));
    dev.log('ModelManager: starting download', name: 'ai.model');

    // Clamp progress to be strictly non-decreasing.
    // The underlying Android Download Manager can report lower values when
    // a new chunk begins, causing the bar to appear to go backwards.
    var highWaterProgress = 0.0;

    try {
      final installedPath = await _installManagedModel(
        cancelToken: cancelToken,
        onProgress: (progress) {
          final value = (progress / 100.0).clamp(0.0, 1.0);
          if (value >= highWaterProgress) {
            highWaterProgress = value;
            _emit(ModelDownloading(progress: value));
          }
        },
      );

      if (!identical(_downloadCancelToken, cancelToken) || cancelToken.isCancelled) {
        if (_currentState is! ModelDownloadIdle) {
          _emit(const ModelDownloadIdle());
        }
        return;
      }

      final targetFile = await _modelFile();
      await _moveInstalledModel(installedPath: installedPath, targetFile: targetFile);
      await _activateModelPath(targetFile.path);

      _emit(const ModelReady());
      dev.log('ModelManager: download complete', name: 'ai.model');
    } catch (error, stackTrace) {
      if (CancelToken.isCancel(error)) {
        if (_currentState is! ModelDownloadIdle) {
          _emit(const ModelDownloadIdle());
        }
        dev.log('ModelManager: download cancelled', name: 'ai.model');
        return;
      }

      _emit(ModelDownloadError(message: error.toString()));
      dev.log(
        'ModelManager: download failed — $error',
        name: 'ai.model',
        stackTrace: stackTrace,
      );
    } finally {
      if (identical(_downloadCancelToken, cancelToken)) {
        _downloadCancelToken = null;
      }
    }
  }

  /// Cancels an in-progress download.
  Future<void> cancelDownload() async {
    _downloadCancelToken?.cancel('User cancelled model download');
    _downloadCancelToken = null;
    _emit(const ModelDownloadIdle());
    dev.log('ModelManager: download cancelled', name: 'ai.model');
  }

  /// Retries after an error — resets to idle, then starts download.
  Future<void> retry() async {
    _emit(const ModelDownloadIdle());
    await startDownload();
  }

  /// Cleans up resources. Call when the provider is disposed.
  Future<void> dispose() async {
    _downloadCancelToken?.cancel('ModelManager disposed');
    _downloadCancelToken = null;
    await _controller.close();
  }

  // ── Private helpers ────────────────────────────────────────────────────

  void _emit(ModelDownloadState state) {
    _currentState = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<File> _modelFile() async {
    return _modelFileResolver();
  }

  Future<void> _moveInstalledModel({
    required String installedPath,
    required File targetFile,
  }) async {
    final sourceFile = File(installedPath);
    final targetDir = targetFile.parent;
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    if (targetFile.existsSync()) {
      await targetFile.delete();
    }

    try {
      await sourceFile.rename(targetFile.path);
    } on FileSystemException {
      await sourceFile.copy(targetFile.path);
      if (sourceFile.existsSync()) {
        await sourceFile.delete();
      }
    }
  }

  static Future<String> _defaultInstallManagedModel({
    required CancelToken cancelToken,
    required void Function(int progress) onProgress,
  }) async {
    final installation = await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
    ).fromNetwork(
      _downloadedModelUrl,
      token: await const HfTokenService().getToken(),
      foreground: true,
    ).withProgress(onProgress).withCancelToken(cancelToken).install();

    final filePaths = await FlutterGemmaPlugin.instance.modelManager
        .getModelFilePaths(installation.spec);
    final installedPath = filePaths?.values.cast<String?>().firstWhere(
          (path) => path != null && path.endsWith(_downloadedModelFilename),
          orElse: () => filePaths.values.isNotEmpty
              ? filePaths.values.first
              : null,
        );

    if (installedPath == null || installedPath.isEmpty) {
      throw StateError('Unable to resolve installed model file path');
    }

    return installedPath;
  }

  static Future<void> _defaultActivateModelPath(String path) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
    ).fromFile(path).install();
  }

  static Future<File> _defaultModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_modelDirName/$_modelFileName');
  }
}

/// Riverpod stream provider for reactive UI updates.
@Riverpod(keepAlive: true)
class ModelManagerNotifier extends _$ModelManagerNotifier {
  late final ModelManager _manager;
  StreamSubscription<ModelDownloadState>? _stateSubscription;
  bool _initialized = false;

  @override
  ModelDownloadState build() {
    _manager = ModelManager();
    Future.microtask(initialize);
    ref.onDispose(() async {
      await _stateSubscription?.cancel();
      await _manager.dispose();
    });
    return const ModelDownloadIdle();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _stateSubscription = _manager.stateStream.listen((nextState) {
      state = nextState;
      // Pre-load the native model as soon as it is ready so the first
      // inference call doesn't pay the cold-start penalty.
      if (nextState is ModelReady) {
        unawaited(
          ref.read(llmInferenceServiceProvider).warmUp(),
        );
      }
    });
    await _manager.checkExistingModel();
    state = _manager.currentState;
    // Also warm up if the model was already on disk on this launch.
    if (_manager.currentState is ModelReady) {
      unawaited(
        ref.read(llmInferenceServiceProvider).warmUp(),
      );
    }
  }

  /// Whether the model is downloaded and ready.
  bool get isModelReady => _manager.isModelReady;

  /// Start downloading the model.
  Future<void> startDownload() => _manager.startDownload();

  /// Cancel an in-progress download.
  Future<void> cancelDownload() => _manager.cancelDownload();

  /// Retry after a download error.
  Future<void> retry() => _manager.retry();
}
