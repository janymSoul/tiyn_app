import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/design/tokens.dart';

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
