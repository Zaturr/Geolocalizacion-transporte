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
      name: json['name'] as String, // Ensure this key matches your Supabase column name for route name
    );
  }
}

// Represents a bus stop with an ID, name, and geographical coordinates.
class BusStop {
  final String id;
  final String name;
  final LatLng coordinates;
  final int index; // Add the index property

  BusStop({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.index, // Initialize index
  });

  // Factory constructor to create a BusStop from a JSON map
  factory BusStop.fromJson(Map<String, dynamic> json) {
    // Assuming 'Coordenadas' from Supabase is a string like "latitude,longitude"
    final String coordinatesString = json['Coordenadas'] as String;
    final LatLng? parsedCoordinates = parseCoordinatesString(coordinatesString);

    if (parsedCoordinates == null) {
      throw FormatException('Invalid coordinates string: $coordinatesString');
    }

    return BusStop(
      id: json['id'] as String,
      name: json['Nombre_Parada'] as String, // Match your Supabase column name
      coordinates: parsedCoordinates,
      index: json['Index'] as int, // Match your Supabase column name for index
    );
  }

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

  // Method to convert BusStop to a JSON map (useful for sending data to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Nombre_Parada': name,
      'Coordenadas': '${coordinates.latitude},${coordinates.longitude}', // Convert LatLng back to string
      'Index': index,
    };
  }
}