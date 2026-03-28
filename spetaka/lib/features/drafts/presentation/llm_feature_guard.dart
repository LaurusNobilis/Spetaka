// LlmFeatureGuard — Story 10.1 (AC4, AC6)
//
// Reusable widget that gates LLM feature entry points:
// - If !isSupported → hide child entirely (SizedBox.shrink)
// - If isSupported && !isModelReady → on tap, navigate to ModelDownloadScreen
// - If isSupported && isModelReady → show child normally
//
// Actual feature entry points ("Suggest message" button) are wired in
// Stories 10.2 and 10.3 — this story creates the guard infrastructure only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_capability_checker.dart';
import '../../../core/ai/model_manager.dart';
import '../../../core/router/app_router.dart';

/// Gates child widget behind LLM capability + model readiness checks.
///
/// Usage:
/// ```dart
/// LlmFeatureGuard(
///   child: ElevatedButton(
///     onPressed: () => showSuggestions(),
///     child: Text('Suggest message'),
///   ),
/// )
/// ```
class LlmFeatureGuard extends ConsumerWidget {
  const LlmFeatureGuard({
    super.key,
    required this.child,
  });

  /// The widget to show when LLM is fully available.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupported = ref.watch(aiCapabilityCheckerProvider);
    if (!isSupported) {
      return const SizedBox.shrink();
    }

    final modelState = ref.watch(modelManagerProvider);
    final isModelReady = modelState is ModelReady;

    if (!isModelReady) {
      // AC5: Supported but model not ready — wrap child to redirect to
      // ModelDownloadScreen on tap.
      return _ModelGateWrapper(child: child);
    }

    // AC6: Supported + model ready — show child normally.
    return child;
  }
}

/// Wraps the child so that any tap navigates to ModelDownloadScreen instead.
class _ModelGateWrapper extends StatelessWidget {
  const _ModelGateWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => const ModelDownloadRoute().push(context),
      child: AbsorbPointer(child: child),
    );
  }
}
