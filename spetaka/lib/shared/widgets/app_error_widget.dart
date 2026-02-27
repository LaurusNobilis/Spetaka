import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Reusable centered error-state widget with an optional retry action.
///
/// Named [AppErrorWidget] to avoid conflict with Flutter's built-in
/// [ErrorWidget] class.
///
/// Use this widget for any error state in the app to ensure
/// consistent, warm error UX ("calm, never clinical").
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// Human-readable error message shown to the user.
  final String message;

  /// Optional retry callback. When provided, a "Retry" button is rendered.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppTokens.spaceMD),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spaceLG),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
