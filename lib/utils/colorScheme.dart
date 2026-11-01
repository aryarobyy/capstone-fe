// ignore_for_file: file_names

import 'package:flutter/material.dart';

/// Centralized Color Palette extracted from UI Design Specification Guidelines (authGuide.md).
/// 
/// This file acts as the single source of truth for color tokens across the TaniPintar application,
/// ensuring design consistency, maintainability, and reusability.
class AppColors {
  AppColors._();

  // ==========================================
  // 1. BRAND & PRIMARY COLORS
  // ==========================================

  /// Primary / Brand Color: #1B5E20 (Dark Forest Green)
  /// Used for: Header title, primary buttons, back navigation text,
  /// action links ("Masuk di sini" / "Daftar di sini"), and leaf icons.
  static const Color primary = Color(0xFF1B5E20);

  /// Primary Light / Background Circle: #E8F5E9 (Light Mint Green)
  /// Used for: Logo badge circle background container.
  static const Color primaryLight = Color(0xFFE8F5E9);

  /// Primary Dark: #0D3310 (Deep Forest Green)
  /// Used for: Button pressed states, dark accents, and active focus shadows.
  static const Color primaryDark = Color(0xFF0D3310);

  // ==========================================
  // 2. BACKGROUND & CANVAS COLORS
  // ==========================================

  /// Background Canvas: #F8F9FA (Off-White / Very Light Gray)
  /// Used for: Scaffold and screen body background.
  static const Color backgroundCanvas = Color(0xFFF8F9FA);

  /// Card Background: #FFFFFF (Pure White)
  /// Used for: Form card container, dialogs, sheets, and elevated surfaces.
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Input Background: #FAFAFA (Light Gray Neutral)
  /// Used for: Fill color of text input fields.
  static const Color inputBackground = Color(0xFFFAFAFA);

  // ==========================================
  // 3. BORDER & DIVIDER COLORS
  // ==========================================

  /// Border Color: #E0E0E0 (Light Gray Border)
  /// Used for: Outermost border of text input fields and divider lines.
  static const Color border = Color(0xFFE0E0E0);

  /// Focused Border Color: #1B5E20 (Primary Green)
  /// Used for: Active/focused text field border.
  static const Color borderFocused = Color(0xFF1B5E20);

  // ==========================================
  // 4. TYPOGRAPHY & TEXT COLORS
  // ==========================================

  /// Text Primary: #212121 (Dark Gray / Almost Black)
  /// Used for: Input labels, headings, and high-emphasis body text.
  static const Color textPrimary = Color(0xFF212121);

  /// Text Secondary: #616161 (Medium Gray)
  /// Used for: Subtitle description, helper notes, and "Sudah punya akun?" text.
  static const Color textSecondary = Color(0xFF616161);

  /// Text Hint / Placeholder: #9E9E9E (Muted Gray)
  /// Used for: Placeholder hint text inside inputs and disabled elements.
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text On Primary: #FFFFFF (White)
  /// Used for: Text and icons inside primary filled buttons.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ==========================================
  // 5. STATUS & FEEDBACK COLORS
  // ==========================================

  /// Error Color: #D32F2F (Material Red 700)
  /// Used for: Validation error messages and error input borders.
  static const Color error = Color(0xFFD32F2F);

  /// Success Color: #2E7D32 (Material Green 800)
  /// Used for: Positive feedback snackbars, badges, and validation checkmarks.
  static const Color success = Color(0xFF2E7D32);

  /// Warning Color: #F57C00 (Material Orange 700)
  /// Used for: Warnings and non-blocking alerts.
  static const Color warning = Color(0xFFF57C00);

  /// Info Color: #0288D1 (Material Light Blue 700)
  /// Used for: Informational badges and banners.
  static const Color info = Color(0xFF0288D1);

  // ==========================================
  // 6. DASHBOARD & AREA SPECIFIC TOKENS
  // ==========================================
  
  /// Accent Green / FAB Color: #34A853 (Vibrant Leaf Green)
  static const Color accentGreen = Color(0xFF34A853);
  
  /// Area Screen Accent Green: #3B9E59
  static const Color areaAccent = Color(0xFF3B9E59);
  
  /// Danger Badge (Bahaya): #FF3B30
  static const Color badgeDanger = Color(0xFFFF3B30);
  
  /// Warning Badge (Waspada): #FFE600
  static const Color badgeWarning = Color(0xFFFFE600);
  
  /// Bottom Navigation Background: #3B9E59 (Matches "Tambah Area" button / areaAccent)
  static const Color bottomNavBg = areaAccent;
  
  /// Bottom Navigation Unselected: Soft White (75% Opacity)
  static const Color navUnselected = Color(0xBFFFFFFF);
  
  /// Bottom Navigation Default Selected: Pure White
  static const Color navSelected = Color(0xFFFFFFFF);

  // ==========================================
  // 7. SENSOR ACTION TOKENS
  // ==========================================
  
  /// Action Edit Button: #FFE600
  static const Color actionEdit = Color(0xFFFFE600);

  /// Action Delete Button: #FF2D55
  static const Color actionDelete = Color(0xFFFF2D55);
}

/// Material ColorScheme abstraction configured with TaniPintar design tokens.
class AppColorScheme {
  AppColorScheme._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primary,
    onSecondary: AppColors.textOnPrimary,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.cardBackground,
    onSurface: AppColors.textPrimary,
  );
}

/// Global Application Theme based on the design specification.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.light,
      scaffoldBackgroundColor: AppColors.backgroundCanvas,
      canvasColor: AppColors.backgroundCanvas,
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.border,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Text input theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 1.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
