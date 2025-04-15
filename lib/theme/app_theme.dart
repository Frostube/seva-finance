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
  static const backgroundColor = Color(0xFFFFFFFF);  // White background
  static const textColor = Color(0xFF1A1A1A);       // Nearly black text
  static const secondaryTextColor = Color(0xFF757575); // Gray text

  // Typography styles
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // Main theme configuration
  static ThemeData get theme => ThemeData(
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: backgroundColor,
        // Color scheme configuration
        colorScheme: ColorScheme.light(
          primary: primaryGreen,
          secondary: lightGreen,
          surface: backgroundColor,
          background: backgroundColor,
          onPrimary: Colors.white,
        ),
        // Text theme configuration
        textTheme: TextTheme(
          headlineLarge: headlineLarge,
          headlineMedium: headlineMedium,
          bodyLarge: bodyLarge,
        ),
        // Button theme configuration
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            // Full-width button
            minimumSize: MaterialStateProperty.all(
              const Size(double.infinity, 56),
            ),
            // Rounded corners
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Subtle elevation
            elevation: MaterialStateProperty.all(2),
            // Background color with press state
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.pressed)) {
                return darkerGreen;
              }
              return darkGreen;
            }),
            // Overlay color for ripple effect
            overlayColor: MaterialStateProperty.all(
              darkerGreen.withOpacity(0.1),
            ),
            // Text color - now using darkerGreen to match "Spending" text
            foregroundColor: MaterialStateProperty.all(paleGreen),
            // Text style with matching color
            textStyle: MaterialStateProperty.all(buttonText.copyWith(
              color: paleGreen,
              fontWeight: FontWeight.w400,
            )),
          ),
        ),
      );
} 