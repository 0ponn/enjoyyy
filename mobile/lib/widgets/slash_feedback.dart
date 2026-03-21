import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';

class SlashFeedback extends StatefulWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const SlashFeedback({
    super.key,
    this.message,
    this.onDismiss,
  });

  @override
  State<SlashFeedback> createState() => _SlashFeedbackState();
}

class _SlashFeedbackState extends State<SlashFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.message != null) {
      _controller.forward();
      _scheduleAutoDismiss();
    }
  }

  void _scheduleAutoDismiss() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void didUpdateWidget(SlashFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message && widget.message != null) {
      _controller.forward(from: 0);
      _scheduleAutoDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: WitchColors.soot900.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WitchColors.plum900.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  widget.message!,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: WitchColors.parchment,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlashFeedbackOverlay extends StatelessWidget {
  final String? feedback;
  final Widget child;

  const SlashFeedbackOverlay({
    super.key,
    this.feedback,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (feedback != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: SlashFeedback(message: feedback),
          ),
      ],
    );
  }
}
