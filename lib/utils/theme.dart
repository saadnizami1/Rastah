import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Notion-inspired Color Palette
  static const Color primaryColor = Color(0xFF2F3437);
  static const Color secondaryColor = Color(0xFF37352F);
  static const Color accentColor = Color(0xFF0F62FE);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF7F6F3);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2F3437);
  static const Color textSecondary = Color(0xFF787774);
  static const Color textTertiary = Color(0xFF9B9A97);
  static const Color borderColor = Color(0xFFE9E9E7);
  static const Color successColor = Color(0xFF0F7B0F);
  static const Color warningColor = Color(0xFFB54308);
  static const Color errorColor = Color(0xFFE5484D);

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: MaterialColor(0xFF2F3437, {
        50: Color(0xFFF7F6F3),
        100: Color(0xFFE9E9E7),
        200: Color(0xFFD3D2CE),
        300: Color(0xFFB8B6B0),
        400: Color(0xFF9B9A97),
        500: Color(0xFF787774),
        600: Color(0xFF5E5D5A),
        700: Color(0xFF37352F),
        800: Color(0xFF2F3437),
        900: Color(0xFF1C1B18),
      }),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Card Theme
    
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textTertiary,
        ),
      ),
    );
  }
  
  // Urdu Text Styles
  static TextStyle urduHeading = GoogleFonts.notoNaskhArabic(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  
  static TextStyle urduBody = GoogleFonts.notoNaskhArabic(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle urduSubtle = GoogleFonts.notoNaskhArabic(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
}