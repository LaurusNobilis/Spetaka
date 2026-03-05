import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Predefined friend category tags (Story 2.3).
///
/// Canonical ordering for display; also used as fallback when no custom tags
/// have been persisted yet.
///
/// NOTE: these names must stay in sync with
/// `settings/domain/category_tag.dart` → `kDefaultCategoryTags`.
const predefinedFriendTags = <String>[
  'Famille',
  'Amis proches',
  'Amis',
  'Travail',
  'Autre',
];

final Map<String, int> _tagOrder = <String, int>{
  for (var i = 0; i < predefinedFriendTags.length; i++) predefinedFriendTags[i]: i,
};

/// Encodes a set of selected tags into the stable storage format.
///
/// Returns `null` when [tags] is empty (represents "no tags").
///
/// Storage format: JSON array string.
/// Known tags are sorted by their canonical order; custom tags are appended
/// alphabetically.
String? encodeFriendTags(Set<String> tags) {
  if (tags.isEmpty) return null;

  final known = tags.where(_tagOrder.containsKey).toList(growable: false)
    ..sort((a, b) => _tagOrder[a]!.compareTo(_tagOrder[b]!));
  final custom = tags.where((t) => !_tagOrder.containsKey(t)).toList(growable: false)
    ..sort();
  final ordered = [...known, ...custom];
  if (ordered.isEmpty) return null;
  return jsonEncode(ordered);
}

/// Decodes the stored tags string (or legacy variants) into a canonical list.
///
/// - `null` or empty → `[]`
/// - JSON array string → list of tags
/// - Comma-separated string (legacy) → list of tags
///
/// Robustness: never throws. Corrupted values are treated as "no tags".
List<String> decodeFriendTags(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return const <String>[];

  try {
    final List<dynamic> parsed;

    if (trimmed.startsWith('[')) {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return const <String>[];
      parsed = decoded;
    } else {
      // Legacy fallback: comma-separated.
      parsed = trimmed
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    final tags = <String>{};
    for (final item in parsed) {
      // Accept any non-empty string — custom tags created by the user are
      // valid even if they are not in the predefined list.
      if (item is String && item.isNotEmpty) {
        tags.add(item);
      }
    }

    // Sort: known tags first (canonical order), then custom tags alphabetically.
    final ordered = tags.toList(growable: false)
      ..sort((a, b) {
        final ia = _tagOrder[a] ?? (1 << 30);
        final ib = _tagOrder[b] ?? (1 << 30);
        if (ia != ib) return ia.compareTo(ib);
        return a.compareTo(b);
      });
    return ordered;
  } catch (e, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'friend_tags_codec',
        context: ErrorDescription('Failed to decode stored friend tags; treating as empty.'),
      ),
    );
    return const <String>[];
  }
}
