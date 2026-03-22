import 'package:flutter/material.dart';

class WitchColors {
  WitchColors._();

  // Soot (backgrounds)
  static const Color soot950 = Color(0xFF0c090d);
  static const Color soot900 = Color(0xFF120f12);
  static const Color soot800 = Color(0xFF1a161a);
  static const Color soot700 = Color(0xFF231e24);

  // Forest (calm mood)
  static const Color forest900 = Color(0xFF0e1610);
  static const Color forest700 = Color(0xFF1a2a1c);
  static const Color forest500 = Color(0xFF3d5240);

  // Plum (identity, accents)
  static const Color plum900 = Color(0xFF2a1f2e);
  static const Color plum700 = Color(0xFF3d2a42);
  static const Color plum500 = Color(0xFF5a3d5e);
  static const Color plum400 = Color(0xFF7b5278);

  // Sage (muted UI)
  static const Color sage500 = Color(0xFF5c6b5c);
  static const Color sage400 = Color(0xFF7a8a7a);

  // Amber (highlights)
  static const Color amber500 = Color(0xFFb8942e);
  static const Color amber400 = Color(0xFFc9a227);

  // Text
  static const Color parchment = Color(0xFFe0d9d0);
  static const Color parchmentMuted = Color(0xFFa89f94);

  // Additional utility colors
  static const Color error = Color(0xFFcf6679);
  static const Color success = Color(0xFF4caf50);
  static const Color warning = Color(0xFFff9800);

  // Glass effect colors
  static Color glassBackground = soot900.withValues(alpha: 0.65);
  static Color glassBorder = plum900.withValues(alpha: 0.4);
}
