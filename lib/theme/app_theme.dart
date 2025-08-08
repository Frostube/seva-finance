import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration
class AppTheme {
  // Color palette definition

  static const primaryGreen = Color(0xFF4CAF50);    // Main brand color
  static const lightGreen = Color(0xFFB1EC6E);      // Used for backgrounds
  static const paleGreen = Color(0xFFB1EC6E);       // Lighter background color
  static const darkGreen = Color(0xFF154517);       // Used for text and buttons
  static const darkerGreen = Color(0xFF1B5E20);     // Used for pressed states
  static const backgroundColor = Color(0xFFFFFFFF); // White background
  static const textColor = Color(0xFF1A1A1A); // Nearly black text
  static const secondaryTextColor =
      Color(0xFF5A5A5A); // Gray text - Adjusted for better contrast

  // Dark theme colors
  static const darkPrimaryGreen = Color(0xFF66BB6A);
  static const darkLightGreen = Color(0xFF33691E);
  static const darkPaleGreen = Color(0xFF1B5E20);
  static const darkDarkGreen = Color(0xFF81C784);
  static const darkDarkerGreen = Color(0xFF4CAF50);
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
  static ThemeData theme(BuildContext context) => ThemeData(
        useMaterial3: true,
        primaryColor: primaryGreen,
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
        // Color scheme configuration
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: lightGreen,
          surface: backgroundColor,
          onPrimary: Colors.white,
          onSurface: textColor,
        ),
        // Text theme configuration
        textTheme: TextTheme(
          headlineLarge: headlineLarge(context),
          headlineMedium: headlineMedium(context),
          bodyLarge: bodyLarge(context),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: backgroundColor,
          selectedItemColor: darkGreen,
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
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          iconColor: darkGreen,
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
            borderSide: const BorderSide(color: darkGreen, width: 1),
          ),
        ),
        // Button theme configuration
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            // Full-width button
            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 56),
            ),
            // Rounded corners
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Subtle elevation
            elevation: WidgetStateProperty.all(2),
            // Background color with press state
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return darkerGreen;
              }
              return darkGreen;
            }),
            // Overlay color for ripple effect
            overlayColor: WidgetStateProperty.all(
              darkerGreen.withOpacity(0.1),
            ),
            // High-contrast text color
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

  static ThemeData darkTheme(BuildContext context) => ThemeData(
        useMaterial3: true,
        primaryColor: darkPrimaryGreen,
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
        colorScheme: const ColorScheme.dark(
          primary: darkPrimaryGreen,
          secondary: darkLightGreen,
          surface: darkBackgroundColor,
          onPrimary: darkTextColor,
          onSurface: darkTextColor,
        ),
        textTheme: TextTheme(
          headlineLarge: headlineLarge(context).copyWith(color: darkTextColor),
          headlineMedium:
              headlineMedium(context).copyWith(color: darkTextColor),
          bodyLarge: bodyLarge(context).copyWith(color: darkSecondaryTextColor),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: darkBackgroundColor,
          foregroundColor: darkTextColor,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkBackgroundColor,
          selectedItemColor: darkDarkGreen,
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
          iconColor: darkDarkGreen,
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
            borderSide: BorderSide(color: darkDarkGreen, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 56),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            elevation: WidgetStateProperty.all(2),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return darkDarkerGreen;
              }
              return darkDarkGreen;
            }),
            overlayColor: WidgetStateProperty.all(
              darkDarkerGreen.withOpacity(0.1),
            ),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            textStyle: WidgetStateProperty.all(buttonText(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
          ),
        ),
      );
}
