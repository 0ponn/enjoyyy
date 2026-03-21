import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';
import '../providers/socket_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/stream_provider.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketProvider);
    final presenceState = ref.watch(presenceProvider);
    final moodNotifier = ref.watch(moodProvider.notifier);
    final streamState = ref.watch(messageStreamProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Room selector (simplified for now)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WitchColors.soot800.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WitchColors.plum900.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  socketState.currentRoom ?? 'lobby',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: WitchColors.parchment,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  size: 14,
                  color: WitchColors.parchmentMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Separator
          Text(
            '·',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: WitchColors.parchmentMuted,
            ),
          ),
          const SizedBox(width: 8),
          // Connection status
          _buildConnectionStatus(socketState.connectionState),
          const SizedBox(width: 8),
          // Separator
          Text(
            '·',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: WitchColors.parchmentMuted,
            ),
          ),
          const SizedBox(width: 8),
          // Stream count
          Text(
            '${streamState.messages.length.clamp(0, 6)} in stream',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              color: WitchColors.parchmentMuted,
            ),
          ),
          const Spacer(),
          // Mood indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WitchColors.soot800.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              moodNotifier.moodName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: WitchColors.sage400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Presence count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: presenceState.count > 1
                      ? WitchColors.forest500
                      : WitchColors.sage500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${presenceState.count}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: WitchColors.parchmentMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(SocketConnectionState state) {
    Color dotColor;
    String label;

    switch (state) {
      case SocketConnectionState.connected:
        dotColor = WitchColors.forest500;
        label = 'Connected';
        break;
      case SocketConnectionState.connecting:
        dotColor = WitchColors.amber500;
        label = 'Connecting';
        break;
      case SocketConnectionState.disconnected:
        dotColor = WitchColors.error;
        label = 'Disconnected';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            color: WitchColors.parchmentMuted,
          ),
        ),
      ],
    );
  }
}
