import 'package:flutter/material.dart';

class Attention {
  final bool focused;
  final Color color;
  final String? handle;
  final bool steppingAway;

  const Attention({
    required this.focused,
    required this.color,
    this.handle,
    this.steppingAway = false,
  });

  factory Attention.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color'] as String? ?? '#ffffff';
    final color = _parseColor(colorHex);

    return Attention(
      focused: json['focused'] as bool? ?? false,
      color: color,
      handle: json['handle'] as String?,
      steppingAway: json['steppingAway'] as bool? ?? false,
    );
  }

  static Color _parseColor(String hex) {
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFFFFFFF);
  }
}

class PresenceGhost {
  final Color color;
  final String? handle;
  final DateTime departedAt;

  const PresenceGhost({
    required this.color,
    this.handle,
    required this.departedAt,
  });

  factory PresenceGhost.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color'] as String? ?? '#ffffff';
    final color = _parseColor(colorHex);

    return PresenceGhost(
      color: color,
      handle: json['handle'] as String?,
      departedAt: json['departedAt'] != null
          ? DateTime.tryParse(json['departedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Color _parseColor(String hex) {
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFFFFFFF);
  }

  bool get isExpired {
    return DateTime.now().difference(departedAt).inMinutes >= 3;
  }
}
