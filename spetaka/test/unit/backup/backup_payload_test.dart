// test/unit/backup/backup_payload_test.dart
//
// Tests Story 10.6 — BackupPayload voiceProfile field
//
// Coverage:
//   AC6 — currentVersion == 2
//   AC6 — fromJson() with version=1 (no voiceProfile key) → voiceProfile == null
//   AC6 — toJson() / fromJson() roundtrip with non-null voiceProfile preserves all fields

import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/backup/domain/backup_payload.dart';

BackupPayload _emptyPayload({UserVoiceProfile? voiceProfile}) => BackupPayload(
      version: BackupPayload.currentVersion,
      exportedAt: '2025-01-01T00:00:00.000Z',
      settings: const BackupSettings(),
      friends: const [],
      events: const [],
      acquittements: const [],
      eventTypes: const [],
      voiceProfile: voiceProfile,
    );

void main() {
  group('BackupPayload — Story 10.6 voiceProfile', () {
    test('currentVersion is 2', () {
      expect(BackupPayload.currentVersion, equals(2));
    });

    test('fromJson() with v1 JSON (no voiceProfile key) → voiceProfile == null',
        () {
      final json = <String, dynamic>{
        'version': 1,
        'exportedAt': '2025-01-01T00:00:00.000Z',
        'settings': <String, dynamic>{},
        'friends': <dynamic>[],
        'events': <dynamic>[],
        'acquittements': <dynamic>[],
        'eventTypes': <dynamic>[],
        // deliberately no 'voiceProfile' key
      };
      final payload = BackupPayload.fromJson(json);
      expect(payload.voiceProfile, isNull);
    });

    test('fromJson() with explicit null voiceProfile → voiceProfile == null',
        () {
      final json = <String, dynamic>{
        'version': 2,
        'exportedAt': '2025-01-01T00:00:00.000Z',
        'settings': <String, dynamic>{},
        'friends': <dynamic>[],
        'events': <dynamic>[],
        'acquittements': <dynamic>[],
        'eventTypes': <dynamic>[],
        'voiceProfile': null,
      };
      final payload = BackupPayload.fromJson(json);
      expect(payload.voiceProfile, isNull);
    });

    test('toJson() / fromJson() roundtrip — all voiceProfile fields preserved',
        () {
      const source = UserVoiceProfile(
        id: 'user',
        frequentKeywords: '{"famille":3,"courage":2}',
        frequentEmoji: '{"🎉":2}',
        frequentExpression: '{"bonne continuation":1}',
        observationCount: 12,
        updatedAt: 1700000000000,
      );

      final original = _emptyPayload(voiceProfile: source);
      final json = original.toJson();
      final restored = BackupPayload.fromJson(json);

      expect(restored.voiceProfile, isNotNull);
      expect(
        restored.voiceProfile!.frequentKeywords,
        equals('{"famille":3,"courage":2}'),
      );
      expect(restored.voiceProfile!.frequentEmoji, equals('{"🎉":2}'));
      expect(
        restored.voiceProfile!.frequentExpression,
        equals('{"bonne continuation":1}'),
      );
      expect(restored.voiceProfile!.observationCount, equals(12));
      expect(restored.voiceProfile!.updatedAt, equals(1700000000000));
    });

    test('toJson() with null voiceProfile → json voiceProfile is null', () {
      final payload = _emptyPayload();
      final json = payload.toJson();
      expect(json['voiceProfile'], isNull);
    });
  });
}
