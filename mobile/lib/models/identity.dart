import 'package:flutter/material.dart';
import 'message.dart';

class Identity {
  final Color color;
  final String? handle;
  final String? tag;
  final Sigil? sigil;
  final bool isRevealed;

  const Identity({
    required this.color,
    this.handle,
    this.tag,
    this.sigil,
    this.isRevealed = false,
  });

  factory Identity.empty() {
    return const Identity(
      color: Color(0xFFFFFFFF),
    );
  }

  factory Identity.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color'] as String? ?? '#ffffff';
    final color = _parseColor(colorHex);

    Sigil? sigil;
    if (json['sigil'] != null) {
      sigil = Sigil.values.firstWhere(
        (s) => s.name == json['sigil'],
        orElse: () => Sigil.spiral,
      );
    }

    return Identity(
      color: color,
      handle: json['handle'] as String?,
      tag: json['tag'] as String?,
      sigil: sigil,
      isRevealed: json['handle'] != null || json['tag'] != null || json['sigil'] != null,
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

  String get colorHex {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Identity copyWith({
    Color? color,
    String? handle,
    String? tag,
    Sigil? sigil,
    bool? isRevealed,
  }) {
    return Identity(
      color: color ?? this.color,
      handle: handle ?? this.handle,
      tag: tag ?? this.tag,
      sigil: sigil ?? this.sigil,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }

  Map<String, dynamic> toRevealPayload() {
    return {
      if (handle != null) 'handle': handle,
      if (tag != null) 'tag': tag,
      if (sigil != null) 'sigil': sigil!.name,
    };
  }
}
