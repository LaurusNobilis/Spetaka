// ModelDownloadScreen — Story 10.1 (AC5), p2-llm-hf-token (AC5)
//
// Gate screen shown when hardware is supported but model is not yet downloaded.
// Displays storage requirement, download button, progress, cancel, error+retry.
// p2-llm-hf-token: Adds token entry step — user provides their own HF token
// before the first download. Token is stored in flutter_secure_storage.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/hf_token_service.dart';
import '../../../core/ai/model_manager.dart';
import '../../../core/l10n/l10n_extension.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  bool _awaitingTokenEntry = false;
  final _tokenController = TextEditingController();
  String? _tokenError;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelManagerProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modelDownloadTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.modelDownloadStorageRequired,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStateContent(context, state, l10n, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(
    BuildContext context,
    ModelDownloadState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return switch (state) {
      ModelDownloadIdle() => _awaitingTokenEntry
          ? _TokenEntryContent(
              controller: _tokenController,
              errorText: _tokenError,
              l10n: l10n,
              onSaveAndDownload: _saveTokenAndStartDownload,
            )
          : _IdleContent(
              l10n: l10n,
              onDownload: _onDownloadPressed,
            ),
      ModelDownloading(:final progress) => _DownloadingContent(
          progress: progress,
          l10n: l10n,
          onCancel: () =>
              ref.read(modelManagerProvider.notifier).cancelDownload(),
        ),
      ModelReady() => _ReadyContent(
          l10n: l10n,
          onDone: () => Navigator.of(context).pop(),
        ),
      ModelDownloadError(:final message) => _ErrorContent(
          message: message,
          l10n: l10n,
          onRetry: () => ref.read(modelManagerProvider.notifier).retry(),
        ),
    };
  }

  void _onDownloadPressed() {
    unawaited(_checkTokenAndDownload());
  }

  Future<void> _checkTokenAndDownload() async {
    final token = await const HfTokenService().getToken();
    if (token != null && token.isNotEmpty) {
      ref.read(modelManagerProvider.notifier).startDownload();
    } else {
      setState(() => _awaitingTokenEntry = true);
    }
  }

  void _saveTokenAndStartDownload() {
    unawaited(_doSaveTokenAndStartDownload());
  }

  Future<void> _doSaveTokenAndStartDownload() async {
    final raw = _tokenController.text.trim();
    if (raw.isEmpty) {
      setState(() => _tokenError = context.l10n.hfTokenErrorEmpty);
      return;
    }
    await const HfTokenService().saveToken(raw);
    setState(() {
      _awaitingTokenEntry = false;
      _tokenError = null;
    });
    ref.read(modelManagerProvider.notifier).startDownload();
  }
}


class _TokenEntryContent extends StatelessWidget {
  const _TokenEntryContent({
    required this.controller,
    required this.l10n,
    required this.onSaveAndDownload,
    this.errorText,
  });

  final TextEditingController controller;
  final AppLocalizations l10n;
  final VoidCallback onSaveAndDownload;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.hfTokenSectionTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.hfTokenExplainer,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.hfTokenFieldLabel,
            errorText: errorText,
          ),
          onSubmitted: (_) => onSaveAndDownload(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onSaveAndDownload,
            child: Text(l10n.hfTokenSaveAndDownload),
          ),
        ),
      ],
    );
  }
}

class _IdleContent extends StatelessWidget {
  const _IdleContent({required this.l10n, required this.onDownload});

  final AppLocalizations l10n;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.download),
        label: Text(l10n.modelDownloadButton),
      ),
    );
  }
}

class _DownloadingContent extends StatelessWidget {
  const _DownloadingContent({
    required this.progress,
    required this.l10n,
    required this.onCancel,
  });

  final double progress;
  final AppLocalizations l10n;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Column(
      children: [
        Semantics(
          label: l10n.modelDownloadProgressSemantics(percent),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n.modelDownloadCancelButton),
          ),
        ),
      ],
    );
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent({required this.l10n, required this.onDone});

  final AppLocalizations l10n;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 48,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.modelDownloadComplete,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onDone,
            child: Text(l10n.modelDownloadOkButton),
          ),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.message,
    required this.l10n,
    required this.onRetry,
  });

  final String message;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.modelDownloadErrorMessage(message),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.modelDownloadRetryButton),
          ),
        ),
      ],
    );
  }
}
