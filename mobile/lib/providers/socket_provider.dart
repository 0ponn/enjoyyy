import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

enum SocketConnectionState { disconnected, connecting, connected }

class SocketState {
  final SocketConnectionState connectionState;
  final String? ownColor;
  final String? currentRoom;
  final String? error;

  const SocketState({
    this.connectionState = SocketConnectionState.disconnected,
    this.ownColor,
    this.currentRoom,
    this.error,
  });

  SocketState copyWith({
    SocketConnectionState? connectionState,
    String? ownColor,
    String? currentRoom,
    String? error,
  }) {
    return SocketState(
      connectionState: connectionState ?? this.connectionState,
      ownColor: ownColor ?? this.ownColor,
      currentRoom: currentRoom ?? this.currentRoom,
      error: error,
    );
  }

  bool get isConnected => connectionState == SocketConnectionState.connected;
}

class SocketNotifier extends StateNotifier<SocketState> {
  final SocketService _service = SocketService();
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _identitySub;

  SocketNotifier() : super(const SocketState());

  void connect({String? preferredColor, String? room}) {
    state = state.copyWith(connectionState: SocketConnectionState.connecting);

    _connectionSub?.cancel();
    _identitySub?.cancel();

    _connectionSub = _service.connectionStream.listen((connected) {
      if (connected) {
        state = state.copyWith(connectionState: SocketConnectionState.connected);
      } else {
        state = state.copyWith(connectionState: SocketConnectionState.disconnected);
      }
    });

    _identitySub = _service.identityStream.listen((data) {
      if (data['type'] == 'connected') {
        state = state.copyWith(
          ownColor: data['color'] as String?,
          currentRoom: data['room'] as String?,
        );
      }
    });

    _service.connect(preferredColor: preferredColor, room: room);
  }

  void disconnect() {
    _service.disconnect();
    state = state.copyWith(connectionState: SocketConnectionState.disconnected);
  }

  void sendMessage(String text) {
    _service.sendMessage(text);
  }

  void sendTyping() {
    _service.sendTyping();
  }

  void sendTypingStop() {
    _service.sendTypingStop();
  }

  void reveal(Map<String, dynamic> identity) {
    _service.reveal(identity);
  }

  void focus() {
    _service.focus();
  }

  void blur() {
    _service.blur();
  }

  void away() {
    _service.away();
  }

  void back() {
    _service.back();
  }

  void notifyCopy(String messageId) {
    _service.notifyCopy(messageId);
  }

  void affirm(String messageId) {
    _service.affirm(messageId);
  }

  void joinRoom(String room) {
    _service.joinRoom(room);
    state = state.copyWith(currentRoom: room);
  }

  SocketService get service => _service;

  @override
  void dispose() {
    _connectionSub?.cancel();
    _identitySub?.cancel();
    super.dispose();
  }
}

final socketProvider = StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier();
});
