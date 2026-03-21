import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';
import '../providers/socket_provider.dart';

class RoomSelector extends ConsumerWidget {
  const RoomSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketProvider);
    final currentRoom = socketState.currentRoom ?? 'lobby';

    return GestureDetector(
      onTap: () => _showRoomPicker(context, ref, currentRoom),
      child: Container(
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
              currentRoom,
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
    );
  }

  void _showRoomPicker(BuildContext context, WidgetRef ref, String currentRoom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoomPickerSheet(
        currentRoom: currentRoom,
        onRoomSelected: (room) {
          ref.read(socketProvider.notifier).joinRoom(room);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _RoomPickerSheet extends StatefulWidget {
  final String currentRoom;
  final void Function(String room) onRoomSelected;

  const _RoomPickerSheet({
    required this.currentRoom,
    required this.onRoomSelected,
  });

  @override
  State<_RoomPickerSheet> createState() => _RoomPickerSheetState();
}

class _RoomPickerSheetState extends State<_RoomPickerSheet> {
  final _controller = TextEditingController();
  final _defaultRooms = ['lobby', 'quiet', 'midnight', 'grove'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createRoom() {
    final name = _controller.text.trim().toLowerCase();
    if (name.isNotEmpty && name.length <= 20) {
      widget.onRoomSelected(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WitchColors.soot900.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: WitchColors.plum900.withOpacity(0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Room',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WitchColors.parchment,
                ),
              ),
              const SizedBox(height: 16),
              // Default rooms
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _defaultRooms.map((room) {
                  final isSelected = room == widget.currentRoom;
                  return GestureDetector(
                    onTap: () => widget.onRoomSelected(room),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? WitchColors.plum700.withOpacity(0.5)
                            : WitchColors.soot800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? WitchColors.plum500
                              : WitchColors.plum900.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        room,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: isSelected
                              ? WitchColors.parchment
                              : WitchColors.parchmentMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Create custom room
              Text(
                'Or create a new room',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: WitchColors.parchmentMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: WitchColors.parchment,
                      ),
                      decoration: InputDecoration(
                        hintText: 'room name...',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: WitchColors.parchmentMuted,
                        ),
                        filled: true,
                        fillColor: WitchColors.soot800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WitchColors.plum700,
                      foregroundColor: WitchColors.parchment,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Join',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
