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
        _showError(
          'Contact permission denied. '
          'Please use "Enter manually" below.',
        );
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
        _showError('Could not load contact details. Please try again.');
        return;
      }

      // AC3: extract primary mobile number.
      final rawPhone = _primaryPhone(full.phones);
      if (rawPhone == null) {
        _showError('This contact has no phone number. Please enter it manually.');
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

      // AC3: display name from contact.
      final name = full.displayName.trim().isEmpty
          ? 'Unknown'
          : full.displayName.trim();

      // AC6: build Friend domain object (UUID v4, careScore 0.0, nulls for
      //      story-2.2 fields: notes, concernNote).
      final now = DateTime.now().millisecondsSinceEpoch;
      final friend = Friend(
        id: const Uuid().v4(),
        name: name,
        mobile: normalizedPhone,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        createdAt: now,
        updatedAt: now,
      );

      // AC6: persist via FriendRepository — encryption boundary lives there.
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
  // Helper: select primary mobile phone
  // -------------------------------------------------------------------------

  /// Returns the raw number string for the best phone:
  /// prefers a [PhoneLabel.mobile]-labelled entry; falls back to the first
  /// available phone.  Returns null if [phones] is empty.
  String? _primaryPhone(List<Phone> phones) {
    if (phones.isEmpty) return null;
    final mobile = phones.firstWhere(
      (p) => p.label == PhoneLabel.mobile,
      orElse: () => phones.first,
    );
    return mobile.number;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
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
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.contacts_outlined),
              label: const Text('Import from contacts'),
            ),

            const SizedBox(height: 16),

            // AC5: manual entry fallback — placeholder pending Story 2.2.
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manual entry coming soon (Story 2.2).'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Enter manually'),
            ),
          ],
        ),
      ),
    );
  }
}
