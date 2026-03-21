import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../theme/witch_gradients.dart';
import 'socket_provider.dart';

class MoodNotifier extends StateNotifier<Mood> {
  final SocketService _service;
  StreamSubscription<String>? _moodSub;

  MoodNotifier(this._service) : super(Mood.neutral) {
    _setupListener();
  }

  void _setupListener() {
    _moodSub = _service.moodStream.listen((moodStr) {
      switch (moodStr.toLowerCase()) {
        case 'calm':
          state = Mood.calm;
          break;
        case 'intense':
          state = Mood.intense;
          break;
        default:
          state = Mood.neutral;
      }
    });
  }

  String get moodName {
    switch (state) {
      case Mood.calm:
        return 'calm';
      case Mood.intense:
        return 'intense';
      case Mood.neutral:
        return 'neutral';
    }
  }

  @override
  void dispose() {
    _moodSub?.cancel();
    super.dispose();
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, Mood>((ref) {
  final socketNotifier = ref.watch(socketProvider.notifier);
  return MoodNotifier(socketNotifier.service);
});
