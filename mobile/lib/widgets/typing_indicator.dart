import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';
import '../providers/presence_provider.dart';

class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceState = ref.watch(presenceProvider);

    if (!presenceState.someoneTyping) {
      return const SizedBox(height: 20);
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TypingDots(),
          const SizedBox(width: 8),
          Text(
            'Someone is speaking...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: WitchColors.parchmentMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final scale = 0.5 + 0.5 * _pulse(value);

            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: WitchColors.parchmentMuted.withOpacity(scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  double _pulse(double t) {
    // Create a pulse effect
    if (t < 0.5) {
      return t * 2;
    } else {
      return 2 - t * 2;
    }
  }
}
