import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (from OrderFlow)
  static const Color primary = Color(0xFF17CF91); // Green
  static const Color primaryDark = Color(0xFF12A877); // Darker green
  static const Color primaryLight = Color(0xFF8FE8C6); // Lighter green

  // Background Colors (from OrderFlow)
  static const Color backgroundLight = Color(0xFFF6F8F7); // Light background
  static const Color backgroundDark = Color(0xFF11211C); // Dark background

  static const Color darkBorder = Color(0xFF346555);
  static const Color darkInputBackground = Color(0xFF1A322A);
  static const Color darkPlaceholder = Color(0xFF93C8B6);


  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // Gray Scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);

  // Semantic Colors
  static const Color success = Color(0xFF17CF91); // Same as primary
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Surface Colors - Light Theme
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Surface Colors - Dark Theme
  static const Color surfaceDark = Color(0xFF1A2A25); // Slightly lighter than background
  static const Color cardDark = Color(0xFF22332D);

  // Text Colors - Light Theme
  static const Color textPrimaryLight = Color(0xFF11211C); // Using dark background as text
  static const Color textSecondaryLight = Color(0xFF525252);
  static const Color textDisabledLight = Color(0xFFA3A3A3);

  // Text Colors - Dark Theme
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color textDisabledDark = Color(0xFF737373);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color borderDark = Color(0xFF2D3D37);

  // Overlay Colors
  static const Color overlayLight = Color(0x0D000000);
  static const Color overlayDark = Color(0x1AFFFFFF);

  // Specific colors from OrderFlow design
  static const Color logoBackground = Color(0x3317CF91); // primary/20
  static const Color progressBarBackground = Color(0x33FFFFFF); // white/20
}