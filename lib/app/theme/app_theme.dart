import 'package:flutter/material.dart';

/// App-wide theme configuration with WhatsApp-style colors and styling
class AppTheme {
  // WhatsApp brand colors
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDarkGreen = Color(0xFF075E54);
  static const Color whatsappTeal = Color(0xFF128C7E);
  static const Color whatsappLightGreen = Color(0xFFDCF8C6);
  static const Color whatsappBlue = Color(0xFF34B7F1);

  // Message bubble colors
  static const Color outgoingMessageColor = whatsappLightGreen;
  static const Color incomingMessageColor = Colors.white;

  // Status colors
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color typingColor = whatsappTeal;
  static const Color lastSeenColor = Colors.grey;

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Primary color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: whatsappGreen,
        brightness: Brightness.light,
        primary: whatsappGreen,
        secondary: whatsappTeal,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 1,
        backgroundColor: whatsappDarkGreen,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: whatsappGreen,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: whatsappGreen,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Card theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Colors.white,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: whatsappGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: whatsappGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: whatsappGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: whatsappGreen,
          side: const BorderSide(color: whatsappGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Snack bar theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: whatsappDarkGreen,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 8,
      ),

      // Text themes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 0.5,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.black54,
        size: 24,
      ),

      // Primary icon theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Primary color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: whatsappGreen,
        brightness: Brightness.dark,
        primary: whatsappGreen,
        secondary: whatsappTeal,
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 1,
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: whatsappGreen,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: whatsappGreen,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Card theme
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Color(0xFF1E1E1E),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: whatsappGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: whatsappGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: whatsappGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Snack bar theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: whatsappDarkGreen,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      // Text themes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[700],
        thickness: 0.5,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.white70,
        size: 24,
      ),
    );
  }

  /// Custom message bubble styles
  static BoxDecoration outgoingMessageDecoration = const BoxDecoration(
    color: outgoingMessageColor,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(4),
    ),
  );

  static BoxDecoration incomingMessageDecoration = BoxDecoration(
    color: incomingMessageColor,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(18),
    ),
    border: Border.all(color: Colors.grey[300]!, width: 0.5),
  );

  /// Status indicator styles
  static const TextStyle onlineTextStyle = TextStyle(
    color: onlineColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle typingTextStyle = TextStyle(
    color: typingColor,
    fontSize: 12,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle lastSeenTextStyle = TextStyle(
    color: lastSeenColor,
    fontSize: 12,
  );
}