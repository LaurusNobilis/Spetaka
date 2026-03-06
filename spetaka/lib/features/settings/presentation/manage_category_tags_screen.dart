import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../data/category_tags_provider.dart';
import '../domain/category_tag.dart';

/// Screen for managing category tags (name + weight).
///
/// Accessible from Settings → Category Tags.
/// Allows: add, edit (name + weight), delete, reorder, reset to defaults.
class ManageCategoryTagsScreen extends ConsumerWidget {
  const ManageCategoryTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(categoryTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.categoryTagsTitle),
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
          Semantics(
            label: context.l10n.resetToDefaultTagsTooltip,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.restore_outlined),
              tooltip: context.l10n.resetToDefaultTagsTooltip,
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(context, ref, index: null, tag: null),
        tooltip: context.l10n.addTagTooltip,
        child: const Icon(Icons.add),
      ),
      body: tags.isEmpty
          ? Center(child: Text(context.l10n.noTagsYet))
          : Column(
              children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      context.l10n.tagsWeightHelp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: tags.length,
                      onReorder: (oldIndex, newIndex) => ref
                          .read(categoryTagsProvider.notifier)
                          .reorder(oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return _TagTile(
                          key: ValueKey(tag.name),
                          tag: tag,
                          index: index,
                          onEdit: () => _openEditDialog(
                            context,
                            ref,
                            index: index,
                            tag: tag,
                          ),
                          onDelete: () => _confirmDelete(
                            context,
                            ref,
                            index: index,
                            name: tag.name,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required int? index,
    required CategoryTag? tag,
  }) async {
    final tags = ref.read(categoryTagsProvider);
    final existingNames = tags
        .map((t) => t.name)
        .where((n) => n != tag?.name)
        .toSet();

    final result = await showDialog<CategoryTag>(
      context: context,
      builder: (_) => _TagEditDialog(
        initialTag: tag,
        forbiddenNames: existingNames,
      ),
    );

    if (result == null) return;

    if (index == null) {
      await ref.read(categoryTagsProvider.notifier).addTag(result);
    } else {
      await ref.read(categoryTagsProvider.notifier).updateTag(index, result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required String name,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteTagTitle),
        content: Text(context.l10n.deleteTagContent(name)),
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
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(categoryTagsProvider.notifier).removeTag(index);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.resetToDefaultsTitle),
        content: Text(context.l10n.resetToDefaultsContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionReset),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(categoryTagsProvider.notifier).resetToDefaults();
    }
  }
}

// ---------------------------------------------------------------------------
// Tag tile
// ---------------------------------------------------------------------------

class _TagTile extends StatelessWidget {
  const _TagTile({
    super.key,
    required this.tag,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryTag tag;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final weightLabel = tag.weight.toStringAsFixed(1);

    return ListTile(
      key: key,
      minVerticalPadding: 12,
      leading: Semantics(
        label: context.l10n.dragToReorder(tag.name),
        child: const Icon(Icons.drag_handle_outlined),
      ),
      title: Text(tag.name),
      subtitle: Text(context.l10n.weightValueLabel(weightLabel)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: context.l10n.editItemSemantics(tag.name),
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.actionEdit,
              onPressed: onEdit,
            ),
          ),
          Semantics(
            label: context.l10n.deleteItemSemantics(tag.name),
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: context.l10n.actionDelete,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit / add dialog
// ---------------------------------------------------------------------------

class _TagEditDialog extends StatefulWidget {
  const _TagEditDialog({
    required this.initialTag,
    required this.forbiddenNames,
  });

  final CategoryTag? initialTag;
  final Set<String> forbiddenNames;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialTag?.name ?? '');
    _weightCtrl = TextEditingController(
      text: widget.initialTag?.weight.toStringAsFixed(1) ?? '1.0',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 1.0;
    Navigator.of(context).pop(
      CategoryTag(name: _nameCtrl.text.trim(), weight: weight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialTag == null;

    return AlertDialog(
      title: Text(isNew ? context.l10n.addTagTitle : context.l10n.editTagTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.tagNameLabel,
                hintText: context.l10n.tagNamePlaceholder,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name cannot be empty.';
                }
                if (widget.forbiddenNames.contains(v.trim())) {
                  return 'A tag with this name already exists.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Weight field
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: context.l10n.weightLabel,
                hintText: context.l10n.weightPlaceholder,
                helperText: context.l10n.weightHelperText,
                helperMaxLines: 3,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a weight.';
                final d = double.tryParse(v.trim());
                if (d == null) return 'Enter a valid number (e.g. 2.5).';
                if (d < 0) return 'Weight must be ≥ 0.';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isNew ? context.l10n.actionAdd : context.l10n.actionSave),
        ),
      ],
    );
  }
}
