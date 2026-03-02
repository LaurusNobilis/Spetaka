import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../backup/providers/backup_providers.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Main Settings screen — wraps all settings sections.
///
/// Currently contains a **Backup & Restore** section (Story 6.5).
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
          ],
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
      type: FileType.any,
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

    ref
        .read(backupImportProvider.notifier)
        .importBackup(filePath, passphrase);
  }

  // --------------------------------------------------------------------------
  // Listeners (export / import state)
  // --------------------------------------------------------------------------

  void _handleExportState(
      AsyncValue<String?>? prev, AsyncValue<String?> next,) {
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

    final exportState = ref.watch(backupExportProvider);
    final importState = ref.watch(backupImportProvider);

    final isExporting = exportState is AsyncLoading;
    final isImporting = importState is AsyncLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Backup & Restore',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Your passphrase is the only key to your backup. If you lose it, '
            'the backup cannot be recovered.',
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
          onTap: isExporting || isImporting ? null : _onExport,
        ),
        _ActionTile(
          icon: Icons.download_outlined,
          label: 'Import backup',
          semanticsLabel: 'Import encrypted backup from file',
          isLoading: isImporting,
          onTap: isExporting || isImporting ? null : _onImport,
        ),        const Divider(height: 24),
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
        minVerticalPadding: 12,   // ≥ 48 dp total tap height
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
                textInputAction: widget.confirmField
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: widget.confirmField ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Passphrase',
                  suffixIcon: IconButton(
                    tooltip: _obscure1 ? 'Show passphrase' : 'Hide passphrase',
                    icon: Icon(
                        _obscure1
                            ? Icons.visibility
                            : Icons.visibility_off,),
                    onPressed: () =>
                        setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a passphrase.' : null,
              ),
              if (widget.confirmField) ...[
                const SizedBox(height: 12),
                // Confirm field
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm passphrase',
                    suffixIcon: IconButton(
                      tooltip:
                          _obscure2 ? 'Show passphrase' : 'Hide passphrase',
                      icon: Icon(
                          _obscure2
                              ? Icons.visibility
                              : Icons.visibility_off,),
                      onPressed: () =>
                          setState(() => _obscure2 = !_obscure2),
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
