import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';
import '../providers/socket_provider.dart';
import '../providers/stream_provider.dart';
import '../providers/identity_provider.dart';
import '../providers/mood_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  final VoidCallback? onSlashCommand;
  final void Function(String command, String? arg)? onCommand;

  const ChatInput({
    super.key,
    this.onSlashCommand,
    this.onCommand,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _isTyping = false;
  static const int maxLength = 500;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    final socketNotifier = ref.read(socketProvider.notifier);
    if (_focusNode.hasFocus) {
      socketNotifier.focus();
    } else {
      socketNotifier.blur();
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(socketProvider.notifier).sendTyping();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        ref.read(socketProvider.notifier).sendTypingStop();
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (text.length > maxLength) {
      _showError('Message too long (max $maxLength characters)');
      return;
    }

    // Check for slash commands
    if (text.startsWith('/')) {
      _handleSlashCommand(text);
      return;
    }

    // Send regular message
    ref.read(socketProvider.notifier).sendMessage(text);
    _controller.clear();
    _stopTyping();
  }

  void _handleSlashCommand(String text) {
    final parts = text.substring(1).split(' ');
    final command = parts[0].toLowerCase();
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    switch (command) {
      case 'clear':
        ref.read(messageStreamProvider.notifier).clear();
        ref.read(messageStreamProvider.notifier).addSystemMessage('Stream cleared');
        break;
      case 'help':
        _showHelp();
        break;
      case 'anon':
        ref.read(identityProvider.notifier).goAnonymous();
        ref.read(messageStreamProvider.notifier).addSystemMessage('Identity hidden');
        break;
      case 'id':
        _showIdentity();
        break;
      case 'mood':
        _showMood();
        break;
      case 'whisper':
        if (arg != null && arg.isNotEmpty) {
          ref.read(socketProvider.notifier).sendMessage('/whisper $arg');
        } else {
          ref.read(messageStreamProvider.notifier).addSystemMessage('Usage: /whisper <message>');
        }
        break;
      case 'away':
        ref.read(socketProvider.notifier).away();
        ref.read(messageStreamProvider.notifier).addSystemMessage('Stepping away...');
        break;
      case 'back':
        ref.read(socketProvider.notifier).back();
        ref.read(messageStreamProvider.notifier).addSystemMessage('Welcome back');
        break;
      case 'copy':
        _copyLatest();
        break;
      default:
        // Send to server for handling
        ref.read(socketProvider.notifier).sendMessage(text);
    }

    _controller.clear();
    widget.onCommand?.call(command, arg);
  }

  void _showHelp() {
    final commands = [
      '/clear — clear stream',
      '/help — show help',
      '/anon — go anonymous',
      '/id — show identity',
      '/mood — show atmosphere',
      '/copy — copy latest message',
      '/whisper — quieter message',
      '/away / /back — presence',
    ];
    for (final cmd in commands) {
      ref.read(messageStreamProvider.notifier).addSystemMessage(cmd);
    }
  }

  void _showIdentity() {
    final identity = ref.read(identityProvider);
    ref.read(messageStreamProvider.notifier).addSystemMessage(
      'Your color: ${identity.colorHex}',
    );
    if (identity.handle != null) {
      ref.read(messageStreamProvider.notifier).addSystemMessage(
        'Handle: ${identity.handle}',
      );
    }
    if (identity.tag != null) {
      ref.read(messageStreamProvider.notifier).addSystemMessage(
        'Tag: ${identity.tag}',
      );
    }
  }

  void _showMood() {
    final moodName = ref.read(moodProvider.notifier).moodName;
    ref.read(messageStreamProvider.notifier).addSystemMessage(
      'Current mood: $moodName',
    );
  }

  void _copyLatest() {
    final latest = ref.read(messageStreamProvider.notifier).latestMessage;
    if (latest != null) {
      // In a real app, this would copy to clipboard
      ref.read(socketProvider.notifier).notifyCopy(latest.id);
      ref.read(messageStreamProvider.notifier).addSystemMessage('Copied to clipboard');
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      ref.read(socketProvider.notifier).sendTypingStop();
    }
  }

  void _showError(String message) {
    ref.read(messageStreamProvider.notifier).addSystemMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final socketState = ref.watch(socketProvider);
    final isConnected = socketState.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WitchColors.soot800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WitchColors.plum900.withOpacity(0.4),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: isConnected,
                maxLength: maxLength,
                maxLines: 1,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: WitchColors.parchment,
                ),
                decoration: InputDecoration(
                  hintText: isConnected ? 'Speak... (or /help)' : 'Connecting...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: WitchColors.parchmentMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: isConnected ? WitchColors.plum700 : WitchColors.soot700,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isConnected ? _sendMessage : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.send_rounded,
                  color: isConnected
                      ? WitchColors.parchment
                      : WitchColors.parchmentMuted,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
