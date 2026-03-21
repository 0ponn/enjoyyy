import 'package:flutter/material.dart';

enum Mood { calm, neutral, intense }

class WitchGradients {
  WitchGradients._();

  // Calm: deep forest night
  static const LinearGradient calm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0a0e0a),
      Color(0xFF0e1610),
      Color(0xFF142018),
      Color(0xFF0c120e),
    ],
  );

  // Neutral: soot + plum, cauldron simmer
  static const LinearGradient neutral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0c090d),
      Color(0xFF1a1418),
      Color(0xFF231a28),
      Color(0xFF120f12),
    ],
  );

  // Intense: ember and candle glow
  static const LinearGradient intense = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1a0f08),
      Color(0xFF2a1810),
      Color(0xFF3d2018),
      Color(0xFF1a0d08),
    ],
  );

  static LinearGradient forMood(Mood mood) {
    switch (mood) {
      case Mood.calm:
        return calm;
      case Mood.neutral:
        return neutral;
      case Mood.intense:
        return intense;
    }
  }
}
