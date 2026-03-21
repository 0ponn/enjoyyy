import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/witch_colors.dart';
import '../theme/witch_gradients.dart';
import '../providers/socket_provider.dart';
import '../providers/mood_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/glamour.dart';
import '../widgets/message_stream.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/ambiance.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Connect on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final socketNotifier = ref.read(socketProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        socketNotifier.away();
        break;
      case AppLifecycleState.resumed:
        socketNotifier.back();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodProvider);
    final gradient = WitchGradients.forMood(mood);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // Ambient particles
            const Positioned.fill(
              child: Ambiance(),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar with status and glamour
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          WitchColors.soot950.withOpacity(0.8),
                          WitchColors.soot950.withOpacity(0),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Expanded(child: StatusBar()),
                              const Glamour(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Message stream (centered in remaining space)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        const MessageStream(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Bottom input area
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          WitchColors.soot950.withOpacity(0.9),
                          WitchColors.soot950.withOpacity(0),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const TypingIndicator(),
                        const ChatInput(),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
