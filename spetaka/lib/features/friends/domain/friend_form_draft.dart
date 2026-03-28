/// In-memory session draft for the friend form (Story 10.4).
///
/// Holds the current state of a partially-filled friend form so it can be
/// restored if the user navigates away and returns during the same session.
///
/// This is a plain Dart class — no Drift table, no code generation, no
/// persistence beyond process lifetime (architecture addendum Q5).
class FriendFormDraft {
  const FriendFormDraft({
    this.name,
    this.mobile,
    this.notes,
    this.categoryTags = const [],
    this.isConcernActive = false,
    this.concernNote,
  });

  final String? name;
  final String? mobile;
  final String? notes;
  final List<String> categoryTags;
  final bool isConcernActive;
  final String? concernNote;
}
