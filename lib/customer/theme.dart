import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerTheme {
  // Colors
  static const Color pageBackground = Color(0xFFFFF5F7); // Ultra soft pink
  static const Color primaryActionStart = Color(0xFFFFB6D3); // Vibrant Pink
  static const Color primaryActionEnd = Color(0xFFEC407A); // Deep Pink
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF4A152C); // Deep berry text
  static const Color accent = Color(0xFFC2185B); // Rich Pink/Berry
  static const Color secondaryText = Color(0xFFFF4D8D); // Medium berry
  static const Color inactiveIcon = Color(0xFFD81B60);
  static const Color inputBorder = Color(0xFFF8BBD0);
  static const Color tagBackground = Color(0xFFFCE4EC);
  static const Color logoColor = Color(0xFF880E4F); // Dark berry logo
  static const Color headingText = Color(0xFF51102A); // Dark berry heading

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryActionStart, primaryActionEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme {
    return ThemeData(
      primaryColor: accent,
      scaffoldBackgroundColor: pageBackground,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: primaryActionEnd,
        surface: cardSurface,
        background: pageBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: accent),
        titleTextStyle: GoogleFonts.notoSerif(
          color: logoColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(
          color: headingText,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          color: headingText,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          color: primaryText,
          fontSize: 24,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          color: primaryText,
          fontSize: 20,
        ),
        titleLarge: GoogleFonts.dmSerifDisplay(
          color: primaryText,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.inter(
          color: primaryText,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          color: secondaryText,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.inter(
          color: secondaryText,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.inter(
          color: accent,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pageBackground,
        selectedItemColor: accent,
        unselectedItemColor: inactiveIcon,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
    );
  }
}
