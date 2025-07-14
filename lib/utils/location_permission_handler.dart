// lib/utils/location_permission_handler.dart
// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart'; // For Android-specific settings launch
import 'dart:io' show Platform; // Used to check the operating system

/// A utility class for handling location permissions and service status.
///
/// This class provides static methods to check, request, and guide the user
/// through enabling necessary location functionalities for the application.
class LocationPermissionHandler {
  /// Checks and requests location permissions, and verifies if location services are enabled.
  ///
  /// This method performs a sequential check:
  /// 1. It first checks the current status of location permissions. If not granted,
  ///    it requests them from the user. If the user denies, it shows a dialog
  ///    guiding them to app settings.
  /// 2. If permissions are granted, it then checks if the device's location
  ///    services (GPS, Wi-Fi, etc.) are enabled. If not, it shows a dialog
  ///    to prompt the user to enable them.
  ///
  /// [context] is required to display dialogs to the user.
  ///
  /// Returns a `Future<bool>`:
  /// - `true` if location permission is granted AND location service is enabled.
  /// - `false` otherwise (permission denied, service disabled, or error).
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // 1. Check and Request Location Permission
    var permissionStatus = await Permission.location.status;

    if (!permissionStatus.isGranted) {
      // Permission not granted, request it
      final result = await Permission.location.request();
      if (!result.isGranted) {
        // User denied permission, show a dialog to guide them to settings
        await _showPermissionDeniedDialog(context);
        return false; // Permission not granted
      }
    }

    // 2. Check if Location Services are Enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      // Location service is disabled on the device, show a dialog
      await _showLocationServiceDisabledDialog(context);
      return false; // Location service disabled
    }

    // All checks passed: permission granted and service enabled.
    return true;
  }

  /// Displays an [AlertDialog] informing the user that location permission is required.
  ///
  /// Provides options to cancel or open the application settings.
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso de Ubicación Requerido'),
        content: const Text(
            'Esta aplicación necesita permiso de ubicación para funcionar correctamente. Por favor, habilítalo en la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close the dialog
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog first
              openAppSettings(); // Open the app's settings screen
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Displays an [AlertDialog] informing the user that location services are disabled.
  ///
  /// Provides options to cancel or open the device's location settings (Android)
  /// or app settings (iOS fallback, as direct location settings aren't exposed).
  static Future<void> _showLocationServiceDisabledDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servicio de Ubicación Desactivado'),
        content: const Text(
            'Por favor, habilita los servicios de ubicación para usar esta función.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close the dialog
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog first
              if (Platform.isAndroid) {
                // On Android, directly open location source settings
                const AndroidIntent intent = AndroidIntent(
                  action: 'android.settings.LOCATION_SOURCE_SETTINGS',
                );
                intent.launch();
              } else if (Platform.isIOS) {
                // On iOS, direct access to location services settings is not common.
                // Usually, users manage this from Control Center or the app's settings.
                // Opening app settings is a common fallback.
                openAppSettings();
                print('Please enable location services from iOS Control Center or Settings > Privacy & Security > Location Services.');
              }
            },
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );
  }
}