import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/category_tag.dart';

const _kPrefsKey = 'category_tags';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Notifier that loads/persists user-configurable category tags.
///
/// Initialises synchronously to [kDefaultCategoryTags] and immediately
/// schedules an async load from SharedPreferences (same pattern as
/// [DensityNotifier]).
class CategoryTagsNotifier extends Notifier<List<CategoryTag>> {
  @override
  List<CategoryTag> build() {
    Future.microtask(_loadFromPrefs);
    return List.of(kDefaultCategoryTags);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      state = decodeCategoryTags(raw);
    }
  }

  Future<void> _save(List<CategoryTag> tags) async {
    state = tags;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, encodeCategoryTags(tags));
  }

  /// Adds a new tag (name must be non-empty and unique, weight >= 0).
  Future<void> addTag(CategoryTag tag) async {
    if (tag.name.trim().isEmpty) return;
    if (state.any((t) => t.name == tag.name)) return;
    await _save([...state, tag]);
  }

  /// Replaces the tag at [index] with [updated].
  Future<void> updateTag(int index, CategoryTag updated) async {
    final current = List<CategoryTag>.of(state);
    if (index < 0 || index >= current.length) return;
    // Ensure name uniqueness (ignore the tag being edited).
    if (current
        .asMap()
        .entries
        .any((e) => e.key != index && e.value.name == updated.name)) {
      return;
    }
    current[index] = updated;
    await _save(current);
  }

  /// Removes the tag at [index].
  Future<void> removeTag(int index) async {
    final current = List<CategoryTag>.of(state);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    await _save(current);
  }

  /// Reorders a tag from [oldIndex] to [newIndex] (ReorderableListView semantics).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = List<CategoryTag>.of(state);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    await _save(current);
  }

  /// Resets to the default tag list.
  Future<void> resetToDefaults() async {
    await _save(List.of(kDefaultCategoryTags));
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Full list of category tags (name + weight), user-configurable.
final categoryTagsProvider =
    NotifierProvider<CategoryTagsNotifier, List<CategoryTag>>(
  CategoryTagsNotifier.new,
);

/// Derived Map<String, double> for use by the priority engine / care-score.
final categoryWeightsMapProvider = Provider<Map<String, double>>((ref) {
  final tags = ref.watch(categoryTagsProvider);
  return {for (final t in tags) t.name: t.weight};
});
