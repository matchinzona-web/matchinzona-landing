import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0D1411);
  static const Color cardBg = Color(0xFF16201A);
  static const Color cardBorder = Color(0x12FFFFFF);

  static const Color textPrimary = Color(0xFFF5F3EE);
  static const Color textSecondary = Color(0xFF8A988F);
  static const Color textDisabled = Color(0xFF55615A);

  static const Color accent = Color(0xFF39FF14); // verde neon originale

  static const Color statoSuccesso = accent;
  static const Color statoAttenzione = Color(0xFFFF9100);
  static const Color statoErrore = Color(0xFFE14B4B);

  static const Color neonGreen = accent;
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonOrange = statoAttenzione;
  static const Color neonPurple = Color(0xFF9457EB);

  static const Color coloreBottoneAccedi = accent;
  static const Color coloreBottoneRegistrati = accent;
  static const Color testoChiaro = textPrimary;
  static const Color testoSecondario = textSecondary;

  static const String fontMono = 'monospace';

  // TEMA PRINCIPALE DELL'APP

  static ThemeData get darkNeonTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      useMaterial3: true,
      fontFamily: 'Roboto',

      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: cardBg,
      ),

      //STILE APPBAR
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: cardBorder, width: 1),
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
