import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/app_shell/app_shell.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SpetakaApp(),
    ),
  );
}

class SpetakaApp extends ConsumerWidget {
  const SpetakaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppShell();
  }
}
