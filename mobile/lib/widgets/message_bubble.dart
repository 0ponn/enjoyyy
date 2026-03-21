import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../theme/witch_colors.dart';
import '../providers/blocked_provider.dart';
import 'sigil_icon.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final double opacity;
  final double blurAmount;

  const MessageBubble({
    super.key,
    required this.message,
    this.opacity = 1.0,
    this.blurAmount = 0.0,
  });

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WitchColors.soot900,
        title: Text(
          'Protect the Stream',
          style: GoogleFonts.spaceGrotesk(color: WitchColors.parchment),
        ),
        content: Text(
          'Would you like to block this user? Their messages will no longer appear in your stream.',
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
              ref.read(blockedProvider.notifier).block(message.colorHex);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked')),
              );
            },
            child: Text(
              'Block User',
              style: GoogleFonts.spaceGrotesk(color: WitchColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isSystem) {
      return _buildSystemMessage();
    }

    return GestureDetector(
      onLongPress: message.isOwn ? null : () => _showReportDialog(context, ref),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: opacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 500),
          scale: 0.95 + (opacity * 0.05),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12 + blurAmount,
                  sigmaY: 12 + blurAmount,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.whisper
                        ? WitchColors.soot800.withOpacity(0.5)
                        : WitchColors.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isOwn
                          ? message.color.withOpacity(0.3)
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
                          color: message.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Sigil icon
                      if (message.sigil != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 6, top: 2),
                          child: SigilIcon(
                            sigil: message.sigil!,
                            size: 12,
                            color: message.color.withOpacity(0.7),
                          ),
                        ),
                      ],
                      // Tag
                      if (message.tag != null) ...[
                        Text(
                          message.tag!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: WitchColors.sage400,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Handle
                      if (message.handle != null) ...[
                        Text(
                          message.handle!,
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
                          message.text,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: message.whisper
                                ? WitchColors.parchmentMuted
                                : WitchColors.parchment,
                            fontStyle: message.whisper ? FontStyle.italic : null,
                          ),
                        ),
                      ),
                      // Timestamp
                      const SizedBox(width: 8),
                      Text(
                        message.relativeTime,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: WitchColors.parchmentMuted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
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
        message.text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: WitchColors.sage400.withOpacity(opacity),
        ),
      ),
    );
  }
}
