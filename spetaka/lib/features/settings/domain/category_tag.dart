import 'dart:convert';

/// A user-configurable category tag that can be assigned to friend cards.
///
/// [name]   — display label (e.g. "Family").
/// [weight] — contribution to the priority score (≥ 0.0).
class CategoryTag {
  const CategoryTag({required this.name, required this.weight});

  final String name;
  final double weight;

  CategoryTag copyWith({String? name, double? weight}) => CategoryTag(
        name: name ?? this.name,
        weight: weight ?? this.weight,
      );

  Map<String, dynamic> toJson() => {'name': name, 'weight': weight};

  factory CategoryTag.fromJson(Map<String, dynamic> json) => CategoryTag(
        name: json['name'] as String,
        weight: (json['weight'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is CategoryTag && other.name == name && other.weight == weight;

  @override
  int get hashCode => Object.hash(name, weight);

  @override
  String toString() => 'CategoryTag($name, $weight)';
}

// ---------------------------------------------------------------------------
// Default tags — single source of truth for the app.
// These are used the first time the app runs (no persisted state yet).
// ---------------------------------------------------------------------------

const List<CategoryTag> kDefaultCategoryTags = [
  CategoryTag(name: 'Famille', weight: 3.0),
  CategoryTag(name: 'Amis proches', weight: 2.5),
  CategoryTag(name: 'Amis', weight: 2.0),
  CategoryTag(name: 'Travail', weight: 1.5),
  CategoryTag(name: 'Autre', weight: 1.0),
];

// ---------------------------------------------------------------------------
// Serialisation helpers
// ---------------------------------------------------------------------------

String encodeCategoryTags(List<CategoryTag> tags) =>
    jsonEncode(tags.map((t) => t.toJson()).toList());

List<CategoryTag> decodeCategoryTags(String raw) {
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(CategoryTag.fromJson)
        .toList();
  } catch (_) {
    return List.of(kDefaultCategoryTags);
  }
}
