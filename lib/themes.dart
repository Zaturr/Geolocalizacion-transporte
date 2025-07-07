import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Primary color for the light theme
    brightness: Brightness.light,
  ),
  useMaterial3: true, // Ensure Material 3 is enabled
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Primary color for the dark theme
    brightness: Brightness.dark,
  ),
  useMaterial3: true, // Ensure Material 3 is enabled
);