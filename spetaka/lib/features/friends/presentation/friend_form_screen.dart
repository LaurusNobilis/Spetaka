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

/// Add Friend screen — contacts import entry point (Story 2.1).
///
/// Provides two paths:
/// - "Import from contacts": opens the system contact picker after requesting
///   [READ_CONTACTS] at point-of-use only (AC1, NFR9).
/// - "Enter manually": placeholder — full implementation in Story 2.2 (AC5,
///   no dead-end when permission is denied).
///
/// AC implementation map:
///   AC1  — [_importFromContacts] requests permission on tap only.
///   AC2  — [FlutterContacts.openExternalPick] opens the system picker.
///   AC3  — [_primaryPhone] extracts the best mobile; [PhoneNormalizer] normalises.
///   AC4  — only name + mobile are read; no photo import.
///   AC5  — permission denied shows a snackbar; manual entry button remains visible.
///   AC6  — inserts via [FriendRepository.insert] with UUID v4 + careScore 0.0.
class FriendFormScreen extends ConsumerStatefulWidget {
  const FriendFormScreen({super.key});

  @override
  ConsumerState<FriendFormScreen> createState() => _FriendFormScreenState();
}

class _FriendFormScreenState extends ConsumerState<FriendFormScreen> {
  bool _isLoading = false;

  bool _isManualFormVisible = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Contact import flow — AC1, AC2, AC3, AC4, AC5, AC6
  // -------------------------------------------------------------------------

  Future<void> _importFromContacts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // AC1 / NFR9: request READ_CONTACTS only at the point of use.
      final granted = await FlutterContacts.requestPermission(readonly: true);

      if (!granted) {
        // AC5: no dead-end — inform user and keep manual entry visible.
        _showError(errorMessageFor(const ContactPermissionDeniedAppError()));
        _showManualForm();
        return;
      }

      // AC2: open the system contact picker.
      final contact = await FlutterContacts.openExternalPick();

      if (contact == null) {
        // User cancelled the picker — nothing to do.
        return;
      }

      // Fetch full contact details (phones) — requires READ_CONTACTS.
      // AC4: withAccounts/withPhoto explicitly false; withProperties=true
      //      only to access phone numbers.
      final full = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: false, // AC4: no photo import in v1
      );

      if (full == null) {
        _showError(errorMessageFor(const ContactDetailsLoadFailedAppError()));
        return;
      }

      // AC3: extract primary mobile number.
      final rawPhone = _primaryPhone(full.phones);
      if (rawPhone == null) {
        _showError(errorMessageFor(const ContactHasNoPhoneAppError()));
        _showManualForm(prefillName: _safeContactName(full.displayName));
        return;
      }

      // AC3: normalise to E.164 via PhoneNormalizer.
      final String normalizedPhone;
      try {
        normalizedPhone = const PhoneNormalizer().normalize(rawPhone);
      } on PhoneNormalizationAppError catch (e) {
        // Do NOT surface raw phone number (PII); use typed error message.
        _showError(errorMessageFor(e));
        return;
      }

      // AC3: prefill the form with display name + primary mobile.
      // User confirms with a single tap (Save) to avoid silently persisting
      // incorrect data.
      _showManualForm(
        prefillName: _safeContactName(full.displayName),
        prefillMobile: normalizedPhone,
      );
    } on AppError catch (e) {
      _showError(errorMessageFor(e));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
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

  String _safeContactName(String displayName) {
    final trimmed = displayName.trim();
    return trimmed;
  }

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

  Future<void> _saveFriend() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final rawName = _nameController.text.trim();
      if (rawName.isEmpty) {
        _showError(errorMessageFor(const FriendNameMissingAppError()));
        return;
      }

      final rawMobile = _mobileController.text.trim();
      if (rawMobile.isEmpty) {
        _showError(errorMessageFor(const FriendMobileMissingAppError()));
        return;
      }

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
      _showError(errorMessageFor(e));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Helper: show error snackbar
  // -------------------------------------------------------------------------

  void _showError(String message) {
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
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _isManualFormVisible
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter details',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      hintText: 'e.g. 06 12 34 56 78',
                    ),
                    onSubmitted: (_) => _saveFriend(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
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
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isManualFormVisible = false;
                              _nameController.clear();
                              _mobileController.clear();
                            });
                          },
                    child: const Text('Back'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How would you like to add this friend?',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Primary action — import from contacts (AC1, AC2)
                  FilledButton.icon(
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

                  // AC5: manual entry fallback.
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _showManualForm(),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Enter manually'),
                  ),
                ],
              ),
      ),
    );
  }
}
