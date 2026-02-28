import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../data/event_repository_provider.dart';
import '../data/event_type_providers.dart';

/// Human-readable cadence labels — matches AddEventScreen.
const _cadenceOptions = [
  (days: 7, label: 'Every week'),
  (days: 14, label: 'Every 2 weeks'),
  (days: 21, label: 'Every 3 weeks'),
  (days: 30, label: 'Monthly'),
  (days: 60, label: 'Every 2 months'),
  (days: 90, label: 'Every 3 months'),
];

/// Screen for editing an existing event.
///
/// Story 3.3 AC1: form opens prefilled with current event values.
/// Story 3.3 AC2: save updates event record.
class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({super.key, required this.event});

  final Event event;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  late String _selectedType;
  late DateTime _selectedDate;
  late TextEditingController _commentController;
  late bool _isRecurring;
  late int _cadenceDays;
  bool _isSaving = false;

  static final _dateFormat = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    // Use the raw type string from the event (now dynamic, not enum-based).
    _selectedType = widget.event.type;
    _selectedDate =
        DateTime.fromMillisecondsSinceEpoch(widget.event.date);
    _commentController =
        TextEditingController(text: widget.event.comment ?? '');
    _isRecurring = widget.event.isRecurring;
    _cadenceDays = widget.event.cadenceDays ?? 30;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      await repo.updateEvent(
        id: widget.event.id,
        friendId: widget.event.friendId,
        type: _selectedType,
        date: _selectedDate.millisecondsSinceEpoch,
        isRecurring: _isRecurring,
        cadenceDays: _isRecurring ? _cadenceDays : null,
        comment: comment,
        isAcknowledged: widget.event.isAcknowledged,
        acknowledgedAt: widget.event.acknowledgedAt,
        createdAt: widget.event.createdAt,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventTypesAsync = ref.watch(watchEventTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ── Event type selector — AC6 (3.4) ──────────────────────────────
          Text(
            'Event Type',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          eventTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Could not load event types.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.error),
            ),
            data: (types) {
              // Include the current event type if it's been deleted (orphan).
              final hasCurrentType =
                  types.any((t) => t.name == _selectedType);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!hasCurrentType)
                    _TypeChip(
                      label: _selectedType,
                      selected: true,
                      onTap: () {},
                    ),
                  for (final t in types)
                    _TypeChip(
                      label: t.name,
                      selected: _selectedType == t.name,
                      onTap: () => setState(() => _selectedType = t.name),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Date picker ──────────────────────────────────────────────────
          Text(
            'Date',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dateFormat.format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Recurring toggle ─────────────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Recurring',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: const Text('Set a repeating check-in cadence'),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),

          // ── Cadence options (visible when recurring) ─────────────────────
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in _cadenceOptions)
                  _TypeChip(
                    label: opt.label,
                    selected: _cadenceDays == opt.days,
                    onTap: () => setState(() => _cadenceDays = opt.days),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Comment ──────────────────────────────────────────────────────
          Text(
            'Comment',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Optional note…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable chip for event type / cadence selection.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
