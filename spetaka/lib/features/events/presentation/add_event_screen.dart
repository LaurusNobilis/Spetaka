import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/event_repository_provider.dart';
import '../domain/event_type.dart';

/// Human-readable cadence labels for Story 3.2 AC3.
const _cadenceOptions = [
  (days: 7, label: 'Every week'),
  (days: 14, label: 'Every 2 weeks'),
  (days: 21, label: 'Every 3 weeks'),
  (days: 30, label: 'Monthly'),
  (days: 60, label: 'Every 2 months'),
  (days: 90, label: 'Every 3 months'),
];

/// Screen for adding a dated or recurring event to a friend card.
///
/// AC2 (3.1): saves one-off events with UUID v4 and is_recurring=false.
/// AC4 (3.1): event type selector includes the 5 default types.
/// AC5 (3.1): date picker respects 48×48 dp touch targets.
/// AC1 (3.2): recurring events saved with is_recurring=true and cadence_days.
/// AC3 (3.2): cadence options (7/14/21/30/60/90 days) with human labels.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key, required this.friendId});

  final String friendId;

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  EventType _selectedType = EventType.regularCheckin;
  DateTime _selectedDate = DateTime.now();
  final _commentController = TextEditingController();
  bool _isRecurring = false;
  int _cadenceDays = 30; // default: monthly
  bool _isSaving = false;

  static final _dateFormat = DateFormat('d MMM yyyy');

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
      final trimmedComment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      if (_isRecurring) {
        await repo.addRecurringEvent(
          friendId: widget.friendId,
          type: _selectedType,
          date: _selectedDate.millisecondsSinceEpoch,
          cadenceDays: _cadenceDays,
          comment: trimmedComment,
        );
      } else {
        await repo.addDatedEvent(
          friendId: widget.friendId,
          type: _selectedType,
          date: _selectedDate.millisecondsSinceEpoch,
          comment: trimmedComment,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
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
          // ── Event type selector — AC4 (3.1) ─────────────────────────────
          Text(
            'Event Type',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in EventType.values)
                _TypeChip(
                  label: type.displayLabel,
                  selected: _selectedType == type,
                  onTap: () => setState(() => _selectedType = type),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Date picker — AC5 (3.1) ──────────────────────────────────────
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
                  Icon(Icons.calendar_today_outlined,
                      color: colorScheme.primary,),
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

          // ── Recurring toggle — Story 3.2 ─────────────────────────────────
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

          // ── Cadence options — AC3 (3.2) — visible when recurring ─────────
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

          // ── Optional comment ─────────────────────────────────────────────
          Text(
            'Comment (optional)',
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
            decoration: const InputDecoration(
              hintText: 'Add a note…',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type chip — custom chip with 48-dp height constraint
// ---------------------------------------------------------------------------

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              selected ? colorScheme.primaryContainer : colorScheme.surface,
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
