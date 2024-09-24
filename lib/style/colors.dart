import 'package:flutter/material.dart';

class AppColors {
  // Snackbar Message Colors
  static const Color success = Color(0xFF00C853); // Green for success messages
  static const Color error = Color(0xFFD32F2F);   // Red for error messages
  static const Color info = Color(0xFF2196F3);    // Blue for informational messages
  static const Color warning = Color(0xFFFFC107); // Yellow for warning messages

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);  // White for primary text
  static const Color textSecondary = Color(0xFFB3B3B3); // Light Gray for secondary text
  static const Color textHighlight = Color(0xFFE50914); // Netflix Red for highlights or emphasis

  // Button Colors
  static const Color buttonPrimary = Color(0xFFE50914);  // Netflix Red for primary buttons
  static const Color buttonSecondary = Color(0xFF333333); // Slate Gray for secondary buttons
  static const Color buttonDisabled = Color(0xFF757575);  // Dark Gray for disabled buttons

  // Background Colors
  static const Color backgroundPrimary = Color(0xFF000000); // Rich Black for primary background
  static const Color backgroundSecondary = Color(0xFF121212); // Dark Charcoal for secondary background
  static const Color backgroundOverlay = Color(0x88000000);  // Semi-transparent black for overlays

  // Divider or Border Colors
  static const Color dividerColor = Color(0xFF808080);  // Slate Gray for dividers or borders

  // Additional Colors
  static const Color cardBackground = Color(0xFF1E1E1E); // Dark gray for card backgrounds
  static const Color iconColor = Color(0xFFFFFFFF); // White for icons

  // Method to generate colors dynamically if needed
  static Color getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", ""); // Remove the hash symbol if present
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Add alpha channel if not provided
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
