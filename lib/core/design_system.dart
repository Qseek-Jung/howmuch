import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Official Apple System Green (iOS 17)
  static const Color primary = Color(0xFF34C759); // Light Mode Primary
  static const Color primaryDark = Color(
    0xFF2E7D32,
  ); // Dark Mode Primary (Darker Green)

  // High Intensity Green for Numbers/Labels (More Contrast)
  static const Color textGreen = Color(0xFF248A3D);
  static const Color textGreenDark = Color(0xFF32D74B);

  // Soft Accents for backgrounds
  static const Color accentSoft = Color(0xFFE0F4E5);
  static const Color accentSoftDark = Color(0xFF1A3821);

  // Neutral Colors
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1C1C1E); // Apple Dark Surface
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color backgroundDark = Colors.black;

  // Semantic Colors
  static const Color accent = primary;
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);

  // Helper Methods
  static Color getPrimary(bool isDark) => isDark ? primaryDark : primary;
  static Color getTextGreen(bool isDark) => isDark ? textGreenDark : textGreen;
  static Color getAccentSoft(bool isDark) =>
      isDark ? accentSoftDark : accentSoft;

  // Gradients
  static LinearGradient primaryGradient(bool isDark) => LinearGradient(
    colors: isDark
        ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
        : [const Color(0xFF34C759), const Color(0xFF248A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppDesign {
  static const double buttonRadius = 28.0; // Pill shaped for 56h buttons
  static const double cardRadius = 16.0;
  static const double inputRadius = 12.0;

  static ButtonStyle primaryButtonStyle({bool isDark = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.getPrimary(isDark),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      elevation: 0,
    );
  }

  static BoxDecoration primaryGradientDecoration(bool isDark) => BoxDecoration(
    borderRadius: BorderRadius.circular(buttonRadius),
    gradient: AppColors.primaryGradient(isDark),
    boxShadow: [
      BoxShadow(
        color: AppColors.getPrimary(isDark).withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static TextStyle buttonTextStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static BoxDecoration selectionDecoration({
    required bool isSelected,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: isSelected
          ? AppColors.getPrimary(isDark).withValues(alpha: 0.12)
          : (isDark ? Colors.white10 : Colors.grey[100]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected
            ? AppColors.getPrimary(isDark).withValues(alpha: 0.3)
            : Colors.transparent,
        width: 1.5,
      ),
    );
  }

  static TextStyle selectionTextStyle({
    required bool isSelected,
    bool isDark = false,
  }) {
    return TextStyle(
      color: isSelected
          ? AppColors.getPrimary(isDark)
          : (isDark ? Colors.white70 : Colors.black87),
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      fontSize: 14,
    );
  }
}
