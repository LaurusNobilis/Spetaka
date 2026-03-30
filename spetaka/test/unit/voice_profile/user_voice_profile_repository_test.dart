// test/unit/voice_profile/user_voice_profile_repository_test.dart
//
// Tests Story 10.6 — UserVoiceProfile on-device learning
//
// Coverage:
//   AC1 — first observation increments observationCount to 1
//   AC2 — tutoiement text lowers formalityScore below default (5)
//   AC2 — vouvoiement text raises formalityScore above default (5)
//   AC3 — avgWordCount tracks word length of sent text
//   AC4 — three observations reach observationCount == 3
//   AC7 — restore() faithfully upserts the provided profile values

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

    test('tutoiement text drives formalityScore below 5', () async {
      // "coucou tu vas bien" — contains tutoiement markers (coucou, tu)
      await repo.observe(sentText: 'Coucou tu vas bien ?');
      final profile = await repo.getProfile();
      expect(profile!.formalityScore, lessThan(5));
    });

    test('vouvoiement text drives formalityScore above 5', () async {
      // "Bonjour, comment vous portez-vous" — vouvoiement markers (bonjour, vous)
      await repo.observe(sentText: 'Bonjour, comment vous portez-vous ?');
      final profile = await repo.getProfile();
      expect(profile!.formalityScore, greaterThan(5));
    });

    test('avgWordCount reflects word count of observed text', () async {
      // "un deux trois quatre cinq six sept huit neuf dix onze douze treize quatorze quinze seize dix-sept dix-huit dix-neuf vingt"
      // 20 whitespace-delimited tokens
      final twentyWordText = List.generate(20, (i) => 'mot${i + 1}').join(' ');
      await repo.observe(sentText: twentyWordText);
      final profile = await repo.getProfile();
      expect(profile!.avgWordCount, closeTo(20.0, 0.01));
    });

    test('three observations reach observationCount == 3', () async {
      await repo.observe(sentText: 'Premier message envoyé.');
      await repo.observe(sentText: 'Deuxième message envoyé.');
      await repo.observe(sentText: 'Troisième message envoyé.');
      final profile = await repo.getProfile();
      expect(profile!.observationCount, equals(3));
    });

    test('keywords are extracted and stored as JSON array', () async {
      // "famille courage santé" — all ≥4 chars, none are stop words
      await repo.observe(sentText: 'famille courage santé');
      final profile = await repo.getProfile();
      final keywords = jsonDecode(profile!.frequentKeywords) as Map<String, dynamic>;
      expect(keywords.keys, containsAll(['famille', 'courage']));
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
        formalityScore: 8,
        avgWordCount: 14.5,
        frequentKeywords: '["famille","courage","santé"]',
        observationCount: 12,
        updatedAt: 1700000000000,
      );

      await repo.restore(source);
      final stored = await repo.getProfile();

      expect(stored, isNotNull);
      expect(stored!.formalityScore, equals(8));
      expect(stored.avgWordCount, closeTo(14.5, 0.001));
      expect(stored.frequentKeywords, equals('["famille","courage","santé"]'));
      expect(stored.observationCount, equals(12));
    });

    test('restore() is idempotent — second call overwrites first', () async {
      const v1 = UserVoiceProfile(
        id: 'user',
        formalityScore: 3,
        avgWordCount: 5.0,
        frequentKeywords: '["old"]',
        observationCount: 2,
        updatedAt: 1000000,
      );
      const v2 = UserVoiceProfile(
        id: 'user',
        formalityScore: 7,
        avgWordCount: 20.0,
        frequentKeywords: '["new"]',
        observationCount: 5,
        updatedAt: 2000000,
      );

      await repo.restore(v1);
      await repo.restore(v2);
      final stored = await repo.getProfile();

      expect(stored!.formalityScore, equals(7));
      expect(stored.observationCount, equals(5));
    });
  });
}
