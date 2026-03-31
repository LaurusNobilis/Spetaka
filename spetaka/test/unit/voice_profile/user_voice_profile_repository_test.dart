// test/unit/voice_profile/user_voice_profile_repository_test.dart
//
// Tests UserVoiceProfile on-device learning (couche 4 refactor)
//
// Coverage:
//   AC1 — first observation increments observationCount to 1
//   AC2 — keywords are extracted and stored
//   AC3 — emoji characters are extracted and stored
//   AC4 — expressions (bigrams) are extracted and stored
//   AC5 — three observations reach observationCount == 3
//   AC6 — restore() faithfully upserts the provided profile values

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/voice_profile/data/user_voice_profile_repository.dart';

void main() {
  late AppDatabase db;
  late UserVoiceProfileRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserVoiceProfileRepository(db: db);
  });

  tearDown(() async => db.close());

  // ────────────────────────────────────────────────────────────────────────────
  group('observe()', () {
    test('first observation increments observationCount to 1', () async {
      await repo.observe(sentText: 'Salut, comment tu vas ?');
      final profile = await repo.getProfile();
      expect(profile, isNotNull);
      expect(profile!.observationCount, equals(1));
    });

    test('keywords are extracted and stored as JSON map', () async {
      // "famille courage santé" — all ≥4 chars, none are stop words
      await repo.observe(sentText: 'famille courage santé');
      final profile = await repo.getProfile();
      final keywords = jsonDecode(profile!.frequentKeywords) as Map<String, dynamic>;
      expect(keywords.keys, containsAll(['famille', 'courage']));
    });

    test('emojis are extracted and stored', () async {
      await repo.observe(sentText: 'Bravo ! 🎉 Tu as réussi 💪');
      final profile = await repo.getProfile();
      final emojis = jsonDecode(profile!.frequentEmoji) as Map<String, dynamic>;
      expect(emojis.keys, isNotEmpty);
    });

    test('expressions (bigrams) are extracted and stored', () async {
      // "bonne santé" → bigram of 2 significant words
      await repo.observe(sentText: 'bonne santé courage famille');
      final profile = await repo.getProfile();
      final expressions = jsonDecode(profile!.frequentExpression) as Map<String, dynamic>;
      expect(expressions.keys, isNotEmpty);
    });

    test('three observations reach observationCount == 3', () async {
      await repo.observe(sentText: 'Premier message envoyé.');
      await repo.observe(sentText: 'Deuxième message envoyé.');
      await repo.observe(sentText: 'Troisième message envoyé.');
      final profile = await repo.getProfile();
      expect(profile!.observationCount, equals(3));
    });

    test('observe() is idempotent on empty string — no row created', () async {
      await repo.observe(sentText: '   ');
      final profile = await repo.getProfile();
      expect(profile, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('restore()', () {
    test('restore() upserts exactly the provided profile values', () async {
      const source = UserVoiceProfile(
        id: 'user',
        frequentKeywords: '{"famille":3,"courage":2}',
        frequentEmoji: '{"🎉":2}',
        frequentExpression: '{"bonne santé":1}',
        observationCount: 12,
        updatedAt: 1700000000000,
      );

      await repo.restore(source);
      final stored = await repo.getProfile();

      expect(stored, isNotNull);
      expect(stored!.frequentKeywords, equals('{"famille":3,"courage":2}'));
      expect(stored.frequentEmoji, equals('{"🎉":2}'));
      expect(stored.frequentExpression, equals('{"bonne santé":1}'));
      expect(stored.observationCount, equals(12));
    });

    test('restore() is idempotent — second call overwrites first', () async {
      const v1 = UserVoiceProfile(
        id: 'user',
        frequentKeywords: '{"old":1}',
        frequentEmoji: '[]',
        frequentExpression: '[]',
        observationCount: 2,
        updatedAt: 1000000,
      );
      const v2 = UserVoiceProfile(
        id: 'user',
        frequentKeywords: '{"new":5}',
        frequentEmoji: '{"😊":3}',
        frequentExpression: '{"bonne continuation":2}',
        observationCount: 5,
        updatedAt: 2000000,
      );

      await repo.restore(v1);
      await repo.restore(v2);
      final stored = await repo.getProfile();

      expect(stored!.frequentKeywords, equals('{"new":5}'));
      expect(stored.observationCount, equals(5));
    });
  });
}
