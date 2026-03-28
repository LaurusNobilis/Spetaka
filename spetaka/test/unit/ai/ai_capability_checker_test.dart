// Story 10.1 — Unit tests for AiCapabilityChecker (AC8).
//
// Tests isSupported() with mocked API level/RAM combinations:
// - ≥29 + ≥4GB → true
// - <29 → false
// - <4GB → false
// - both fail → false

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/ai/ai_capability_checker.dart';

void main() {
  group('AiCapabilityChecker — Story 10.1 AC8', () {
    test('returns false on non-Android platform', () async {
      // This test runs on the host (Linux) which is not Android.
      // AiCapabilityChecker checks Platform.isAndroid first.
      if (!Platform.isAndroid) {
        final checker = AiCapabilityChecker();
        final result = await checker.isSupported();
        expect(result, isFalse);
      }
    });

    test('_readTotalRamFromProcMeminfo returns int from /proc/meminfo', () {
      // On Linux test hosts, /proc/meminfo exists and should return > 0.
      // On Android, this also works.
      if (Platform.isLinux || Platform.isAndroid) {
        final ram = AiCapabilityChecker.readTotalRamFromProcMeminfo();
        expect(ram, greaterThan(0));
      }
    });

    // ── Logic validation tests (pure logic, no device dependency) ──────

    test('RAM threshold is exactly 4 GB', () {
      // Verify the constant is correct.
      expect(AiCapabilityChecker.minRamBytes, equals(4 * 1024 * 1024 * 1024));
    });

    test('API level threshold is exactly 29', () {
      expect(AiCapabilityChecker.minApiLevel, equals(29));
    });

    // ── Capability evaluation tests ────────────────────────────────────

    test('supported: API 29 + 4 GB RAM → true', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 29,
        totalRamBytes: 4 * 1024 * 1024 * 1024,
      );
      expect(result, isTrue);
    });

    test('supported: API 34 + 8 GB RAM → true', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 34,
        totalRamBytes: 8 * 1024 * 1024 * 1024,
      );
      expect(result, isTrue);
    });

    test('unsupported: API 28 + 4 GB RAM → false (API too low)', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 28,
        totalRamBytes: 4 * 1024 * 1024 * 1024,
      );
      expect(result, isFalse);
    });

    test('unsupported: API 29 + 3 GB RAM → false (RAM too low)', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 29,
        totalRamBytes: 3 * 1024 * 1024 * 1024,
      );
      expect(result, isFalse);
    });

    test('unsupported: API 26 + 2 GB RAM → false (both below threshold)', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 26,
        totalRamBytes: 2 * 1024 * 1024 * 1024,
      );
      expect(result, isFalse);
    });

    test('edge case: API 29 + exactly 4GB-1 byte → false', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 29,
        totalRamBytes: 4 * 1024 * 1024 * 1024 - 1,
      );
      expect(result, isFalse);
    });

    test('edge case: API 0 + 0 RAM → false', () {
      final result = AiCapabilityChecker.evaluateCapability(
        apiLevel: 0,
        totalRamBytes: 0,
      );
      expect(result, isFalse);
    });

    test('isSupported returns true for mocked Android API and RAM', () async {
      final checker = AiCapabilityChecker(
        isAndroidChecker: () => true,
        apiLevelReader: () async => 34,
        totalRamReader: () => 8 * 1024 * 1024 * 1024,
      );

      final result = await checker.isSupported();

      expect(result, isTrue);
    });

    test('isSupported returns false when mocked API is too low', () async {
      final checker = AiCapabilityChecker(
        isAndroidChecker: () => true,
        apiLevelReader: () async => 28,
        totalRamReader: () => 8 * 1024 * 1024 * 1024,
      );

      final result = await checker.isSupported();

      expect(result, isFalse);
    });

    test('isSupported returns false when mocked RAM is too low', () async {
      final checker = AiCapabilityChecker(
        isAndroidChecker: () => true,
        apiLevelReader: () async => 34,
        totalRamReader: () => 3 * 1024 * 1024 * 1024,
      );

      final result = await checker.isSupported();

      expect(result, isFalse);
    });
  });
}
