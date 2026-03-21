import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'witch_colors.dart';

class WitchTheme {
  WitchTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WitchColors.soot950,
      colorScheme: const ColorScheme.dark(
        surface: WitchColors.soot900,
        primary: WitchColors.plum500,
        secondary: WitchColors.amber500,
        onSurface: WitchColors.parchment,
        onPrimary: WitchColors.parchment,
        error: WitchColors.error,
      ),
      textTheme: _textTheme,
      inputDecorationTheme: _inputDecorationTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      iconTheme: const IconThemeData(
        color: WitchColors.parchmentMuted,
        size: 20,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      // Display - Space Grotesk
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: WitchColors.parchment,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: WitchColors.parchment,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: WitchColors.parchment,
      ),
      // Body - Space Grotesk
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: WitchColors.parchment,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        color: WitchColors.parchment,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        color: WitchColors.parchmentMuted,
      ),
      // Labels - JetBrains Mono for handles/code
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: WitchColors.plum400,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        color: WitchColors.plum400,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: WitchColors.sage400,
      ),
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: WitchColors.soot800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: WitchColors.plum900.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: WitchColors.plum900.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WitchColors.plum500),
      ),
      hintStyle: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: WitchColors.parchmentMuted,
      ),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WitchColors.plum700,
        foregroundColor: WitchColors.parchment,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
