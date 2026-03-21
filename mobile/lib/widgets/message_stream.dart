import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stream_provider.dart';
import 'message_bubble.dart';

class MessageStream extends ConsumerWidget {
  const MessageStream({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamState = ref.watch(messageStreamProvider);
    final messages = streamState.messages;

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      reverse: true,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length.clamp(0, 6),
      itemBuilder: (context, index) {
        final message = messages[index];
        final opacity = streamState.fadeOpacity(index);
        final blur = streamState.fadeBlur(index);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          child: MessageBubble(
            key: ValueKey(message.id),
            message: message,
            opacity: opacity,
            blurAmount: blur,
          ),
        );
      },
    );
  }
}
