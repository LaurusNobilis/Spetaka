import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Predefined friend category tags (Story 2.3).
///
/// This list defines the canonical ordering used for storage and display.
const predefinedFriendTags = <String>[
  'Family',
  'Close friends',
  'Friends',
  'Work',
  'Other',
];

final Map<String, int> _tagOrder = <String, int>{
  for (var i = 0; i < predefinedFriendTags.length; i++) predefinedFriendTags[i]: i,
};

/// Encodes a set of selected tags into the stable storage format.
///
/// Returns `null` when [tags] is empty (represents "no tags").
///
/// Storage format (recommended): JSON array string, deterministically ordered.
/// Example: `["Family","Work"]`.
String? encodeFriendTags(Set<String> tags) {
  if (tags.isEmpty) return null;

  final filtered = tags.where(_tagOrder.containsKey).toList(growable: false);
  if (filtered.isEmpty) return null;

  filtered.sort((a, b) => (_tagOrder[a] ?? 1 << 30).compareTo(_tagOrder[b] ?? 1 << 30));
  return jsonEncode(filtered);
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
      if (item is String && _tagOrder.containsKey(item)) {
        tags.add(item);
      }
    }

    final ordered = tags.toList(growable: false)
      ..sort((a, b) => (_tagOrder[a] ?? 1 << 30).compareTo(_tagOrder[b] ?? 1 << 30));
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
