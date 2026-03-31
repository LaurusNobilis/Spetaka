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
  static const _maxEmojis = 5;
  static const _maxExpressions = 10;

  static const _stopWords = {
    'cette', 'avec', 'pour', 'dans', 'bien', 'mais', 'aussi', 'comme',
    'plus', 'tout', 'très', 'votre', 'notre', 'leur', 'vous', 'nous',
    'même', 'être', 'avoir', 'faire',
  };

  static final _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}]|'
    r'[\u{1F300}-\u{1F5FF}]|'
    r'[\u{1F680}-\u{1F6FF}]|'
    r'[\u{1F1E0}-\u{1F1FF}]|'
    r'[\u{2600}-\u{26FF}]|'
    r'[\u{2700}-\u{27BF}]',
    unicode: true,
  );

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

    final wordTokens = _tokenizeWords(text);

    // ── FrequentKeywords ────────────────────────────────────────────────────
    final keywordTokens = wordTokens
        .where((word) => word.length >= 4 && !_stopWords.contains(word))
        .toList();
    final keywordFreqMap = _decodeFrequencyMap(existing?.frequentKeywords);
    for (final token in keywordTokens) {
      keywordFreqMap[token] = (keywordFreqMap[token] ?? 0) + 1;
    }
    final trimmedKeywordMap = _trimFrequencyMap(keywordFreqMap, _maxKeywords);

    // ── FrequentEmoji ───────────────────────────────────────────────────────
    final emojiFreqMap = _decodeFrequencyMap(existing?.frequentEmoji);
    for (final emoji in _extractEmojis(text)) {
      emojiFreqMap[emoji] = (emojiFreqMap[emoji] ?? 0) + 1;
    }
    final trimmedEmojiMap = _trimFrequencyMap(emojiFreqMap, _maxEmojis);

    // ── FrequentExpression ──────────────────────────────────────────────────
    final exprFreqMap = _decodeFrequencyMap(existing?.frequentExpression);
    for (final expr in _extractExpressions(wordTokens)) {
      exprFreqMap[expr] = (exprFreqMap[expr] ?? 0) + 1;
    }
    final trimmedExprMap = _trimFrequencyMap(exprFreqMap, _maxExpressions);

    dev.log(
      'UserVoiceProfileRepository: observation #$newCount — '
      'keywordsCount=${trimmedKeywordMap.length}, '
      'emojiCount=${trimmedEmojiMap.length}, '
      'expressionCount=${trimmedExprMap.length}',
      name: 'voice_profile.repository',
    );

    await _db.userVoiceProfileDao.upsertProfile(
      UserVoiceProfilesCompanion(
        id: const Value('user'),
        frequentKeywords: Value(jsonEncode(trimmedKeywordMap)),
        frequentEmoji: Value(jsonEncode(trimmedEmojiMap)),
        frequentExpression: Value(jsonEncode(trimmedExprMap)),
        observationCount: Value(newCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Restores a profile from backup (Story 6.5 restore path).
  Future<void> restore(UserVoiceProfile profile) =>
      _db.userVoiceProfileDao.upsertProfile(
        UserVoiceProfilesCompanion(
          id: const Value('user'),
          frequentKeywords: Value(profile.frequentKeywords),
          frequentEmoji: Value(profile.frequentEmoji),
          frequentExpression: Value(profile.frequentExpression),
          observationCount: Value(profile.observationCount),
          updatedAt: Value(profile.updatedAt),
        ),
      );

  /// Minimum observations threshold for prompt injection.
  static int get minObservations => _minObservations;

  /// Returns top [limit] items from a JSON frequency map, sorted by frequency.
  static List<String> topItemsFromJson(
    String? serialized, {
    int limit = 3,
  }) {
    final sorted = _decodeFrequencyMap(serialized).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((entry) => entry.key).toList();
  }

  /// Alias kept for call-site compatibility.
  static List<String> topKeywordsFromJson(
    String? serializedKeywords, {
    int limit = 3,
  }) =>
      topItemsFromJson(serializedKeywords, limit: limit);

  static List<String> _extractEmojis(String text) =>
      _emojiRegex.allMatches(text).map((m) => m.group(0)!).toList();

  static List<String> _extractExpressions(List<String> wordTokens) {
    final significant = wordTokens
        .where((w) => w.length >= 3 && !_stopWords.contains(w))
        .toList();
    final bigrams = <String>[];
    for (var i = 0; i < significant.length - 1; i++) {
      bigrams.add('${significant[i]} ${significant[i + 1]}');
    }
    return bigrams;
  }

  static Map<String, int> _trimFrequencyMap(
    Map<String, int> freqMap,
    int maxEntries,
  ) {
    final sorted = freqMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return <String, int>{
      for (final entry in sorted.take(maxEntries)) entry.key: entry.value,
    };
  }

  static Map<String, int> _decodeFrequencyMap(String? serialized) {
    if (serialized == null || serialized.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(serialized);
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
