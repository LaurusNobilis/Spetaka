import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/actions/phone_normalizer.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../data/friend_repository_provider.dart';

/// Add Friend screen — contact import + manual entry (Stories 2.1 & 2.2).
///
/// Provides two paths:
/// - "Import from contacts": opens the system contact picker after requesting
///   [READ_CONTACTS] at point-of-use only (AC1/2.1, NFR9).
/// - "Enter manually": validated Form with inline field errors (Story 2.2
///   AC1/AC2), 48 dp touch targets (AC4), UUID v4 id + E.164 mobile (AC3).
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
class FriendFormScreen extends ConsumerStatefulWidget {
  const FriendFormScreen({super.key});

  @override
  ConsumerState<FriendFormScreen> createState() => _FriendFormScreenState();
}

class _FriendFormScreenState extends ConsumerState<FriendFormScreen> {
  bool _isLoading = false;

  bool _isManualFormVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
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
      _showSnackBar('Something went wrong. Please try again.');
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
      final friend = Friend(
        id: const Uuid().v4(),
        name: rawName,
        mobile: normalizedMobile,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(friendRepositoryProvider).insert(friend);

      if (mounted) {
        const FriendsRoute().go(context);
      }
    } on AppError catch (e) {
      _showSnackBar(errorMessageFor(e));
    } catch (_) {
      _showSnackBar('Something went wrong. Please try again.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _isManualFormVisible ? _buildManualForm(context) : _buildChoiceButtons(context),
      ),
    );
  }

  /// Manual-entry form — 2.2/AC1, AC2, AC3, AC4.
  Widget _buildManualForm(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter details',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Name field — 2.2/AC1: non-empty check.
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return errorMessageFor(const FriendNameMissingAppError());
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Mobile field — 2.2/AC1: parseability via PhoneNormalizer.
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Mobile',
              hintText: 'e.g. 06 12 34 56 78',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return errorMessageFor(const FriendMobileMissingAppError());
              }
              try {
                const PhoneNormalizer().normalize(value.trim());
                return null; // valid
              } on PhoneNormalizationAppError catch (e) {
                return errorMessageFor(e); // inline error, no SnackBar (AC2)
              }
            },
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
                : const Text('Save'),
          ),
          const SizedBox(height: 12),

          // Back — 2.2/AC4: minimumSize 48 dp height.
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isManualFormVisible = false;
                      _nameController.clear();
                      _mobileController.clear();
                      _formKey.currentState?.reset();
                    });
                  },
            child: const Text('Back'),
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
          label: const Text('Import from contacts'),
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
          label: const Text('Enter manually'),
        ),
      ],
    );
  }
}
