import 'dart:convert';
import 'dart:developer' as dev;

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';

part 'user_voice_profile_repository.g.dart';

@Riverpod(keepAlive: true)
UserVoiceProfileRepository userVoiceProfileRepository(Ref ref) {
  return UserVoiceProfileRepository(db: ref.watch(appDatabaseProvider));
}

class UserVoiceProfileRepository {
  UserVoiceProfileRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  static const _minObservations = 3;
  static const _maxKeywords = 10;

  // Formality markers (compared lowercase)
  static const _vouvoiementMarkers = [
    'vous', 'votre', 'vos', 'bonjour', 'madame', 'monsieur',
  ];
  static const _tutoiementMarkers = [
    'tu', 'ton', 'ta', 'tes', 'toi', 'coucou', 'salut', 'hey',
  ];
  static const _stopWords = {
    'cette', 'avec', 'pour', 'dans', 'bien', 'mais', 'aussi', 'comme',
    'plus', 'tout', 'très', 'votre', 'notre', 'leur', 'vous', 'nous',
    'même', 'être', 'avoir', 'faire',
  };

  Future<UserVoiceProfile?> getProfile() =>
      _db.userVoiceProfileDao.getProfile();

  Future<void> clearProfile() => _db.userVoiceProfileDao.deleteProfile();

  /// Observes [sentText] (the final message sent by the user) and updates
  /// the stored learning vectors incrementally. Fire-and-forget safe.
  Future<void> observe({required String sentText}) async {
    final text = sentText.trim();
    if (text.isEmpty) return;

    final existing = await _db.userVoiceProfileDao.getProfile();
    final oldCount = existing?.observationCount ?? 0;
    final newCount = oldCount + 1;

    // ── FormalityScore ──────────────────────────────────────────────────────
    final wordTokens = _tokenizeWords(text);
    final tokenSet = wordTokens.toSet();
    var vouCount = 0;
    var tuCount = 0;
    for (final marker in _vouvoiementMarkers) {
      if (tokenSet.contains(marker)) vouCount++;
    }
    for (final marker in _tutoiementMarkers) {
      if (tokenSet.contains(marker)) tuCount++;
    }
    final rawScore = 5 + (vouCount - tuCount).clamp(-3, 3);
    final oldFormality = existing?.formalityScore ?? 5;
    final newFormalityDouble =
        ((oldFormality * oldCount) + rawScore) / newCount;
    final newFormality = newFormalityDouble.round().clamp(0, 10);

    // ── AvgWordCount ────────────────────────────────────────────────────────
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final oldAvg = existing?.avgWordCount ?? 0.0;
    final newAvg = ((oldAvg * oldCount) + wordCount) / newCount;

    // ── FrequentKeywords ────────────────────────────────────────────────────
    final tokens = wordTokens
        .where((word) => word.length >= 4 && !_stopWords.contains(word))
        .toList();

    final freqMap = _decodeKeywordFrequencyMap(existing?.frequentKeywords);
    for (final token in tokens) {
      freqMap[token] = (freqMap[token] ?? 0) + 1;
    }
    final sorted = freqMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final trimmedFreqMap = <String, int>{
      for (final entry in sorted.take(_maxKeywords)) entry.key: entry.value,
    };

    dev.log(
      'UserVoiceProfileRepository: observation #$newCount — '
      'formality=$newFormality, avgWords=${newAvg.toStringAsFixed(1)}, '
      'keywordsCount=${trimmedFreqMap.length}',
      name: 'voice_profile.repository',
    );

    await _db.userVoiceProfileDao.upsertProfile(
      UserVoiceProfilesCompanion(
        id: const Value('user'),
        formalityScore: Value(newFormality),
        avgWordCount: Value(newAvg),
        frequentKeywords: Value(jsonEncode(trimmedFreqMap)),
        observationCount: Value(newCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Restores a profile from backup (AC6 — Story 6.5 restore path).
  Future<void> restore(UserVoiceProfile profile) =>
      _db.userVoiceProfileDao.upsertProfile(
        UserVoiceProfilesCompanion(
          id: const Value('user'),
          formalityScore: Value(profile.formalityScore),
          avgWordCount: Value(profile.avgWordCount),
          frequentKeywords: Value(profile.frequentKeywords),
          observationCount: Value(profile.observationCount),
          updatedAt: Value(profile.updatedAt),
        ),
      );

  /// Minimum observations threshold for prompt injection.
  static int get minObservations => _minObservations;

  static List<String> topKeywordsFromJson(
    String? serializedKeywords, {
    int limit = 3,
  }) {
    final sorted = _decodeKeywordFrequencyMap(serializedKeywords).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((entry) => entry.key).toList();
  }

  static Map<String, int> _decodeKeywordFrequencyMap(String? serializedKeywords) {
    if (serializedKeywords == null || serializedKeywords.isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(serializedKeywords);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        );
      }
      if (decoded is List<dynamic>) {
        final migrated = <String, int>{};
        for (var i = 0; i < decoded.length; i++) {
          final keyword = decoded[i];
          if (keyword is String && keyword.isNotEmpty) {
            migrated[keyword] = decoded.length - i;
          }
        }
        return migrated;
      }
    } catch (_) {
      // Corrupt JSON — start fresh.
    }

    return <String, int>{};
  }

  static List<String> _tokenizeWords(String text) =>
      text.toLowerCase().split(RegExp(r"[^a-zA-ZÀ-ÿ']+")).where((word) => word.isNotEmpty).toList();
}
