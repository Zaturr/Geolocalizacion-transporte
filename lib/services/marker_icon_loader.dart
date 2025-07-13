// lib/services/marker_icon_loader.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui; // Alias 'dart:ui' to 'ui' for clarity

/// A utility class for loading and resizing custom marker icons from asset images.
///
/// This class provides a static method to efficiently convert an image asset
/// into a `BitmapDescriptor`, allowing for custom sizing.
class MarkerIconLoader {
  /// Loads an image asset, resizes it, and converts it into a `BitmapDescriptor`.
  ///
  /// This is useful for creating custom markers on a Google Map. The image
  /// is loaded from the asset bundle, decoded, resized to the target dimensions
  /// (based on a default size of 48x48 and the provided `scale`), and then
  /// converted into a `BitmapDescriptor` for use with `Maps_flutter`.
  ///
  /// [context] is required to access the `DefaultAssetBundle`.
  /// [assetPath] is the path to the image asset (e.g., 'assets/my_icon.png').
  /// [scale] is a multiplier for the default icon size (48x48). A `scale` of 1.0
  ///   means 48x48 pixels. A `scale` of 2.0 means 96x96 pixels.
  ///
  /// Returns a `Future<BitmapDescriptor>` that resolves with the loaded and
  /// resized icon.
  ///
  /// Throws an `Exception` if the image conversion to byte data fails.
  static Future<BitmapDescriptor> loadCustomMarkerIcon({
    required BuildContext context,
    required String assetPath,
    double scale = 1.0, // Default scale to maintain original size if not specified
  }) async {
    // Load the image data from the asset bundle.
    final data = await DefaultAssetBundle.of(context).load(assetPath);

    // Instantiate an image codec from the byte data.
    // The targetWidth and targetHeight are calculated based on a base size
    // (e.g., 48x48 pixels) multiplied by the provided scale.
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (48 * scale).round(), // Calculate target width
      targetHeight: (48 * scale).round(), // Calculate target height
    );

    // Get the next frame from the codec (for static images, there's usually only one).
    final frame = await codec.getNextFrame();

    // Convert the image frame to byte data in PNG format.
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    // Check if byte data was successfully obtained.
    if (byteData == null) {
      throw Exception("Failed to convert image '$assetPath' to byte data.");
    }

    // Return the BitmapDescriptor created from the byte data.
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
}