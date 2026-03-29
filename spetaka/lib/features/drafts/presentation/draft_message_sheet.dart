// DraftMessageSheet — Story 10.2 (AC1, AC3, AC4, AC5, AC6, AC8)
//
// Bottom sheet displaying ≥ 3 on-device LLM message variants for selection
// and editing, then sending via WhatsApp or SMS.
// No SQLite persistence — draft is in-memory only (AC5, AC7).

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/actions/contact_action_service.dart';
import '../../../core/actions/phone_normalizer.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../features/acquittement/domain/pending_action_state.dart';
import '../../../features/friends/data/friends_providers.dart';
import '../../../shared/utils/relative_date.dart';
import '../domain/draft_message.dart';
import '../providers/draft_message_providers.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Opens [DraftMessageSheet] as a modal bottom sheet.
///
/// Immediately calls [DraftMessageNotifier.requestSuggestions] so the sheet
/// opens in loading state (AC1).
Future<void> showDraftMessageSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String friendId,
  required Event event,
}) async {
  // Trigger inference BEFORE opening the sheet so it starts loading immediately.
  ref.read(draftMessageProvider.notifier).requestSuggestions(
        friendId: friendId,
        event: event,
        channel: 'whatsapp',
      );

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DraftMessageSheetContent(
        friendId: friendId,
        event: event,
      ),
    );
  } finally {
    ref.read(draftMessageProvider.notifier).clear();
  }
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _DraftMessageSheetContent extends ConsumerStatefulWidget {
  const _DraftMessageSheetContent({
    required this.friendId,
    required this.event,
  });

  final String friendId;
  final Event event;

  @override
  ConsumerState<_DraftMessageSheetContent> createState() =>
      _DraftMessageSheetContentState();
}

class _DraftMessageSheetContentState
    extends ConsumerState<_DraftMessageSheetContent> {
  TextEditingController? _textController;
  String _channel = 'whatsapp';
  bool _channelInitialized = false;
  bool _channelChosenByUser = false;

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  void _syncController(DraftMessage draft) {
    final selectedIndex = draft.selectedIndex ?? 0;
    final text = draft.editedText ??
        (draft.variants.isNotEmpty ? draft.variants[selectedIndex] : '');
    if (_textController == null) {
      _textController = TextEditingController(text: text);
    } else if (_textController!.text != text && draft.editedText == null) {
      // Only overwrite when user hasn't manually edited (i.e., variant changed).
      _textController!.text = text;
      _textController!.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  Future<void> _handleSend(DraftMessage draft) async {
    final editedText = _textController?.text.trim() ?? '';
    if (editedText.isEmpty) return;

    // Copy to clipboard (AC4).
    await Clipboard.setData(ClipboardData(text: editedText));

    // Resolve the friend to get mobile number.
    final friend = await ref.read(friendByIdProvider(widget.friendId).future);

    if (!mounted) return;

    final contactService = ref.read(contactActionServiceProvider);

    try {
      if (_channel == 'whatsapp') {
        await contactService.whatsapp(
          friend?.mobile ?? '',
          friendId: widget.friendId,
          origin: AcquittementOrigin.friendCard,
        );
      } else {
        await contactService.sms(
          friend?.mobile ?? '',
          friendId: widget.friendId,
          origin: AcquittementOrigin.friendCard,
        );
      }
    } on AppError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessageFor(error))),
      );
      return;
    } catch (error) {
      dev.log(
        'DraftMessageSheet: ContactActionService failed — $error',
        name: 'drafts.sheet',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.somethingWentWrong)),
      );
      return;
    }

    // Discard in-memory draft (AC4, AC5).
    ref.read(draftMessageProvider.notifier).clear();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDiscard() {
    ref.read(draftMessageProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  void _handleChannelChanged(String channel) {
    setState(() {
      _channelChosenByUser = true;
      _channel = channel;
    });
  }

  void _maybeInitializeChannel(String? mobile) {
    if (_channelInitialized || _channelChosenByUser || mobile == null) {
      return;
    }
    _channel = _preferredChannel(mobile);
    _channelInitialized = true;
  }

  String _preferredChannel(String mobile) {
    try {
      const PhoneNormalizer().normalize(mobile);
      return 'whatsapp';
    } on AppError {
      return 'sms';
    } catch (_) {
      return 'sms';
    }
  }

  String _eventHeaderContext() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final relativeDate = formatRelativeDate(
      DateTime.fromMillisecondsSinceEpoch(widget.event.date),
      languageCode: languageCode,
    );
    return '${widget.event.type} ${_asSentenceFragment(relativeDate)}';
  }

  String _asSentenceFragment(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toLowerCase()}${text.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final draftState = ref.watch(draftMessageProvider);
    final asyncFriend = ref.watch(friendByIdProvider(widget.friendId));
    final friend = asyncFriend.asData?.value;
    _maybeInitializeChannel(friend?.mobile);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AC1: small loading indicator at the very top of the sheet.
          // Also shown while streaming (isStreaming == true) so the user sees
          // continuous feedback even after the first partial variants arrive.
          if (draftState is AsyncLoading<DraftMessage?> ||
              draftState.value?.isStreaming == true)
            LinearProgressIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer,
              minHeight: 3,
            ),

          // ── Drag handle ─────────────────────────────────────────────
          ExcludeSemantics(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Sheet title ──────────────────────────────────────────────
          Text(
            l10n.draftMessageSheetTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Body — switches between loading / data / error states ────
          draftState.when(
            loading: () => _LoadingBody(l10n: l10n),
            error: (_, __) => _ErrorBody(
              l10n: l10n,
              colorScheme: colorScheme,
              theme: theme,
              textController: _textController ??= TextEditingController(),
              channel: _channel,
              onChannelChanged: _handleChannelChanged,
              onSend: (_) async => _handleSend(
                DraftMessage(
                  friendId: widget.friendId,
                  friendName: '',
                  eventContext: widget.event.type,
                  channel: _channel,
                  variants: const [],
                ),
              ),
              onDiscard: _handleDiscard,
            ),
            data: (draft) {
              if (draft == null) {
                // Not yet requested — show minimal placeholder.
                return _LoadingBody(l10n: l10n);
              }
              if (draft.variants.isEmpty) {
                // AC6: inference returned no parseable variants.
                return _ErrorBody(
                  l10n: l10n,
                  colorScheme: colorScheme,
                  theme: theme,
                  textController: _textController ??= TextEditingController(),
                  channel: _channel,
                  onChannelChanged: _handleChannelChanged,
                  onSend: (_) async => _handleSend(draft),
                  onDiscard: _handleDiscard,
                );
              }

              // Sync text controller with current draft state.
              _syncController(draft);

              return _DataBody(
                draft: draft,
                l10n: l10n,
                colorScheme: colorScheme,
                theme: theme,
                textController: _textController!,
                channel: _channel,
                headerContext: _eventHeaderContext(),
                onChannelChanged: _handleChannelChanged,
                onVariantSelected: (i) => ref
                    .read(draftMessageProvider.notifier)
                    .selectVariant(i),
                onTextChanged: (t) => ref
                    .read(draftMessageProvider.notifier)
                    .updateEditedText(t),
                onGenerateMore: () => ref
                    .read(draftMessageProvider.notifier)
                    .requestSuggestions(
                      friendId: widget.friendId,
                      event: widget.event,
                      channel: _channel,
                    ),
                onSend: () => _handleSend(draft),
                onDiscard: _handleDiscard,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading body
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.l10n});
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          (l10n as dynamic).draftMessageGenerating as String,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body (AC6)
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.l10n,
    required this.colorScheme,
    required this.theme,
    required this.textController,
    required this.channel,
    required this.onChannelChanged,
    required this.onSend,
    required this.onDiscard,
  });

  final dynamic l10n;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final TextEditingController textController;
  final String channel;
  final ValueChanged<String> onChannelChanged;
  final ValueChanged<String> onSend;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.draftMessageError as String,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _EditableTextField(
          controller: textController,
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _ChannelSelector(
          channel: channel,
          onChanged: onChannelChanged,
          colorScheme: colorScheme,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        _ConfirmButton(
          channel: channel,
          colorScheme: colorScheme,
          l10n: l10n,
          onPressed: () => onSend(textController.text),
        ),
        _DiscardButton(l10n: l10n, onPressed: onDiscard),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data body (AC3)
// ---------------------------------------------------------------------------

class _DataBody extends StatelessWidget {
  const _DataBody({
    required this.draft,
    required this.headerContext,
    required this.l10n,
    required this.colorScheme,
    required this.theme,
    required this.textController,
    required this.channel,
    required this.onChannelChanged,
    required this.onVariantSelected,
    required this.onTextChanged,
    required this.onGenerateMore,
    required this.onSend,
    required this.onDiscard,
  });

  final DraftMessage draft;
  final String headerContext;
  final dynamic l10n;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final TextEditingController textController;
  final String channel;
  final ValueChanged<String> onChannelChanged;
  final ValueChanged<int> onVariantSelected;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onGenerateMore;
  final VoidCallback onSend;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    final selectedIndex = draft.selectedIndex ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // AC3: event context header.
        Text(
          l.draftMessageEventHeader(
            draft.friendName,
            headerContext,
          ) as String,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        // AC3: variant cards.
        for (int i = 0; i < draft.variants.length; i++) ...[
          _VariantCard(
            index: i,
            text: draft.variants[i],
            isSelected: i == selectedIndex,
            colorScheme: colorScheme,
            theme: theme,
            onTap: () => onVariantSelected(i),
            l10n: l10n,
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 4),

        // Generate more button (AC2: shown when < 3 variants parsed).
        if (draft.variants.length < 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onGenerateMore,
              icon: const Icon(Icons.refresh_outlined, size: 16),
              label: Text(l.draftMessageGenerateMore as String),
            ),
          ),

        const SizedBox(height: 8),

        // AC3: editable text field.
        _EditableTextField(
          controller: textController,
          theme: theme,
          colorScheme: colorScheme,
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 12),

        // AC3: channel selector.
        _ChannelSelector(
          channel: channel,
          onChanged: onChannelChanged,
          colorScheme: colorScheme,
          l10n: l10n,
        ),
        const SizedBox(height: 16),

        // AC4: confirm button.
        _ConfirmButton(
          channel: channel,
          colorScheme: colorScheme,
          l10n: l10n,
          onPressed: onSend,
        ),

        // AC5: discard button.
        _DiscardButton(l10n: l10n, onPressed: onDiscard),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

/// AC3: selectable variant card.
class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
    required this.l10n,
  });

  final int index;
  final String text;
  final bool isSelected;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    final preview = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    return Semantics(
      label: l.draftMessageVariantSemantics(index + 1, preview) as String,
      button: true,
      selected: isSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AC3: editable text field pre-filled with selected variant.
class _EditableTextField extends StatelessWidget {
  const _EditableTextField({
    required this.controller,
    required this.theme,
    required this.colorScheme,
    this.onChanged,
  });

  final TextEditingController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

/// AC3: WhatsApp / SMS channel selector chips.
class _ChannelSelector extends StatelessWidget {
  const _ChannelSelector({
    required this.channel,
    required this.onChanged,
    required this.colorScheme,
    required this.l10n,
  });

  final String channel;
  final ValueChanged<String> onChanged;
  final ColorScheme colorScheme;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // WhatsApp chip — AC8 semantics.
        Semantics(
          label: l.draftMessageChannelWhatsAppSemantics as String,
          child: ChoiceChip(
            label: Text(l.draftMessageChannelWhatsApp as String),
            selected: channel == 'whatsapp',
            onSelected: (_) => onChanged('whatsapp'),
            avatar: const Icon(Icons.chat_outlined, size: 16),
          ),
        ),
        const SizedBox(width: 8),
        // SMS chip — AC8 semantics.
        Semantics(
          label: l.draftMessageChannelSmsSemantics as String,
          child: ChoiceChip(
            label: Text(l.draftMessageChannelSms as String),
            selected: channel == 'sms',
            onSelected: (_) => onChanged('sms'),
            avatar: const Icon(Icons.sms_outlined, size: 16),
          ),
        ),
      ],
    );
  }
}

/// AC4: confirm / send button.
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.channel,
    required this.colorScheme,
    required this.l10n,
    required this.onPressed,
  });

  final String channel;
  final ColorScheme colorScheme;
  final dynamic l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    final label = channel == 'whatsapp'
        ? l.draftMessageSendViaWhatsApp as String
        : l.draftMessageSendViaSms as String;
    final semanticsLabel =
        l.draftMessageSendSemantics(channel == 'whatsapp' ? 'WhatsApp' : 'SMS')
            as String;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: FilledButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

/// AC5: discard button.
class _DiscardButton extends StatelessWidget {
  const _DiscardButton({required this.l10n, required this.onPressed});
  final dynamic l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = l10n as dynamic;
    return Semantics(
      label: l.draftMessageDiscardSemantics as String,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: TextButton(
          onPressed: onPressed,
          child: Text(l.draftMessageDiscard as String),
        ),
      ),
    );
  }
}
