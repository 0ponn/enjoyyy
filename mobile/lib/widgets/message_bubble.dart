import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../theme/witch_colors.dart';
import '../providers/blocked_provider.dart';
import '../providers/stream_provider.dart';
import 'sigil_icon.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final double opacity;
  final double blurAmount;

  const MessageBubble({
    super.key,
    required this.message,
    this.opacity = 1.0,
    this.blurAmount = 0.0,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _vanishController;
  late Animation<double> _vanishAnimation;

  @override
  void initState() {
    super.initState();
    _vanishController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _vanishAnimation = CurvedAnimation(
      parent: _vanishController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _vanishController.dispose();
    super.dispose();
  }

  // Call this to trigger the dissolve effect
  void vanish() {
    _vanishController.forward();
  }

  void _showBanishDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WitchColors.soot900,
        title: Text(
          'Banish Message?',
          style: GoogleFonts.spaceGrotesk(color: WitchColors.parchment),
        ),
        content: Text(
          'This will dissolve the message from your stream.',
          style: GoogleFonts.spaceGrotesk(color: WitchColors.parchmentMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: WitchColors.parchmentMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vanish(); // Trigger the animation
              ref.read(blockedProvider.notifier).block(widget.message.colorHex);
            },
            child: Text(
              'Banish',
              style: GoogleFonts.spaceGrotesk(color: WitchColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this message should vanish
    final streamState = ref.watch(messageStreamProvider);
    final shouldVanish = streamState.isVanishing(widget.message.id);

    // Trigger vanish animation when server requests
    if (shouldVanish && !_vanishController.isAnimating && _vanishController.value == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vanish();
        // After animation completes, notify provider to remove message
        _vanishController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            ref.read(messageStreamProvider.notifier).completeVanish(widget.message.id);
          }
        });
      });
    }

    if (widget.message.isSystem) {
      return _buildSystemMessage();
    }

    return AnimatedBuilder(
      animation: _vanishAnimation,
      builder: (context, child) {
        final v = _vanishAnimation.value;
        if (v == 1.0) return const SizedBox.shrink();

        return Opacity(
          opacity: (1.0 - v) * widget.opacity,
          child: Transform.translate(
            offset: Offset(0, -30 * v), // Drifts upward
            child: Transform.scale(
              scale: 1.0 + (0.1 * v), // Expands slightly
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onLongPress: widget.message.isOwn ? null : () => _showBanishDialog(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12 + widget.blurAmount,
                sigmaY: 12 + widget.blurAmount,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.message.whisper
                      ? WitchColors.soot800.withValues(alpha: 0.5)
                      : WitchColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.message.isOwn
                        ? widget.message.color.withValues(alpha: 0.3)
                        : WitchColors.glassBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color dot
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      decoration: BoxDecoration(
                        color: widget.message.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Sigil icon
                    if (widget.message.sigil != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 2),
                        child: SigilIcon(
                          sigil: widget.message.sigil!,
                          size: 12,
                          color: widget.message.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    // Tag
                    if (widget.message.tag != null) ...[
                      Text(
                        widget.message.tag!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: WitchColors.sage400,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Handle
                    if (widget.message.handle != null) ...[
                      Text(
                        widget.message.handle!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: WitchColors.plum400,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Message text
                    Expanded(
                      child: Text(
                        widget.message.text,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: widget.message.whisper
                              ? WitchColors.parchmentMuted
                              : WitchColors.parchment,
                          fontStyle: widget.message.whisper ? FontStyle.italic : null,
                        ),
                      ),
                    ),
                    // Timestamp
                    const SizedBox(width: 8),
                    Text(
                      widget.message.relativeTime,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: WitchColors.parchmentMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: Text(
        widget.message.text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: WitchColors.sage400.withValues(alpha: widget.opacity),
        ),
      ),
    );
  }
}
