import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Buz TV inspired — deep dark + purple accent
  static const Color primary = Color(0xFF0E0E0E);
  static const Color secondary = Color(0xFF141414);
  static const Color accent = Color(0xFF7B5CF6);     // Purple
  static const Color highlight = Color(0xFF7B5CF6);  // Purple (same)
  static const Color surface = Color(0xFF0E0E0E);
  static const Color cardBg = Color(0xFF1C1C1E);
  static const Color cardBorder = Color(0xFF2C2C2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surface,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: cardBg,
          background: surface,
          onPrimary: Colors.white,
        ),
        textTheme: GoogleFonts.cairoTextTheme(const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        )),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          titleTextStyle: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: const CardThemeData(
          color: cardBg,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          labelStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF141414),
          selectedItemColor: accent,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          showUnselectedLabels: true,
        ),
        dividerTheme: const DividerThemeData(
          color: cardBorder,
          thickness: 0.5,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      );
}
