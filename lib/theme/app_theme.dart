import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration
class AppTheme {
  // Color palette definition

  // Brand color (Seva Finance): Dark Green #1B4332
  static const brandGreen = Color(0xFF1B4332);
  // Backwards-compatible aliases used throughout the app codebase
  // Keep these to avoid large refactors while migrating to ColorScheme.
  static const primaryGreen = brandGreen; // alias for brand primary
  static const darkGreen = brandGreen; // primary actions
  static const darkerGreen = Color(0xFF154517); // pressed/darker state
  static const lightGreen = Color(0xFF2D6A4F); // supportive tint
  static const paleGreen = Color(0xFFE9F1EC); // light background tint
  static const backgroundColor = Color(0xFFFFFFFF); // White background
  static const textColor = Color(0xFF1A1A1A); // Nearly black text
  // Increase contrast for secondary text (approx. Colors.grey[700])
  static const secondaryTextColor = Color(0xFF616161);

  // Dark theme colors
  // Derive dark colors from the same seed to keep brand consistent
  static const darkPrimaryGreen = brandGreen;
  static const darkLightGreen = Color(0xFF2C654B);
  static const darkPaleGreen = Color(0xFF0E241B);
  static const darkDarkGreen = Color(0xFF3A7C60);
  static const darkDarkerGreen = Color(0xFF2E634B);
  static const darkBackgroundColor = Color(0xFF121212);
  static const darkTextColor = Color(0xFFE0E0E0);
  static const darkSecondaryTextColor = Color(0xFFAAAAAA);

  // Typography styles
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: MediaQuery.textScalerOf(context).scale(32),
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: MediaQuery.textScalerOf(context).scale(24),
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: MediaQuery.textScalerOf(context).scale(16),
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      );

  static TextStyle buttonText(BuildContext context) => GoogleFonts.inter(
        fontSize: MediaQuery.textScalerOf(context).scale(16),
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // Main theme configuration
  static ThemeData theme(BuildContext context) {
    final ColorScheme cs = ColorScheme.fromSeed(seedColor: brandGreen);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: backgroundColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      // Typography: Inter everywhere
      textTheme: GoogleFonts.interTextTheme(),
      iconTheme: const IconThemeData(size: 22),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: cs.primary,
        unselectedItemColor: secondaryTextColor,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardTheme(
        color: backgroundColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: cs.primary,
        textColor: textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        hintStyle: const TextStyle(color: secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          elevation: WidgetStateProperty.all(2),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return cs.primary.withOpacity(0.90);
            }
            return cs.primary;
          }),
          overlayColor: WidgetStateProperty.all(cs.primary.withOpacity(0.1)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
            buttonText(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: darkBackgroundColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: darkTextColor,
        displayColor: darkTextColor,
      ),
      iconTheme: const IconThemeData(size: 22),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: darkBackgroundColor,
        foregroundColor: darkTextColor,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackgroundColor,
        selectedItemColor: cs.primary,
        unselectedItemColor: darkSecondaryTextColor,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardTheme(
        color: darkBackgroundColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: cs.primary,
        textColor: darkTextColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintStyle: TextStyle(color: darkSecondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          elevation: WidgetStateProperty.all(2),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return cs.primary.withOpacity(0.90);
            }
            return cs.primary;
          }),
          overlayColor: WidgetStateProperty.all(cs.primary.withOpacity(0.1)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
            buttonText(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
