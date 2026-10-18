import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores tomados del diseño "Login y registro pop-up"
class AuthColors {
  static const accent = Color(0xFF1D3BB3);
  static const accentDark = Color(0xFF142A85);
  static const text = Color(0xFF141833);
  static const label = Color(0xFF4A5170);
  static const muted = Color(0xFF6B7190);
  static const placeholder = Color(0xFF8A90A8);
  static const icon = Color(0xFF5A6180);
  static const fieldFill = Color(0xFFF3F5FB);
  static const fieldBorder = Color(0xFFDCE1EF);
  static const divider = Color(0xFFE3E6F0);
  static const headerSubtitle = Color(0xFFE3E8FA);
  static const error = Color(0xFFC62828);

  // rgba(6, 10, 28, 0.55): oscurece el feed pausado detrás del pop-up
  static const barrier = Color(0x8C060A1C);
}

class AuthTheme {

  // El pop-up es claro aunque la app use tema oscuro
  static ThemeData of(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AuthColors.accent,
        primary: AuthColors.accent,
        error: AuthColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AuthColors.text,
        displayColor: AuthColors.text,
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AuthColors.accent),
    );
  }

}
