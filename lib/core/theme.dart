import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFFC05C3E); // Terracotta
  static const secondaryColor = Color(0xFF6A6661); // Muted gray-brown
  static const canvasColor = Color(0xFFFAF8F5); // Warm cream canvas
  static const dividerColor = Color(0xFFE5E2DD); // Warm soft divider

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        background: canvasColor,
        surface: Colors.white,
        surfaceVariant: const Color(0xFFF1EDE8),
      ),
      scaffoldBackgroundColor: canvasColor,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F0F0F)),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF0F0F0F)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF333333)),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent, // flat by default matching the screenshot
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F0F0F),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F0F0F)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: canvasColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(0xFFE88160),
        secondary: const Color(0xFFA5A09A),
        background: const Color(0xFF141312),
        surface: const Color(0xFF1D1B1A),
        surfaceVariant: const Color(0xFF272523),
      ),
      scaffoldBackgroundColor: const Color(0xFF141312),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFFE2DFDA)),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D2A28),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141312),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFE88160),
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF141312),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
