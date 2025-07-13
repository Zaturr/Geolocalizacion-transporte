// lib/models/map_models.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Represents a geographical route with an ID and a name.
class Route {
  final String id;
  final String name;

  Route({required this.id, required this.name});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

// Represents a bus stop with an ID, name, and geographical coordinates.
class BusStop {
  final String id;
  final String name;
  final LatLng coordinates;

  BusStop({required this.id, required this.name, required this.coordinates});

  // Helper to parse "latitude,longitude" string into LatLng
  static LatLng? parseCoordinatesString(String coordString) {
    try {
      final parts = coordString.split(',');
      if (parts.length == 2) {
        final double latitude = double.parse(parts[0].trim());
        final double longitude = double.parse(parts[1].trim());
        return LatLng(latitude, longitude);
      }
    } catch (e) {
      // Print an error for debugging if parsing fails
      print('Error parsing coordinates string "$coordString": $e');
    }
    return null;
  }
}