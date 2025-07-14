import 'package:flutter/material.dart';

// 1. Centralize Core Colors/Palette (for better reusability and single source of truth)
// This abstract class acts as a namespace for your app's color palette.
abstract class AppColors {
  static const Color primaryBlue = Colors.blue;
  static const Color primaryLightBlue = Color(0xFF64B5F6); // A lighter shade of blue
  static const Color primaryDarkBlue = Color(0xFF1976D2);  // A darker shade of blue

  // You can add more specific colors if your design system uses them consistently
  static const Color appBackgroundLight = Colors.white;
  static const Color appBackgroundDark = Color(0xFF121212); // Dark background
  static const Color textLight = Colors.black87;
  static const Color textDark = Colors.white70;

  // Semantic colors, if applicable
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.amber;
}

// 2. Centralize Common Theme Constants (e.g., Material 3 usage)
// This abstract class holds properties that are consistent across all themes.
abstract class ThemeConstants {
  static const bool useMaterial3 = true;
  static const double defaultElevation = 2.0; // Example: for cards or app bars
  // Add other constants like default border radii, font sizes etc.
}

// 3. Helper Function to Create a Base ThemeData (improves reusability)
// This function takes a brightness and constructs a ThemeData object,
// applying common properties and the centralized seed color.
ThemeData _buildBaseTheme(Brightness brightness) {
  return ThemeData(
    // Use ColorScheme.fromSeed for Material 3 dynamic color generation
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue, // Use the centralized primary color
      brightness: brightness,
      // You can further customize colors for specific roles if needed
      // primary: AppColors.primaryBlue, // Explicitly set if not relying solely on seed
      // onPrimary: Colors.white,
      // surface: brightness == Brightness.light ? AppColors.appBackgroundLight : AppColors.appBackgroundDark,
      // onSurface: brightness == Brightness.light ? AppColors.textLight : AppColors.textDark,
      // error: AppColors.errorColor,
    ),
    useMaterial3: ThemeConstants.useMaterial3, // Use the centralized constant

    // Common properties applied to both themes:
    // Scaffold background color
    scaffoldBackgroundColor: brightness == Brightness.light
        ? AppColors.appBackgroundLight
        : AppColors.appBackgroundDark,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.light
          ? AppColors.primaryBlue
          : AppColors.primaryDarkBlue, // Different app bar color for dark theme
      foregroundColor: Colors.white, // Text/icons on app bar
      elevation: ThemeConstants.defaultElevation,
      centerTitle: true,
    ),

    // Floating Action Button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brightness == Brightness.light
          ? AppColors.primaryBlue
          : AppColors.primaryLightBlue, // Can be different per theme
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Card theme example
    cardTheme: CardTheme(
      elevation: ThemeConstants.defaultElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: brightness == Brightness.light ? Colors.white : Colors.grey[850],
    ),

    // Button themes (example for ElevatedButton)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Define Text Themes (important for consistent typography)
    // You can base this on a default TextTheme and then modify specific styles.
    textTheme: (brightness == Brightness.light
            ? ThemeData.light().textTheme
            : ThemeData.dark().textTheme)
        .apply(
      bodyColor: brightness == Brightness.light ? AppColors.textLight : AppColors.textDark,
      displayColor: brightness == Brightness.light ? AppColors.textLight : AppColors.textDark,
    ).copyWith(
      // Example: Customize headlineSmall for a specific font size or weight
      headlineSmall: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      // bodyMedium: TextStyle(fontSize: 14.0), // Example: customize body text
    ),

    // Input Decoration Theme (for form fields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? Colors.grey[200] : Colors.grey[700],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: brightness == Brightness.light ? TextStyle(color: Colors.grey[600]) : TextStyle(color: Colors.grey[400]),
    ),

    // Other component themes can be added here (e.g., dialogTheme, bottomSheetTheme, etc.)
  );
}

// 4. Expose the final ThemeData instances
final lightTheme = _buildBaseTheme(Brightness.light);
final darkTheme = _buildBaseTheme(Brightness.dark);

// Optional: If you want to provide easy access to theme-specific elements
// without constantly calling `Theme.of(context).colorScheme.primary`, you
// could create helper methods or extensions on BuildContext.
// For instance:
// extension CustomThemeColors on BuildContext {
//   ColorScheme get colorScheme => Theme.of(this).colorScheme;
//   Color get primaryColor => colorScheme.primary;
//   Color get onPrimaryColor => colorScheme.onPrimary;
//   // ... and so on for other colors or text styles
// }