import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedNotifier extends StateNotifier<Set<String>> {
  static const String _storageKey = 'blocked_identities';

  BlockedNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey);
    if (list != null) {
      state = list.toSet();
    }
  }

  Future<void> block(String colorHex) async {
    final newState = {...state, colorHex.toLowerCase()};
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, newState.toList());
  }

  Future<void> unblock(String colorHex) async {
    final newState = state.where((item) => item != colorHex.toLowerCase()).toSet();
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, newState.toList());
  }

  bool isBlocked(String colorHex) {
    return state.contains(colorHex.toLowerCase());
  }
}

final blockedProvider = StateNotifierProvider<BlockedNotifier, Set<String>>((ref) {
  return BlockedNotifier();
});
