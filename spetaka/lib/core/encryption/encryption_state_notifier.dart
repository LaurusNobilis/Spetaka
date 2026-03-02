import 'package:flutter/foundation.dart';

/// A singleton [ChangeNotifier] that tracks whether [EncryptionService] has a
/// live in-memory key.
///
/// Used by [GoRouter] as `refreshListenable` so the router re-evaluates its
/// `redirect` whenever the encryption state changes (lock / unlock).
final encryptionStateNotifier = EncryptionStateNotifier._();

class EncryptionStateNotifier extends ChangeNotifier {
  EncryptionStateNotifier._();

  bool _isInitialized = false;

  /// `true` when [EncryptionService] has a live key in memory.
  bool get isInitialized => _isInitialized;

  /// Called by [EncryptionService] whenever the key is set or cleared.
  void setInitialized(bool value) {
    if (_isInitialized != value) {
      _isInitialized = value;
      notifyListeners();
    }
  }
}
