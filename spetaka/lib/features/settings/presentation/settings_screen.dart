import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../backup/providers/backup_providers.dart';
import '../../daily/data/density_provider.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Main Settings screen — single organised entry point for all app settings.
///
/// Sections (Story 7.1):
///  - **Backup & Restore** — export, import, passphrase note, reset
///  - **Display** — density-mode toggle (compact / expanded)
///  - **Event Types** — deep-link to the Manage Event Types screen
///  - **Sync & Backup** — Phase 2 placeholder (disabled)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackupSection(),
            _DisplaySection(),
            _EventTypesSection(),
            _SyncPlaceholderSection(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section heading
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Backup & Restore section
// ---------------------------------------------------------------------------

class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  // --------------------------------------------------------------------------
  // Export
  // --------------------------------------------------------------------------

  Future<void> _onExport() async {
    final passphrase = await _showPassphraseDialog(
      context,
      title: 'Export backup',
      hint:
          'Choose a passphrase to protect your backup. Write it down somewhere safe — it cannot be recovered.',
      confirmField: true,
    );
    if (passphrase == null || !mounted) return;

    ref.read(backupExportProvider.notifier).export(passphrase);
  }

  // --------------------------------------------------------------------------
  // Import
  // --------------------------------------------------------------------------

  Future<void> _onImport() async {
    // Step 1 — pick a .enc file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['enc'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null || !mounted) return;

    // Step 2 — ask for passphrase
    final passphrase = await _showPassphraseDialog(
      context,
      title: 'Import backup',
      hint: 'Enter the passphrase you used when creating this backup.',
      confirmField: false,
    );
    if (passphrase == null || !mounted) return;

    ref.read(backupImportProvider.notifier).importBackup(filePath, passphrase);
  }

  // --------------------------------------------------------------------------
  // Reset backup settings
  // --------------------------------------------------------------------------

  Future<void> _onResetBackupSettings() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset backup settings'),
        content: const Text(
          'This will reset the encryption salt stored on this device.\n\n'
          'Your existing backups are NOT affected — each backup file '
          'contains its own encryption data. You may need to re-enter '
          'your passphrase on your next export.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final passphrase = await _showPassphraseDialog(
      context,
      title: 'Reset backup settings',
      hint: 'Enter your passphrase to continue. It is never stored.',
      confirmField: false,
    );
    if (passphrase == null || !mounted) return;

    ref.read(backupResetProvider.notifier).resetBackupSettings(passphrase);
  }

  void _handleResetState(AsyncValue<bool>? prev, AsyncValue<bool> next) {
    if (!mounted) return;
    next.whenOrNull(
      data: (done) {
        if (done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup settings have been reset.')),
          );
          ref.read(backupResetProvider.notifier).reset();
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : 'Reset failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(backupResetProvider.notifier).reset();
      },
    );
  }

  // --------------------------------------------------------------------------
  // Listeners (export / import state)
  // --------------------------------------------------------------------------

  void _handleExportState(
    AsyncValue<String?>? prev,
    AsyncValue<String?> next,
  ) {
    if (!mounted) return;
    next.whenOrNull(
      data: (path) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup saved to:\n$path'),
              duration: const Duration(seconds: 6),
            ),
          );
          ref.read(backupExportProvider.notifier).reset();
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : 'Export failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(backupExportProvider.notifier).reset();
      },
    );
  }

  void _handleImportState(AsyncValue<bool>? prev, AsyncValue<bool> next) {
    if (!mounted) return;
    next.whenOrNull(
      data: (success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully.')),
          );
          ref.read(backupImportProvider.notifier).reset();
          const HomeRoute().go(context);
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : 'Import failed. Please check your passphrase and file.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(backupImportProvider.notifier).reset();
      },
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(backupExportProvider, _handleExportState);
    ref.listen(backupImportProvider, _handleImportState);
    ref.listen(backupResetProvider, _handleResetState);

    final exportState = ref.watch(backupExportProvider);
    final importState = ref.watch(backupImportProvider);
    final resetState = ref.watch(backupResetProvider);

    final isExporting = exportState is AsyncLoading;
    final isImporting = importState is AsyncLoading;
    final isResetting = resetState is AsyncLoading;

    final isBusy = isExporting || isImporting || isResetting;
    final resetOnTap = isBusy ? null : _onResetBackupSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Backup & Restore'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Your passphrase encrypts your backup. It is never stored. If you '
            'lose it, your backup cannot be recovered.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.upload_file_outlined,
          label: 'Export backup',
          semanticsLabel: 'Export encrypted backup',
          isLoading: isExporting,
          onTap: isBusy ? null : _onExport,
        ),
        _ActionTile(
          icon: Icons.download_outlined,
          label: 'Import backup',
          semanticsLabel: 'Import encrypted backup from file',
          isLoading: isImporting,
          onTap: isBusy ? null : _onImport,
        ),
        Semantics(
          label: 'Reset backup settings',
          button: resetOnTap != null,
          child: ListTile(
            minVerticalPadding: 12,
            enabled: resetOnTap != null,
            leading: Icon(
              Icons.restore_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Reset backup settings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            trailing: isResetting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : null,
            onTap: resetOnTap,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable tile with loading state
// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: ListTile(
        minVerticalPadding: 12, // ≥ 48 dp total tap height
        leading: Icon(icon),
        title: Text(label),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Passphrase dialog
// ---------------------------------------------------------------------------

/// Shows a modal dialog that collects a passphrase.
///
/// When [confirmField] is `true`, a second "confirm passphrase" field is shown
/// and both values must match before the dialog can be committed.
///
/// Returns `null` if the user cancels.
Future<String?> _showPassphraseDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required bool confirmField,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PassphraseDialog(
      title: title,
      hint: hint,
      confirmField: confirmField,
    ),
  );
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({
    required this.title,
    required this.hint,
    required this.confirmField,
  });

  final String title;
  final String hint;
  final bool confirmField;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _passphraseCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    // Zero-out passphrase strings before discarding controllers.
    _passphraseCtrl.clear();
    _confirmCtrl.clear();
    _passphraseCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_passphraseCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.hint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Passphrase field
              TextFormField(
                controller: _passphraseCtrl,
                obscureText: _obscure1,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.none,
                textInputAction: widget.confirmField
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: widget.confirmField ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Passphrase',
                  suffixIcon: IconButton(
                    tooltip: _obscure1 ? 'Show passphrase' : 'Hide passphrase',
                    icon: Icon(
                      _obscure1 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter a passphrase.'
                    : null,
              ),
              if (widget.confirmField) ...[
                const SizedBox(height: 12),
                // Confirm field
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm passphrase',
                    suffixIcon: IconButton(
                      tooltip:
                          _obscure2 ? 'Show passphrase' : 'Hide passphrase',
                      icon: Icon(
                        _obscure2 ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your passphrase.';
                    }
                    if (v != _passphraseCtrl.text) {
                      return 'Passphrases do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Display section — density preference toggle
// ---------------------------------------------------------------------------

class _DisplaySection extends ConsumerWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(densityModeProvider);
    final isCompact = mode == DensityMode.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Display'),
        Semantics(
          label: isCompact ? 'Compact view, on' : 'Compact view, off',
          toggled: isCompact,
          excludeSemantics: true,
          child: SwitchListTile(
            key: const Key('density_switch'),
            secondary: const Icon(Icons.density_medium_outlined),
            title: const Text('Compact view'),
            subtitle: const Text('Show more friends on screen at once'),
            value: isCompact,
            onChanged: (_) => ref.read(densityModeProvider.notifier).toggle(),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Event Types section — deep link to Manage Event Types
// ---------------------------------------------------------------------------

class _EventTypesSection extends StatelessWidget {
  const _EventTypesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Event Types'),
        Semantics(
          label: 'Manage event types',
          button: true,
          child: ListTile(
            minVerticalPadding: 12,
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Manage Event Types'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ManageEventTypesRoute().go(context),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sync & Backup — Phase 2 placeholder (disabled)
// ---------------------------------------------------------------------------

class _SyncPlaceholderSection extends StatelessWidget {
  const _SyncPlaceholderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Sync & Backup'),
        Semantics(
          label: 'Sync & Backup \u2014 Coming in Phase 2, not yet available',
          enabled: false,
          child: const ListTile(
            minVerticalPadding: 12,
            enabled: false,
            leading: Icon(Icons.cloud_sync_outlined),
            title: Text('Sync & Backup'),
            subtitle: Text('Coming in Phase 2'),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
