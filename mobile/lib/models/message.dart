import 'package:flutter/material.dart';

enum Sigil { spiral, eye, triangle, cross, diamond }

class Message {
  final String id;
  final String text;
  final Color color;
  final String colorHex;
  final String? handle;
  final String? tag;
  final Sigil? sigil;
  final bool whisper;
  final DateTime timestamp;
  final bool isSystem;
  final bool isOwn;
  final String? affirmCount;

  Message({
    required this.id,
    required this.text,
    required this.color,
    required this.colorHex,
    this.handle,
    this.tag,
    this.sigil,
    this.whisper = false,
    DateTime? timestamp,
    this.isSystem = false,
    this.isOwn = false,
    this.affirmCount,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json, {String? ownColor}) {
    final hex = json['color'] as String? ?? '#ffffff';
    final color = _parseColor(hex);

    Sigil? sigil;
    if (json['sigil'] != null) {
      sigil = Sigil.values.firstWhere(
        (s) => s.name == json['sigil'],
        orElse: () => Sigil.spiral,
      );
    }

    return Message(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      color: color,
      colorHex: hex.toLowerCase(),
      handle: json['handle'] as String?,
      tag: json['tag'] as String?,
      sigil: sigil,
      whisper: json['whisper'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
      isOwn: ownColor != null && hex.toLowerCase() == ownColor.toLowerCase(),
      affirmCount: json['affirmCount']?.toString(),
    );
  }

  static Color _parseColor(String hex) {
    String cleanHex = hex;
    if (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return const Color(0xFFFFFFFF);
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  Message copyWith({
    String? id,
    String? text,
    Color? color,
    String? colorHex,
    String? handle,
    String? tag,
    Sigil? sigil,
    bool? whisper,
    DateTime? timestamp,
    bool? isSystem,
    bool? isOwn,
    String? affirmCount,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      handle: handle ?? this.handle,
      tag: tag ?? this.tag,
      sigil: sigil ?? this.sigil,
      whisper: whisper ?? this.whisper,
      timestamp: timestamp ?? this.timestamp,
      isSystem: isSystem ?? this.isSystem,
      isOwn: isOwn ?? this.isOwn,
      affirmCount: affirmCount ?? this.affirmCount,
    );
  }
}
