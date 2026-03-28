// AiCapabilityChecker — Story 10.1 (AC3, AC4)
//
// Hardware gate: returns true only if Android API level ≥ 29 AND RAM ≥ 4 GB.
// Result is cached for the session via @Riverpod(keepAlive: true).

import 'dart:developer' as dev;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_capability_checker.g.dart';

/// Minimum requirements for on-device LLM inference.
class AiCapabilityChecker {
  AiCapabilityChecker({
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<int> Function()? apiLevelReader,
    bool Function()? isAndroidChecker,
    int Function()? totalRamReader,
  })  : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
        _apiLevelReader = apiLevelReader,
        _isAndroidChecker = isAndroidChecker,
        _totalRamReader = totalRamReader;

  final DeviceInfoPlugin _deviceInfoPlugin;
  final Future<int> Function()? _apiLevelReader;
  final bool Function()? _isAndroidChecker;
  final int Function()? _totalRamReader;

  static const int _minApiLevel = 29;
  static const int _minRamBytes = 4 * 1024 * 1024 * 1024; // 4 GB

  static int get minApiLevel => _minApiLevel;

  static int get minRamBytes => _minRamBytes;

  static bool evaluateCapability({
    required int apiLevel,
    required int totalRamBytes,
  }) {
    return apiLevel >= _minApiLevel && totalRamBytes >= _minRamBytes;
  }

  static int readTotalRamFromProcMeminfo() {
    return _readTotalRamFromProcMeminfo();
  }

  /// Returns `true` if the device meets LLM hardware requirements.
  ///
  /// Checks:
  /// - Android API level ≥ 29
  /// - Total system RAM ≥ 4 GB
  ///
  /// Returns `false` on non-Android platforms or if checks fail.
  Future<bool> isSupported() async {
    if (!_isAndroidPlatform()) {
      dev.log(
        'AiCapabilityChecker: not Android — unsupported',
        name: 'ai.capability',
      );
      return false;
    }

    try {
      final apiLevel = await _readApiLevel();

      if (apiLevel < _minApiLevel) {
        dev.log(
          'AiCapabilityChecker: API $apiLevel < $_minApiLevel — unsupported',
          name: 'ai.capability',
        );
        return false;
      }

      final totalRamReader = _totalRamReader;
      final totalRam = totalRamReader != null
          ? totalRamReader()
          : _readTotalRamFromProcMeminfo();

      if (!evaluateCapability(apiLevel: apiLevel, totalRamBytes: totalRam)) {
        dev.log(
          'AiCapabilityChecker: API $apiLevel or RAM '
          '${totalRam ~/ (1024 * 1024)} MB below minimum — unsupported',
          name: 'ai.capability',
        );
        return false;
      }

      dev.log(
        'AiCapabilityChecker: API $apiLevel, '
        'RAM ${totalRam ~/ (1024 * 1024)} MB — supported',
        name: 'ai.capability',
      );
      return true;
    } catch (e) {
      dev.log(
        'AiCapabilityChecker: check failed — $e',
        name: 'ai.capability',
      );
      return false;
    }
  }

  bool _isAndroidPlatform() {
    final isAndroidChecker = _isAndroidChecker;
    return isAndroidChecker != null ? isAndroidChecker() : Platform.isAndroid;
  }

  Future<int> _readApiLevel() async {
    final apiLevelReader = _apiLevelReader;
    if (apiLevelReader != null) {
      return apiLevelReader();
    }

    final androidInfo = await _deviceInfoPlugin.androidInfo;
    return androidInfo.version.sdkInt;
  }

  /// Reads total RAM from /proc/meminfo (available on all Android devices).
  static int _readTotalRamFromProcMeminfo() {
    try {
      final contents = File('/proc/meminfo').readAsStringSync();
      final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(contents);
      if (match != null) {
        return int.parse(match.group(1)!) * 1024; // kB → bytes
      }
    } catch (_) {
      // Fallback: cannot read /proc/meminfo
    }
    return 0;
  }
}

/// Riverpod provider — cached for the session (keepAlive).
@Riverpod(keepAlive: true)
class AiCapabilityCheckerNotifier extends _$AiCapabilityCheckerNotifier {
  late final AiCapabilityChecker _checker;
  bool _initialized = false;

  @override
  bool build() {
    _checker = AiCapabilityChecker();
    Future.microtask(initialize);
    return false;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    state = await _checker.isSupported();
  }
}
