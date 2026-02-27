import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Reusable centered loading indicator with an optional text label.
///
/// Use this widget for any async-loading state in the app to ensure
/// consistent loading UX across features.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.label});

  /// Optional label displayed below the progress indicator.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          if (label != null) ...[
            const SizedBox(height: AppTokens.spaceMD),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
