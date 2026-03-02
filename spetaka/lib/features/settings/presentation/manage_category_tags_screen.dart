import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Category Tags'),
        actions: [
          Semantics(
            label: 'Reset to default tags',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.restore_outlined),
              tooltip: 'Reset to defaults',
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(context, ref, index: null, tag: null),
        tooltip: 'Add tag',
        child: const Icon(Icons.add),
      ),
      body: tags.isEmpty
          ? const Center(child: Text('No tags yet. Tap + to add one.'))
          : Column(
              children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Tags control the priority score. Higher weight = higher '
                      'priority in the daily view. Drag to reorder.',
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
        title: const Text('Delete tag?'),
        content: Text(
          'Remove "$name"? Friends already tagged with it keep the tag '
          'label, but it will score as the default weight.',
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
            child: const Text('Delete'),
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
        title: const Text('Reset to defaults?'),
        content: const Text(
          'This will restore the original 5 tags and weights. '
          'Any custom tags you added will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
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
        label: 'Drag to reorder ${tag.name}',
        child: const Icon(Icons.drag_handle_outlined),
      ),
      title: Text(tag.name),
      subtitle: Text('Weight: $weightLabel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Edit ${tag.name}',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          ),
          Semantics(
            label: 'Delete ${tag.name}',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete',
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
      title: Text(isNew ? 'Add tag' : 'Edit tag'),
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
              decoration: const InputDecoration(
                labelText: 'Tag name',
                hintText: 'e.g. Family',
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
              decoration: const InputDecoration(
                labelText: 'Weight',
                hintText: 'e.g. 2.5',
                helperText: 'Positive number — higher = more priority',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isNew ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
