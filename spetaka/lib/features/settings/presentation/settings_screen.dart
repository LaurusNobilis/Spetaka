import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../backup/providers/backup_providers.dart';
import '../../daily/data/density_provider.dart';
import '../data/display_prefs_provider.dart';

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
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackupSection(),
            _DisplaySection(),
            _EventTypesSection(),
            _CategoryTagsSection(),
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
      title: context.l10n.exportBackupLabel,
      hint: context.l10n.exportPassphraseHint,
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
      title: context.l10n.importBackupLabel,
      hint: context.l10n.importPassphraseHint,
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
        title: Text(context.l10n.resetEncryptionKeyTitle),
        content: Text(context.l10n.resetEncryptionKeyContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionReset),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    ref.read(backupResetProvider.notifier).resetBackupSettings();
  }

  void _handleResetState(AsyncValue<bool>? prev, AsyncValue<bool> next) {
    if (!mounted) return;
    next.whenOrNull(
      data: (done) {
        if (done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.backupSettingsResetSuccess)),
          );
          ref.read(backupResetProvider.notifier).reset();
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : context.l10n.resetFailed;
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
              content: Text(context.l10n.backupSavedTo(path)),
              duration: const Duration(seconds: 6),
            ),
          );
          ref.read(backupExportProvider.notifier).reset();
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : context.l10n.resetExportFailed;
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
            SnackBar(content: Text(context.l10n.backupRestoredSuccess)),
          );
          ref.read(backupImportProvider.notifier).reset();
          const HomeRoute().go(context);
        }
      },
      error: (e, _) {
        final msg = e is AppError
            ? errorMessageFor(e)
            : context.l10n.importFailed;
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
        _SectionHeading(context.l10n.backupSectionTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            context.l10n.backupPassphraseNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.upload_file_outlined,
          label: context.l10n.exportBackupLabel,
          semanticsLabel: context.l10n.exportBackupSemantics,
          isLoading: isExporting,
          onTap: isBusy ? null : _onExport,
        ),
        _ActionTile(
          icon: Icons.download_outlined,
          label: context.l10n.importBackupLabel,
          semanticsLabel: context.l10n.importBackupSemantics,
          isLoading: isImporting,
          onTap: isBusy ? null : _onImport,
        ),
        Semantics(
          label: context.l10n.resetBackupSettingsLabel,
          button: resetOnTap != null,
          child: ListTile(
            minVerticalPadding: 12,
            enabled: resetOnTap != null,
            leading: Icon(
              Icons.restore_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              context.l10n.resetBackupSettingsLabel,
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
                  labelText: context.l10n.passphraseLabel,
                  suffixIcon: IconButton(
                    tooltip: _obscure1
                        ? context.l10n.showPassphrase
                        : context.l10n.hidePassphrase,
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
                    labelText: context.l10n.confirmPassphraseLabel,
                    suffixIcon: IconButton(
                      tooltip: _obscure2
                          ? context.l10n.showPassphrase
                          : context.l10n.hidePassphrase,
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
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.actionContinue),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Display section — density + font size + icon size + language
// ---------------------------------------------------------------------------

class _DisplaySection extends ConsumerWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(densityModeProvider);
    final fontScale = ref.watch(fontScaleModeProvider);
    final iconSize = ref.watch(iconSizeModeProvider);
    final locale = ref.watch(localeProvider);
    final isCompact = mode == DensityMode.compact;
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(l.displaySectionTitle),
        // ── Compact view toggle ───────────────────────────────────────────
        Semantics(
          label: isCompact ? l.compactViewOn : l.compactViewOff,
          toggled: isCompact,
          excludeSemantics: true,
          child: SwitchListTile(
            key: const Key('density_switch'),
            secondary: const Icon(Icons.density_medium_outlined),
            title: Text(l.compactViewLabel),
            subtitle: Text(l.compactViewSubtitle),
            value: isCompact,
            onChanged: (_) => ref.read(densityModeProvider.notifier).toggle(),
          ),
        ),
        // ── Font size ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.text_fields_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(child: Text(l.fontSizeLabel)),
              SegmentedButton<FontScaleMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                segments: [
                  ButtonSegment(
                    value: FontScaleMode.small,
                    label: Text(l.sizeSmall,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: FontScaleMode.medium,
                    label: Text(l.sizeMedium,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: FontScaleMode.large,
                    label: Text(l.sizeLarge,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {fontScale},
                onSelectionChanged: (s) =>
                    ref.read(fontScaleModeProvider.notifier).set(s.first),
              ),
            ],
          ),
        ),
        // ── Icon size ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Icon(Icons.interests_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(child: Text(l.iconSizeLabel)),
              SegmentedButton<IconSizeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                segments: [
                  ButtonSegment(
                    value: IconSizeMode.small,
                    label: Text(l.sizeSmall,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: IconSizeMode.medium,
                    label: Text(l.sizeMedium,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: IconSizeMode.large,
                    label: Text(l.sizeLarge,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {iconSize},
                onSelectionChanged: (s) =>
                    ref.read(iconSizeModeProvider.notifier).set(s.first),
              ),
            ],
          ),
        ),
        // ── Language ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Icon(Icons.language_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(child: Text(l.languageLabel)),
              SegmentedButton<String>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                segments: [
                  ButtonSegment(
                    value: 'fr',
                    label: Text(l.languageFrench,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(l.languageEnglish,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (s) => ref
                    .read(localeProvider.notifier)
                    .set(Locale(s.first)),
              ),
            ],
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category Tags section
// ---------------------------------------------------------------------------

class _CategoryTagsSection extends StatelessWidget {
  const _CategoryTagsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(context.l10n.categoryTagsSectionTitle),
        Semantics(
          label: context.l10n.manageCategoryTagsLabel,
          button: true,
          child: ListTile(
            minVerticalPadding: 12,
            leading: const Icon(Icons.label_outline),
            title: Text(context.l10n.manageCategoryTagsLabel),
            subtitle: Text(context.l10n.editNamesWeightsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ManageCategoryTagsRoute().push(context),
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
        _SectionHeading(context.l10n.eventTypesSectionTitle),
        Semantics(
          label: context.l10n.manageEventTypesLabel,
          button: true,
          child: ListTile(
            minVerticalPadding: 12,
            leading: const Icon(Icons.event_note_outlined),
            title: Text(context.l10n.manageEventTypesLabel),
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
        _SectionHeading(context.l10n.syncSectionTitle),
        Semantics(
          label: context.l10n.syncSemantics,
          enabled: false,
          child: ListTile(
            minVerticalPadding: 12,
            enabled: false,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(context.l10n.syncSectionTitle),
            subtitle: Text(context.l10n.syncComingSoon),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
