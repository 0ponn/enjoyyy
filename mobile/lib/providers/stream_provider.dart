import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import 'socket_provider.dart';
import 'blocked_provider.dart';

const int ruleOfThree = 3;
const int maxVisible = 6;

class MessageStreamState {
  final List<Message> messages;
  final bool isLoading;

  const MessageStreamState({
    this.messages = const [],
    this.isLoading = false,
  });

  MessageStreamState copyWith({
    List<Message>? messages,
    bool? isLoading,
  }) {
    return MessageStreamState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int fadeLevel(int index) {
    if (index < ruleOfThree) {
      return 0;
    }
    return (index - ruleOfThree + 1).clamp(0, 3);
  }

  double fadeOpacity(int index) {
    final level = fadeLevel(index);
    // More aggressive fade: 1.0 -> 0.6 -> 0.3 -> 0.1
    return (1 - level * 0.35).clamp(0.1, 1.0);
  }

  double fadeBlur(int index) {
    final level = fadeLevel(index);
    // More blur for faded messages
    return level * 4.0;
  }
}

class MessageStreamNotifier extends StateNotifier<MessageStreamState> {
  final SocketService _service;
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _affirmSub;

  MessageStreamNotifier(this._ref, this._service) : super(const MessageStreamState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _messageSub = _service.messageStream.listen((data) {
      final socketState = _ref.read(socketProvider);
      final message = Message.fromJson(data, ownColor: socketState.ownColor);
      
      // Filter out blocked users
      final blocked = _ref.read(blockedProvider);
      if (!blocked.contains(message.colorHex)) {
        _addMessage(message);
      }
    });

    _affirmSub = _service.affirmStream.listen((data) {
      final messageId = data['messageId'] as String?;
      final count = data['count']?.toString();
      if (messageId != null) {
        _updateAffirmCount(messageId, count);
      }
    });
  }

  void _addMessage(Message message) {
    final newMessages = [message, ...state.messages];
    // Keep only max visible + buffer for scroll
    final trimmed = newMessages.take(maxVisible + 10).toList();
    state = state.copyWith(messages: trimmed);
  }

  void _updateAffirmCount(String messageId, String? count) {
    final updated = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(affirmCount: count);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void addSystemMessage(String text) {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      color: const Color(0xFF7a8a7a),
      colorHex: '#7a8a7a',
      isSystem: true,
    );
    _addMessage(message);
  }

  void clear() {
    state = state.copyWith(messages: []);
  }

  Message? get latestMessage => state.messages.isNotEmpty ? state.messages.first : null;

  @override
  void dispose() {
    _messageSub?.cancel();
    _affirmSub?.cancel();
    super.dispose();
  }
}

final messageStreamProvider =
    StateNotifierProvider<MessageStreamNotifier, MessageStreamState>((ref) {
  final socketNotifier = ref.watch(socketProvider.notifier);
  return MessageStreamNotifier(ref, socketNotifier.service);
});
