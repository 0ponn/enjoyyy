import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';
import '../providers/identity_provider.dart';
import '../models/message.dart';
import 'sigil_icon.dart';

class Glamour extends ConsumerWidget {
  const Glamour({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);

    return GestureDetector(
      onTap: () => _showIdentityPanel(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: identity.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: identity.color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (identity.isRevealed) ...[
              const SizedBox(width: 8),
              if (identity.sigil != null)
                SigilIcon(
                  sigil: identity.sigil!,
                  size: 14,
                  color: identity.color.withValues(alpha: 0.7),
                ),
              if (identity.handle != null) ...[
                const SizedBox(width: 6),
                Text(
                  identity.handle!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: WitchColors.plum400,
                  ),
                ),
              ],
            ],
            const SizedBox(width: 8),
            Icon(
              identity.isRevealed ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: WitchColors.parchmentMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showIdentityPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _IdentityPanel(ref: ref),
    );
  }
}

class _IdentityPanel extends StatefulWidget {
  final WidgetRef ref;

  const _IdentityPanel({required this.ref});

  @override
  State<_IdentityPanel> createState() => _IdentityPanelState();
}

class _IdentityPanelState extends State<_IdentityPanel> {
  final _handleController = TextEditingController();
  final _tagController = TextEditingController();
  Sigil? _selectedSigil;

  @override
  void initState() {
    super.initState();
    final identity = widget.ref.read(identityProvider);
    _handleController.text = identity.handle ?? '';
    _tagController.text = identity.tag ?? '';
    _selectedSigil = identity.sigil;
  }

  @override
  void dispose() {
    _handleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _reveal() {
    final handle = _handleController.text.trim();
    final tag = _tagController.text.trim();

    widget.ref.read(identityProvider.notifier).reveal(
          handle: handle.isNotEmpty ? handle : null,
          tag: tag.isNotEmpty ? tag : null,
          sigil: _selectedSigil,
        );
    Navigator.pop(context);
  }

  void _goAnonymous() {
    widget.ref.read(identityProvider.notifier).goAnonymous();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.ref.watch(identityProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WitchColors.soot900.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: WitchColors.plum900.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: identity.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Identity',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: WitchColors.parchment,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    identity.colorHex,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: WitchColors.parchmentMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Handle field
              Text(
                'Handle',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: WitchColors.parchmentMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _handleController,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: WitchColors.parchment,
                ),
                decoration: InputDecoration(
                  hintText: 'Choose a name...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: WitchColors.parchmentMuted,
                  ),
                  filled: true,
                  fillColor: WitchColors.soot800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tag field
              Text(
                'Tag (optional)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: WitchColors.parchmentMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tagController,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: WitchColors.parchment,
                ),
                decoration: InputDecoration(
                  hintText: 'A whisper of context...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: WitchColors.parchmentMuted,
                  ),
                  filled: true,
                  fillColor: WitchColors.soot800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sigil selector
              Text(
                'Sigil',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: WitchColors.parchmentMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: Sigil.values.map((sigil) {
                  final isSelected = _selectedSigil == sigil;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSigil = _selectedSigil == sigil ? null : sigil;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? WitchColors.plum700.withValues(alpha: 0.5)
                            : WitchColors.soot800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? WitchColors.plum500
                              : Colors.transparent,
                        ),
                      ),
                      child: SigilIcon(
                        sigil: sigil,
                        size: 24,
                        color: isSelected
                            ? identity.color
                            : WitchColors.parchmentMuted,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goAnonymous,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WitchColors.parchmentMuted,
                        side: BorderSide(
                          color: WitchColors.plum900.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Go Anonymous',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _reveal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WitchColors.plum700,
                        foregroundColor: WitchColors.parchment,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reveal',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
