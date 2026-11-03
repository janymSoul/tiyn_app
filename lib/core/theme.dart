import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Palette {
  static const navy = Color(0xFF10213A);
  static const gold = Color(0xFFF5B800);
  static const goldSoft = Color(0xFFFBDD7A);
  static const goldWash = Color(0xFFFDF0C2);
  static const background = Color(0xFFF4F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF4A5A70);
  static const line = Color(0xFFE6EBF0);
  static const border = Color(0xFFD5DEE7);
  static const infoWash = Color(0xFFDDF0F9);
  static const infoText = Color(0xFF0B5A80);
  static const blue = Color(0xFF1E9BD0);
  static const warn = Color(0xFFA8430C);
  static const onNavyMuted = Color(0xFFC5D0DE);
  static const ringOnNavy = Color(0xFF3C4D68);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.navy,
    primary: Palette.navy,
    onPrimary: Colors.white,
    surface: Palette.background,
    error: Palette.warn,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Palette.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.rubikTextTheme(base.textTheme)
        .apply(bodyColor: Palette.navy, displayColor: Palette.navy),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Palette.navy, width: 2),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
