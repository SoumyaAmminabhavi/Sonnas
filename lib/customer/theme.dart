import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerTheme {
  // Colors — Light
  static const Color pageBackgroundLight = Color(0xFFFFF5F7);
  static const Color cardSurfaceLight = Color(0xFFFFFFFF);
  static const Color primaryTextLight = Color(0xFF4A152C);
  static const Color accentLight = Color(0xFFC2185B);
  static const Color secondaryTextLight = Color(0xFFFF4D8D);
  static const Color inactiveIconLight = Color(0xFFD81B60);
  static const Color inputBorderLight = Color(0xFFF8BBD0);
  static const Color tagBackgroundLight = Color(0xFFFCE4EC);
  static const Color logoColorLight = Color(0xFF880E4F);
  static const Color headingTextLight = Color(0xFF51102A);
  static const Color primaryActionStartLight = Color(0xFFFFB6D3);
  static const Color primaryActionEndLight = Color(0xFFEC407A);

  // Colors — Dark
  static const Color pageBackgroundDark = Color(0xFF1A0F14);
  static const Color cardSurfaceDark = Color(0xFF2D1B22);
  static const Color primaryTextDark = Color(0xFFFFF0F6);
  static const Color accentDark = Color(0xFFFF4D8D);
  static const Color secondaryTextDark = Color(0xFFFFB6D3);
  static const Color inactiveIconDark = Color(0xFF964261);
  static const Color inputBorderDark = Color(0xFF701235);
  static const Color tagBackgroundDark = Color(0xFF2D1B22);
  static const Color logoColorDark = Color(0xFFFFB6D3);
  static const Color headingTextDark = Color(0xFFFFF0F6);
  static const Color primaryActionStartDark = Color(0xFF701235);
  static const Color primaryActionEndDark = Color(0xFFFF4D8D);

  // Gradients
  static LinearGradient primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [primaryActionStartDark, primaryActionEndDark]
          : [primaryActionStartLight, primaryActionEndLight],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentLight,
      scaffoldBackgroundColor: pageBackgroundLight,
      colorScheme: const ColorScheme.light(
        primary: accentLight,
        onPrimary: Colors.white,
        primaryContainer: tagBackgroundLight,
        onPrimaryContainer: logoColorLight,
        secondary: primaryActionEndLight,
        onSecondary: Colors.white,
        secondaryContainer: inputBorderLight,
        onSecondaryContainer: primaryTextLight,
        surface: pageBackgroundLight,
        onSurface: primaryTextLight,
        surfaceContainerLow: tagBackgroundLight,
        surfaceContainer: inputBorderLight,
        surfaceContainerHigh: logoColorLight,
        onSurfaceVariant: secondaryTextLight,
        outline: inputBorderLight,
        outlineVariant: secondaryTextLight,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: accentLight),
        titleTextStyle: GoogleFonts.notoSerif(
          color: logoColorLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
      textTheme: _textTheme(primaryTextLight, secondaryTextLight, accentLight, headingTextLight),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pageBackgroundLight,
        selectedItemColor: accentLight,
        unselectedItemColor: inactiveIconLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: pageBackgroundLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentDark,
      scaffoldBackgroundColor: pageBackgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: accentDark,
        onPrimary: Color(0xFF3E0020),
        primaryContainer: tagBackgroundDark,
        onPrimaryContainer: secondaryTextDark,
        secondary: primaryActionEndDark,
        onSecondary: Color(0xFF3E0020),
        secondaryContainer: inputBorderDark,
        onSecondaryContainer: primaryTextDark,
        surface: pageBackgroundDark,
        onSurface: primaryTextDark,
        surfaceContainerLow: cardSurfaceDark,
        surfaceContainer: inputBorderDark,
        surfaceContainerHigh: Color(0xFF422836),
        onSurfaceVariant: secondaryTextDark,
        outline: inputBorderDark,
        outlineVariant: secondaryTextDark,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pageBackgroundDark.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: accentDark),
        titleTextStyle: GoogleFonts.notoSerif(
          color: logoColorDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
      textTheme: _textTheme(primaryTextDark, secondaryTextDark, accentDark, headingTextDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pageBackgroundDark,
        selectedItemColor: accentDark,
        unselectedItemColor: inactiveIconDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: pageBackgroundDark,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary, Color accent, Color heading) {
    return TextTheme(
      displayLarge: GoogleFonts.dmSerifDisplay(color: heading, fontSize: 32),
      displayMedium: GoogleFonts.dmSerifDisplay(color: heading, fontSize: 28),
      displaySmall: GoogleFonts.dmSerifDisplay(color: primary, fontSize: 24),
      headlineMedium: GoogleFonts.dmSerifDisplay(color: primary, fontSize: 20),
      titleLarge: GoogleFonts.dmSerifDisplay(color: primary, fontSize: 18),
      bodyLarge: GoogleFonts.inter(color: primary, fontSize: 14),
      bodyMedium: GoogleFonts.inter(color: secondary, fontSize: 13),
      labelLarge: GoogleFonts.inter(color: secondary, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(color: accent, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
    );
  }
}
