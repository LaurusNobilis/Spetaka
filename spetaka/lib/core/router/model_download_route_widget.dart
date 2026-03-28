// Conditional import façade for ModelDownloadScreen.
// When `dart:ui` is available (real Flutter runtime), the
// `_flutter.dart` implementation re-exports ModelDownloadScreen.
// In pure-Dart VM environments (unit/widget tests run via the Dart
// test runner) the stub implementation is used, which avoids
// importing `flutter_gemma` — a package that references `dart:ui`
// internally and fails to compile in the VM test environment.
export 'model_download_route_widget_stub.dart'
    if (dart.library.ui) 'model_download_route_widget_flutter.dart';
