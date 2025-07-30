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
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: backgroundColor,
        // Color scheme configuration
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: lightGreen,
          surface: backgroundColor,
          onPrimary: Colors.white,
        ),
        // Text theme configuration
        textTheme: TextTheme(
          headlineLarge: headlineLarge(context),
          headlineMedium: headlineMedium(context),
          bodyLarge: bodyLarge(context),
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
            // Text color - now using darkerGreen to match "Spending" text
            foregroundColor: WidgetStateProperty.all(paleGreen),
            // Text style with matching color
            textStyle: WidgetStateProperty.all(buttonText(context).copyWith(
              color: paleGreen,
              fontWeight: FontWeight.w400,
            )),
          ),
        ),
      );

  static ThemeData darkTheme(BuildContext context) => ThemeData(
        primaryColor: darkPrimaryGreen,
        scaffoldBackgroundColor: darkBackgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: darkPrimaryGreen,
          secondary: darkLightGreen,
          surface: darkBackgroundColor,
          onPrimary: darkTextColor,
        ),
        textTheme: TextTheme(
          headlineLarge: headlineLarge(context).copyWith(color: darkTextColor),
          headlineMedium:
              headlineMedium(context).copyWith(color: darkTextColor),
          bodyLarge: bodyLarge(context).copyWith(color: darkSecondaryTextColor),
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
            foregroundColor: WidgetStateProperty.all(darkPaleGreen),
            textStyle: WidgetStateProperty.all(buttonText(context).copyWith(
              color: darkPaleGreen,
              fontWeight: FontWeight.w400,
            )),
          ),
        ),
      );
}
