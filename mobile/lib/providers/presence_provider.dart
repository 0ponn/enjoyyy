import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attention.dart';
import '../services/socket_service.dart';
import 'socket_provider.dart';

class PresenceState {
  final int count;
  final Set<String> typingColors;
  final List<Attention> attentions;
  final List<PresenceGhost> ghosts;

  const PresenceState({
    this.count = 0,
    this.typingColors = const {},
    this.attentions = const [],
    this.ghosts = const [],
  });

  PresenceState copyWith({
    int? count,
    Set<String>? typingColors,
    List<Attention>? attentions,
    List<PresenceGhost>? ghosts,
  }) {
    return PresenceState(
      count: count ?? this.count,
      typingColors: typingColors ?? this.typingColors,
      attentions: attentions ?? this.attentions,
      ghosts: ghosts ?? this.ghosts,
    );
  }

  bool get someoneTyping => typingColors.isNotEmpty;
}

class PresenceNotifier extends StateNotifier<PresenceState> {
  final SocketService _service;
  StreamSubscription<int>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _attentionSub;
  StreamSubscription<List<Map<String, dynamic>>>? _ghostsSub;
  Timer? _typingCleanupTimer;

  PresenceNotifier(this._service) : super(const PresenceState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _presenceSub = _service.presenceStream.listen((count) {
      state = state.copyWith(count: count);
    });

    _typingSub = _service.typingStream.listen((data) {
      final color = data['color'] as String?;
      final isTyping = data['typing'] as bool? ?? false;

      if (color != null) {
        final newSet = Set<String>.from(state.typingColors);
        if (isTyping) {
          newSet.add(color);
          _startTypingCleanup(color);
        } else {
          newSet.remove(color);
        }
        state = state.copyWith(typingColors: newSet);
      }
    });

    _attentionSub = _service.attentionStream.listen((data) {
      final attention = Attention.fromJson(data);
      final updated = List<Attention>.from(state.attentions);
      // Remove existing attention for same color
      updated.removeWhere((a) => a.color == attention.color);
      updated.add(attention);
      state = state.copyWith(attentions: updated);
    });

    _ghostsSub = _service.ghostsStream.listen((ghostsData) {
      final ghosts = ghostsData
          .map((g) => PresenceGhost.fromJson(g))
          .where((g) => !g.isExpired)
          .toList();
      state = state.copyWith(ghosts: ghosts);
    });
  }

  void _startTypingCleanup(String color) {
    // Auto-remove typing after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final newSet = Set<String>.from(state.typingColors);
        newSet.remove(color);
        state = state.copyWith(typingColors: newSet);
      }
    });
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    _typingSub?.cancel();
    _attentionSub?.cancel();
    _ghostsSub?.cancel();
    _typingCleanupTimer?.cancel();
    super.dispose();
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>((ref) {
  final socketNotifier = ref.watch(socketProvider.notifier);
  return PresenceNotifier(socketNotifier.service);
});
