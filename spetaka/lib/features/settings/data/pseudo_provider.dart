import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pseudoProvider = NotifierProvider<PseudoNotifier, String>(PseudoNotifier.new);

class PseudoNotifier extends Notifier<String> {
  static const _key = 'user_pseudo';
  static const _default = 'Laurus';

  @override
  String build() {
    _load();
    return _default;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? _default;
  }

  Future<void> set(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}
