import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/encryption/encryption_service_provider.dart';

/// Shown at every session start (or after app resume) when the in-memory
/// encryption key has been cleared.
///
/// Two modes:
/// - **Setup** (first launch / after data reset): asks for a new passphrase
///   with confirmation, then calls `initialize` + `setupVerifier`.
/// - **Unlock** (subsequent launches): asks for the existing passphrase and
///   calls `verifyAndInitialize`, which rejects a wrong passphrase.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _checkingSetup = true; // true during the async hasPassphraseSetup() call
  bool _loading = false;      // true during the async submit call
  bool _isSetupMode = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final service = ref.read(encryptionServiceProvider);
    final hasSetup = await service.hasPassphraseSetup();
    if (!mounted) return;
    setState(() {
      _isSetupMode = !hasSetup;
      _checkingSetup = false;
    });
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final service = ref.read(encryptionServiceProvider);
    final passphrase = _passphraseController.text;

    try {
      if (_isSetupMode) {
        await service.initialize(passphrase);
        await service.setupVerifier();
      } else {
        await service.verifyAndInitialize(passphrase);
      }
      // Success — GoRouter redirects via refreshListenable.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _isSetupMode
            ? 'Impossible d\'initialiser le chiffrement. Réessayez.'
            : 'Phrase secrète incorrecte. Réessayez.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: _checkingSetup
                ? const CircularProgressIndicator()
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: 56,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isSetupMode
                              ? 'Créer votre phrase secrète'
                              : 'Déverrouiller Spetaka',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSetupMode
                              ? 'Choisissez une phrase secrète pour protéger vos données. '
                                'Elle chiffre toutes vos informations et n\'est jamais '
                                'stockée. Notez-la dans un endroit sûr.'
                              : 'Entrez votre phrase secrète pour accéder à vos données.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _passphraseController,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Phrase secrète',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onFieldSubmitted: (_) =>
                              _isSetupMode ? null : _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'La phrase secrète est requise.';
                            }
                            if (_isSetupMode && v.length < 8) {
                              return 'Minimum 8 caractères.';
                            }
                            return null;
                          },
                        ),
                        if (_isSetupMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'Confirmer la phrase secrète',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () =>
                                      _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v != _passphraseController.text) {
                                return 'Les phrases secrètes ne correspondent pas.';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: (_loading || _checkingSetup) ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isSetupMode ? 'Créer' : 'Déverrouiller',
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
