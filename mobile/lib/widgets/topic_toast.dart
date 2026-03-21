import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/witch_colors.dart';

class TopicToast extends StatefulWidget {
  final String topic;
  final String? preview;
  final VoidCallback? onDismiss;

  const TopicToast({
    super.key,
    required this.topic,
    this.preview,
    this.onDismiss,
  });

  @override
  State<TopicToast> createState() => _TopicToastState();
}

class _TopicToastState extends State<TopicToast>
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
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _scheduleAutoDismiss();
  }

  void _scheduleAutoDismiss() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: WitchColors.amber500.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WitchColors.amber500.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 16,
                    color: WitchColors.amber400,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.topic,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: WitchColors.amber400,
                          ),
                        ),
                        if (widget.preview != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.preview!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: WitchColors.parchmentMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopicToastOverlay extends StatefulWidget {
  final Widget child;

  const TopicToastOverlay({
    super.key,
    required this.child,
  });

  @override
  State<TopicToastOverlay> createState() => TopicToastOverlayState();
}

class TopicToastOverlayState extends State<TopicToastOverlay> {
  final List<_ToastEntry> _toasts = [];
  int _nextId = 0;

  void showToast(String topic, {String? preview}) {
    setState(() {
      _toasts.add(_ToastEntry(
        id: _nextId++,
        topic: topic,
        preview: preview,
      ));
    });

    // Limit to 3 toasts
    if (_toasts.length > 3) {
      setState(() {
        _toasts.removeAt(0);
      });
    }
  }

  void _removeToast(int id) {
    setState(() {
      _toasts.removeWhere((t) => t.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _toasts.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TopicToast(
                  key: ValueKey(entry.id),
                  topic: entry.topic,
                  preview: entry.preview,
                  onDismiss: () => _removeToast(entry.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ToastEntry {
  final int id;
  final String topic;
  final String? preview;

  _ToastEntry({
    required this.id,
    required this.topic,
    this.preview,
  });
}
