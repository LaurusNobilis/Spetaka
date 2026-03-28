// Stub implementation used when dart:ui is NOT available
// (Dart VM test environment).  Renders nothing so that router
// compilation succeeds without pulling in flutter_gemma.
import 'package:flutter/material.dart';

class ModelDownloadScreen extends StatelessWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
