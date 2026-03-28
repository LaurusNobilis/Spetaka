import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/actions/phone_normalizer.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../features/settings/data/category_tags_provider.dart';
import '../data/friend_repository_provider.dart';
import '../domain/friend_form_draft.dart';
import '../domain/friend_tags_codec.dart';
import '../providers/friend_form_draft_provider.dart';

/// Add / Edit Friend screen — contact import + manual entry (Stories 2.1, 2.2 & 2.7).
///
/// **Create mode** ([editFriendId] == null): two entry paths:
/// - "Import from contacts": system contact picker with READ_CONTACTS (2.1/AC1-5).
/// - "Enter manually": validated Form (2.2/AC1-4).
///
/// **Edit mode** ([editFriendId] != null): pre-fills name, mobile, tags, notes
/// from existing record (2.7/AC1-2), calls [FriendRepository.update] on save
/// (2.7/AC3), and returns to the detail screen reactively (2.7/AC4).
///
/// AC implementation map:
///   2.1/AC1  — [_importFromContacts] requests permission on tap only.
///   2.1/AC2  — [FlutterContacts.openExternalPick] opens the system picker.
///   2.1/AC3  — [_primaryPhone] extracts the best mobile; [PhoneNormalizer].
///   2.1/AC4  — only name + mobile are read; no photo import.
///   2.1/AC5  — permission denied shows a snackbar; manual entry visible.
///   2.1/AC6  — inserts via [FriendRepository.insert] UUID v4 + careScore 0.0.
///   2.2/AC1  — Form validates: name non-empty + phone parseable by normalizer.
///   2.2/AC2  — Inline field errors only; no snackbar for validation failures.
///   2.2/AC3  — UUID v4, E.164 mobile, careScore 0.0 persisted to SQLite.
///   2.2/AC4  — Primary buttons/Back meet 48 dp minimum touch target (NFR15).
///   2.7/AC1  — EditFriendRoute(id) opens this screen prefilled.
///   2.7/AC2  — Editable fields: name, mobile, tags, notes.
///   2.7/AC3  — [FriendRepository.update] preserves UUID + createdAt, sets updatedAt.
///   2.7/AC4  — Returns to FriendCardScreen after save; reactive stream refreshes.
///   2.7/AC5  — Mobile validation identical to create path (same validators).
class FriendFormScreen extends ConsumerStatefulWidget {
  const FriendFormScreen({super.key, this.editFriendId});

  /// When non-null the screen is in edit mode for the friend with this id.
  ///
  /// Story 2.7: pre-fills the form and calls [FriendRepository.update] on save.
  final String? editFriendId;

  @override
  ConsumerState<FriendFormScreen> createState() => _FriendFormScreenState();
}

class _FriendFormScreenState extends ConsumerState<FriendFormScreen> {
  bool _isLoading = false;

  bool _isManualFormVisible = false;
  Set<String> _selectedTags = <String>{};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  /// The original friend being edited; preserved to carry forward read-only
  /// fields (id, careScore, isConcernActive, concernNote, createdAt).
  Friend? _editFriend;

  /// True while the existing record is being loaded in edit mode.
  bool _editLoading = false;

  /// 10.4 — debounce timer for auto-saving draft (AC 2, 11).
  Timer? _debounceTimer;

  /// 10.4 — whether the draft-resuming banner is visible (AC 1).
  bool _showDraftBanner = false;

  /// Suppresses auto-save while programmatically mutating form fields.
  bool _suppressDraftAutoSave = false;

  bool get _isEditMode => widget.editFriendId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _editLoading = true;
      _isManualFormVisible = true; // go straight to form in edit mode
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditFriend());
    } else {
      // 10.4/AC1 — restore draft in create mode.
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // 10.4/AC11
    _nameController.dispose();
    _mobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Edit mode — load existing friend and pre-fill form (2.7/AC1, AC2)
  // -------------------------------------------------------------------------

  Future<void> _loadEditFriend() async {
    try {
      final friend = await ref
          .read(friendRepositoryProvider)
          .findById(widget.editFriendId!);
      if (!mounted) return;
      if (friend == null) {
        _showSnackBar(context.l10n.friendNotFound);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _editFriend = friend;
        _nameController.text = friend.name;
        _mobileController.text = friend.mobile;
        _notesController.text = friend.notes ?? '';
        _selectedTags = decodeFriendTags(friend.tags).toSet();
        _editLoading = false;
      });
      // 10.4/AC1 — check for draft after loading persisted values in edit mode.
      final draft = ref.read(friendFormDraftProvider);
      if (draft != null) {
        _suppressDraftAutoSave = true;
        setState(() {
          _nameController.text = draft.name ?? '';
          _mobileController.text = draft.mobile ?? '';
          _notesController.text = draft.notes ?? '';
          _selectedTags = draft.categoryTags.toSet();
          _showDraftBanner = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _suppressDraftAutoSave = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(context.l10n.somethingWentWrong);
        Navigator.of(context).pop();
      }
    }
  }

  // -------------------------------------------------------------------------
  // 10.4 — Session-draft auto-save (AC 1, 2, 3, 4, 11)
  // -------------------------------------------------------------------------

  /// Restore a previously saved draft (AC 1).
  void _restoreDraft() {
    final draft = ref.read(friendFormDraftProvider);
    if (draft == null) return;
    _suppressDraftAutoSave = true;
    setState(() {
      _nameController.text = draft.name ?? '';
      _mobileController.text = draft.mobile ?? '';
      _notesController.text = draft.notes ?? '';
      _selectedTags = draft.categoryTags.toSet();
      _isManualFormVisible = true;
      _showDraftBanner = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressDraftAutoSave = false;
    });
  }

  /// Schedule a debounced draft save (AC 2). Inline Timer – no shared utility.
  void _scheduleDraftSave() {
    if (_suppressDraftAutoSave) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(friendFormDraftProvider.notifier).update(_buildDraft());
    });
  }

  /// Build a [FriendFormDraft] from the current form state.
  FriendFormDraft _buildDraft() {
    return FriendFormDraft(
      name: _nameController.text,
      mobile: _mobileController.text,
      notes: _notesController.text,
      categoryTags: _selectedTags.toList(),
      isConcernActive: _editFriend?.isConcernActive ?? false,
      concernNote: _editFriend?.concernNote,
    );
  }

  /// Clear draft and reset form (AC 4).
  void _discardDraft() {
    _debounceTimer?.cancel();
    _suppressDraftAutoSave = true;
    ref.read(friendFormDraftProvider.notifier).clear();
    setState(() {
      _showDraftBanner = false;
      if (_isEditMode && _editFriend != null) {
        // Reset to persisted values in edit mode.
        _nameController.text = _editFriend!.name;
        _mobileController.text = _editFriend!.mobile;
        _notesController.text = _editFriend!.notes ?? '';
        _selectedTags = decodeFriendTags(_editFriend!.tags).toSet();
      } else {
        // Reset to empty in create mode.
        _formKey.currentState?.reset();
        _nameController.clear();
        _mobileController.clear();
        _notesController.clear();
        _selectedTags.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressDraftAutoSave = false;
    });
  }

  // -------------------------------------------------------------------------
  // Contact import flow — 2.1/AC1, AC2, AC3, AC4, AC5, AC6
  // -------------------------------------------------------------------------

  Future<void> _importFromContacts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 2.1/AC1 / NFR9: request READ_CONTACTS only at the point of use.
      final granted = await FlutterContacts.requestPermission(readonly: true);

      if (!granted) {
        // 2.1/AC5: no dead-end — inform user and keep manual entry visible.
        _showSnackBar(errorMessageFor(const ContactPermissionDeniedAppError()));
        _showManualForm();
        return;
      }

      // 2.1/AC2: open the system contact picker.
      final contact = await FlutterContacts.openExternalPick();

      if (contact == null) {
        // User cancelled the picker — nothing to do.
        return;
      }

      // Fetch full contact details (phones) — requires READ_CONTACTS.
      // 2.1/AC4: withAccounts/withPhoto explicitly false.
      final full = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: false, // AC4: no photo import in v1
      );

      if (full == null) {
        _showSnackBar(errorMessageFor(const ContactDetailsLoadFailedAppError()));
        return;
      }

      // 2.1/AC3: extract primary mobile number.
      final rawPhone = _primaryPhone(full.phones);
      if (rawPhone == null) {
        _showSnackBar(errorMessageFor(const ContactHasNoPhoneAppError()));
        _showManualForm(prefillName: _safeContactName(full.displayName));
        return;
      }

      // 2.1/AC3: normalise to E.164 via PhoneNormalizer.
      final String normalizedPhone;
      try {
        normalizedPhone = const PhoneNormalizer().normalize(rawPhone);
      } on PhoneNormalizationAppError catch (e) {
        // Do NOT surface raw phone number (PII); use typed error message.
        _showSnackBar(errorMessageFor(e));
        return;
      }

      // 2.1/AC3: prefill the form with display name + primary mobile;
      // user confirms with Save to avoid silently persisting incorrect data.
      _showManualForm(
        prefillName: _safeContactName(full.displayName),
        prefillMobile: normalizedPhone,
      );
    } on AppError catch (e) {
      _showSnackBar(errorMessageFor(e));
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Helper: select primary mobile phone
  // -------------------------------------------------------------------------

  /// Returns the raw number string for the best phone:
  /// prefers a [PhoneLabel.mobile]-labelled entry; falls back to the first
  /// available phone.  Returns null if [phones] is empty.
  String? _primaryPhone(List<Phone> phones) {
    if (phones.isEmpty) return null;
    final primary = phones.where((p) => p.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.number;

    final preferred = phones.firstWhere(
      (p) => _isMobileLabel(p.label),
      orElse: () => phones.first,
    );
    return preferred.number;
  }

  bool _isMobileLabel(PhoneLabel label) {
    return switch (label) {
      PhoneLabel.mobile => true,
      PhoneLabel.workMobile => true,
      PhoneLabel.iPhone => true,
      PhoneLabel.main => true,
      PhoneLabel.mms => true,
      _ => false,
    };
  }

  String _safeContactName(String displayName) => displayName.trim();

  void _showManualForm({String? prefillName, String? prefillMobile}) {
    if (!mounted) return;
    setState(() {
      if (!_isManualFormVisible) {
        _selectedTags.clear();
      }
      _isManualFormVisible = true;
      if (prefillName != null) {
        _nameController.text = prefillName;
      }
      if (prefillMobile != null) {
        _mobileController.text = prefillMobile;
      }
    });
  }

  // -------------------------------------------------------------------------
  // Save — 2.2/AC1, AC2, AC3
  // -------------------------------------------------------------------------

  Future<void> _saveFriend() async {
    if (_isLoading) return;

    // 2.2/AC1 & AC2: trigger Form validation — errors render inline in fields.
    // Return early without SnackBar if validation fails.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Capture the latest form state synchronously so a save failure preserves
    // the user's most recent edits even if the debounce had not fired yet.
    final pendingDraft = _buildDraft();
    _debounceTimer?.cancel();
    _debounceTimer = null;

    setState(() => _isLoading = true);
    try {
      final rawName = _nameController.text.trim();
      final rawMobile = _mobileController.text.trim();

      // Normalize phone — guaranteed to succeed: the Form validator already
      // confirmed parseability via PhoneNormalizer.normalize() on the same
      // trimmed value. No defensive try/catch here; an unexpected error will
      // fall through to the outer AppError / catch-all handlers below.
      final normalizedMobile = const PhoneNormalizer().normalize(rawMobile);

      final now = DateTime.now().millisecondsSinceEpoch;
      final encodedTags = encodeFriendTags(_selectedTags);
      final rawNotes = _notesController.text.trim();

      if (_isEditMode && _editFriend != null) {
        // 2.7/AC3: update preserves UUID + createdAt; sets updatedAt.
        final updated = _editFriend!.copyWith(
          name: rawName,
          mobile: normalizedMobile,
          tags: Value(encodedTags),
          notes: Value(rawNotes.isEmpty ? null : rawNotes),
          updatedAt: now,
        );
        await ref.read(friendRepositoryProvider).update(updated);
        ref.read(friendFormDraftProvider.notifier).clear(); // 10.4/AC3
        if (mounted) {
          // 2.7/AC4 + 4.7/AC6: when edit is stacked above the detail overlay,
          // pop back to preserve the shell page underneath. Deep links without
          // history still land on the detail route explicitly.
          if (context.canPop()) {
            context.pop();
          } else {
            context.replace(FriendDetailRoute(widget.editFriendId!).location);
          }
        }
      } else {
        final friend = Friend(
          id: const Uuid().v4(),
          name: rawName,
          mobile: normalizedMobile,
          tags: encodedTags,
          notes: rawNotes.isEmpty ? null : rawNotes,
          careScore: 0.0,
          isConcernActive: false,
          concernNote: null,
          isDemo: false,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(friendRepositoryProvider).insert(friend);
        ref.read(friendFormDraftProvider.notifier).clear(); // 10.4/AC3
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            const FriendsRoute().go(context);
          }
        }
      }
    } on AppError catch (e) {
      ref.read(friendFormDraftProvider.notifier).update(pendingDraft);
      _showSnackBar(errorMessageFor(e));
    } catch (_) {
      ref.read(friendFormDraftProvider.notifier).update(pendingDraft);
      if (mounted) _showSnackBar(context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Helper: show non-validation error snackbar (AC2 compliance)
  // -------------------------------------------------------------------------

  /// Use only for non-validation errors (permissions, contact import failures,
  /// unexpected exceptions).  Validation errors must be inline — see
  /// [TextFormField] validators in [_buildManualForm].
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? context.l10n.editFriendTitle : context.l10n.addFriendTitle;
    final availableTags = ref
        .watch(categoryTagsProvider)
        .map((t) => t.name)
        .toList();

    if (_isEditMode && _editLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            Semantics(
              label: context.l10n.navDaily,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.view_agenda_outlined),
                tooltip: context.l10n.navDaily,
                onPressed: () => const HomeRoute().go(context),
              ),
            ),
            Semantics(
              label: context.l10n.navFriends,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: context.l10n.navFriends,
                onPressed: () => const FriendsRoute().go(context),
              ),
            ),
            Semantics(
              label: context.l10n.navSettings,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: context.l10n.navSettings,
                onPressed: () => const SettingsRoute().push(context),
              ),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Semantics(
            label: context.l10n.navDaily,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.view_agenda_outlined),
              tooltip: context.l10n.navDaily,
              onPressed: () => const HomeRoute().go(context),
            ),
          ),
          Semantics(
            label: context.l10n.navFriends,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: context.l10n.navFriends,
              onPressed: () => const FriendsRoute().go(context),
            ),
          ),
          Semantics(
            label: context.l10n.navSettings,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.l10n.navSettings,
              onPressed: () => const SettingsRoute().push(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _isManualFormVisible
            ? _buildManualForm(context, availableTags)
            : _buildChoiceButtons(context),
      ),
    );
  }

  /// 10.4/AC1 — Draft-resuming banner with discard action (AC 4).
  Widget _buildDraftBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.draftResumingBanner,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: _discardDraft,
            child: Text(context.l10n.draftDiscard),
          ),
        ],
      ),
    );
  }

  /// Manual-entry form — 2.2/AC1, AC2, AC3, AC4.
  Widget _buildManualForm(BuildContext context, List<String> availableTags) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 10.4/AC1 — draft-resuming banner.
          if (_showDraftBanner)
            _buildDraftBanner(context),
          Text(
            context.l10n.enterDetails,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Category tags — Story 2.3.
          Text(
            context.l10n.categoryTagsLabel,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: context.l10n.categoryTagsLabel,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tag in availableTags)
                  _TagChip(
                    tag: tag,
                    selected: _selectedTags.contains(tag),
                    onChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                      _scheduleDraftSave(); // 10.4/AC2
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name field — 2.2/AC1: non-empty check.
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.l10n.nameLabel),
            onChanged: (_) => _scheduleDraftSave(), // 10.4/AC2
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return errorMessageFor(const FriendNameMissingAppError());
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Mobile field — 2.2/AC1 + 2.7/AC5: parseability via PhoneNormalizer.
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.mobileLabel,
              hintText: context.l10n.mobilePlaceholder,
            ),
            onChanged: (_) => _scheduleDraftSave(), // 10.4/AC2
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return errorMessageFor(const FriendMobileMissingAppError());
              }
              try {
                const PhoneNormalizer().normalize(value.trim());
                return null; // valid
              } on PhoneNormalizationAppError catch (e) {
                return errorMessageFor(e); // inline error, no SnackBar (AC2/AC5)
              }
            },
          ),
          const SizedBox(height: 16),

          // Notes field — 2.7/AC2: editable free-text note.
          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.newline,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n.notesLabel,
              hintText: context.l10n.optionalContextNotes,
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _scheduleDraftSave(), // 10.4/AC2
            onFieldSubmitted: (_) => _saveFriend(),
          ),
          const SizedBox(height: 24),

          // Save — 2.2/AC4: minimumSize 48 dp height.
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _isLoading ? null : _saveFriend,
            child: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onPrimary,
                    ),
                  )
                : Text(context.l10n.actionSave),
          ),
          const SizedBox(height: 12),

          // Back — 2.2/AC4: minimumSize 48 dp height.
          // In edit mode, pop back to the detail screen instead of resetting.
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditMode) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _isManualFormVisible = false;
                        _formKey.currentState?.reset();
                        _nameController.clear();
                        _mobileController.clear();
                        _notesController.clear();
                        _selectedTags.clear();
                      });
                    }
                  },
            child: Text(context.l10n.actionBack),
          ),
        ],
      ),
    );
  }

  /// Initial choice screen — Import from contacts or Enter manually.
  Widget _buildChoiceButtons(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How would you like to add this friend?',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Primary action — import from contacts (2.1/AC1, AC2).
        // 2.2/AC4: minimumSize 48 dp height.
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _isLoading ? null : _importFromContacts,
          icon: _isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onPrimary,
                  ),
                )
              : const Icon(Icons.contacts_outlined),
          label: Text(context.l10n.importFromContacts),
        ),

        const SizedBox(height: 16),

        // 2.1/AC5: manual entry fallback.
        // 2.2/AC4: minimumSize 48 dp height.
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _isLoading ? null : () => _showManualForm(),
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.l10n.enterManually),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onChanged,
  });

  final String tag;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tag: $tag, ${selected ? 'selected' : 'not selected'}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: FilterChip(
          label: Text(tag),
          selected: selected,
          onSelected: onChanged,
        ),
      ),
    );
  }
}
