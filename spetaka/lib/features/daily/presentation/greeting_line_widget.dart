// GreetingLineWidget — Story 10.3
//
// Shows the daily greeting line with an animated cross-fade when the LLM
// result overwrites the initial static fallback.
//
// Animation: AnimatedSwitcher + FadeTransition (300ms easeInOutCubic).
// Height stability: Stack-based layoutBuilder prevents resize.
// Accessibility: Semantics(label: ..., excludeSemantics: true) ensures
// TalkBack reads the current text without a focus jump on animation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/greeting_line_provider.dart';

class GreetingLineWidget extends ConsumerWidget {
  const GreetingLineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingLineProvider);
    final theme = Theme.of(context);

    return Semantics(
      label: greeting,
      excludeSemantics: true,
      child: Padding(
        key: const Key('greeting_banner'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: Text(
            greeting,
            key: ValueKey<String>(greeting),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
