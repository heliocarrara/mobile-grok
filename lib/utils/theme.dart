import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais - Paleta moderna e harmoniosa
  static const Color primaryColor = Color(0xFF6366F1); // Indigo moderno
  static const Color primaryLightColor = Color(0xFF818CF8);
  static const Color primaryDarkColor = Color(0xFF4F46E5);
  
  static const Color secondaryColor = Color(0xFFEC4899); // Pink moderno
  static const Color secondaryLightColor = Color(0xFFF472B6);
  static const Color secondaryDarkColor = Color(0xFFDB2777);
  
  // Cores de fundo - Gradientes suaves
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Cores de texto - Hierarquia clara
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textLightColor = Color(0xFF9CA3AF);
  
  // Cores de status - Mais suaves e modernas
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue
  
  // Cores de categoria - Paleta harmoniosa
  static const Map<String, Color> categoriaColors = {
    'faculdade': Color(0xFF8B5CF6), // Violet
    'casa': Color(0xFFF97316), // Orange
    'lazer': Color(0xFF06B6D4), // Cyan
    'alimentacao': Color(0xFFEF4444), // Red
    'financas': Color(0xFFEAB308), // Yellow
    'trabalho': Color(0xFF64748B), // Slate
    'saude': Color(0xFF10B981), // Emerald
    'outros': Color(0xFF94A3B8), // Slate light
  };

  // Gradientes modernos
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successColor, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningColor, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        background: backgroundColor,
        surface: surfaceColor,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surfaceTint: primaryColor.withOpacity(0.05),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(
          color: textLightColor,
          fontSize: 16,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimaryColor,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondaryColor,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textLightColor,
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryColor,
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Tema escuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        background: const Color(0xFF0F0F23),
        surface: const Color(0xFF1A1A2E),
        onBackground: Colors.white,
        onSurface: Colors.white,
        primary: primaryLightColor,
        secondary: secondaryLightColor,
        error: errorColor,
        surfaceTint: primaryLightColor.withOpacity(0.1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF16213E),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLightColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLightColor,
          side: const BorderSide(color: primaryLightColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLightColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD1D5DB),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF9CA3AF),
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD1D5DB),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F23),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A3E),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF16213E),
        selectedColor: primaryColor,
        disabledColor: const Color(0xFF2A2A3E),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
