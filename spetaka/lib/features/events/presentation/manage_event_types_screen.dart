import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../data/event_type_providers.dart';

/// Screen for managing event types (add, rename, reorder, delete).
///
/// Story 3.4 AC2–AC5: full CRUD + drag-and-drop reorder.
class ManageEventTypesScreen extends ConsumerStatefulWidget {
  const ManageEventTypesScreen({super.key});

  @override
  ConsumerState<ManageEventTypesScreen> createState() =>
      _ManageEventTypesScreenState();
}

class _ManageEventTypesScreenState
    extends ConsumerState<ManageEventTypesScreen> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addType() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(eventTypeRepositoryProvider);
    try {
      await repo.addEventType(name);
      _addController.clear();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      // Évite d'afficher un message d'exception potentiellement en anglais.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidNameFallback)),
      );
    }
  }

  Future<void> _rename(EventTypeEntry entry) async {
    final controller = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.renameEventTypeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.nameLabel,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.isNotEmpty && newName != entry.name) {
      try {
        await ref.read(eventTypeRepositoryProvider).rename(entry.id, newName);
      } on ArgumentError catch (e) {
        if (!mounted) return;
        // Évite d'afficher un message d'exception potentiellement en anglais.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invalidNameFallback)),
        );
      }
    }
  }

  Future<void> _confirmDelete(EventTypeEntry entry) async {
    final repo = ref.read(eventTypeRepositoryProvider);
    final usageCount = await repo.countEventsByType(entry.name);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteEventTypeTitle),
        content: usageCount > 0
            ? Text(
                context.l10n.eventTypeInUseNotice(usageCount),
              )
            : Text(context.l10n.deleteEntryConfirm(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteById(entry.id);
    }
  }

  Future<void> _onReorder(
    List<EventTypeEntry> types,
    int oldIndex,
    int newIndex,
  ) async {
    // ReorderableListView adjusts newIndex when moving downward.
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<EventTypeEntry>.from(types);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    await ref
        .read(eventTypeRepositoryProvider)
        .reorder(reordered.map((e) => e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typesAsync = ref.watch(watchEventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.eventTypesTitle)),
      body: Column(
        children: [
          // ── Add type row — AC2 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.newEventTypePlaceholder,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addType(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addType,
                  icon: const Icon(Icons.add),
                  tooltip: context.l10n.addTypeTooltip,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Reorderable list — AC5 ───────────────────────────────────────
          Expanded(
            child: typesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  context.l10n.couldNotLoadEventTypes,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.error),
                ),
              ),
              data: (types) {
                if (types.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.noEventTypes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: types.length,
                  onReorder: (oldIdx, newIdx) =>
                      _onReorder(types, oldIdx, newIdx),
                  itemBuilder: (_, index) {
                    final entry = types[index];
                    return ListTile(
                      key: ValueKey(entry.id),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(entry.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: context.l10n.actionRename,
                            onPressed: () => _rename(entry),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            tooltip: context.l10n.actionDelete,
                            onPressed: () => _confirmDelete(entry),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
