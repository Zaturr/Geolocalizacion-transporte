// lib/services/map_data_service.dart
// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:PathFinder/models/map_models.dart';

/// A service class responsible for fetching map-related data from Supabase.
class MapDataService {
  final SupabaseClient _supabase;
  final String _busStopsTable = 'paradas';
  final String _routesTable = 'routes';

  MapDataService(this._supabase);

  Future<List<BusStop>> fetchBusStops() async {
    try {
      print("MapDataService: Fetching all bus stops from '$_busStopsTable'...");
      final List<dynamic> response = await _supabase
          .from(_busStopsTable)
          .select('id, "Nombre_Parada", "Coordenadas"')
          .order('id', ascending: true);
      print("MapDataService: Fetched ${response.length} all bus stops raw records.");

      return response.map((stop) {
        final String id = stop['id'] as String;
        final String name = stop['Nombre_Parada'] as String;
        final String coordinatesRaw = stop['Coordenadas'] as String;
        final LatLng? coordinates = BusStop.parseCoordinatesString(coordinatesRaw);

        if (coordinates == null) {
          print('MapDataService: Error parsing coordinates for bus stop ID: $id. Raw: $coordinatesRaw');
          throw Exception("Invalid coordinates format for bus stop ID: $id. Raw: $coordinatesRaw");
        }
        return BusStop(id: id, name: name, coordinates: coordinates);
      }).toList();
    } catch (e) {
      print('MapDataService: Error fetching all bus stops from Supabase: $e');
      rethrow;
    }
  }

  Future<List<Route>> fetchRoutes() async {
    try {
      print("MapDataService: Fetching routes metadata from '$_routesTable'...");
      final List<dynamic> response = await _supabase
          .from(_routesTable)
          .select('id, name')
          .order('id', ascending: true);
      print("MapDataService: Fetched ${response.length} routes metadata raw records.");

      return response.map((routeData) => Route.fromJson(routeData)).toList();
    } catch (e) {
      print('MapDataService: Error fetching routes metadata from Supabase: $e');
      rethrow;
    }
  }

  Future<List<LatLng>> fetchPolylineForRoute(String routeId) async {
    try {
      print("MapDataService: Fetching polyline raw data for route ID: $routeId from '$_busStopsTable' (column 'Ruta')...");
      final List<dynamic> response = await _supabase
          .from(_busStopsTable)
          .select('Coordenadas')
          .eq('Ruta', routeId) // <--- CRITICAL: Using 'Ruta' (uppercase R)
          .order('id', ascending: true);
      print("MapDataService: Fetched ${response.length} raw polyline coordinates records for route ID: $routeId.");

      final List<LatLng> polylinePoints = [];
      for (var stopData in response) {
        final String coordinatesRaw = stopData['Coordenadas'] as String;
        final LatLng? coordinates = BusStop.parseCoordinatesString(coordinatesRaw);
        if (coordinates != null) {
          polylinePoints.add(coordinates);
        } else {
          print('MapDataService: Warning: Skipping invalid coordinates for polyline point in route $routeId. Raw: $coordinatesRaw');
        }
      }
      print("MapDataService: Parsed ${polylinePoints.length} LatLng points for polyline for route ID: $routeId.");
      return polylinePoints;
    } catch (e) {
      print('MapDataService: Error fetching polyline for route $routeId from Supabase: $e');
      rethrow;
    }
  }

  Future<List<BusStop>> fetchBusStopsForRoute(String routeId) async {
    try {
      print("MapDataService: Fetching bus stops raw data for route ID: $routeId from '$_busStopsTable' (column 'Ruta')...");
      final List<dynamic> response = await _supabase
          .from(_busStopsTable)
          .select('id, "Nombre_Parada", "Coordenadas"')
          .eq('Ruta', routeId) // <--- CRITICAL: Using 'Ruta' (uppercase R)
          .order('id', ascending: true);
      print("MapDataService: Fetched ${response.length} raw bus stops records for route ID: $routeId.");

      return response.map((stop) {
        final String id = stop['id'] as String;
        final String name = stop['Nombre_Parada'] as String;
        final String coordinatesRaw = stop['Coordenadas'] as String;
        final LatLng? coordinates = BusStop.parseCoordinatesString(coordinatesRaw);

        if (coordinates == null) {
          print('MapDataService: Warning: Skipping invalid coordinates for bus stop ID: $id in route $routeId. Raw: $coordinatesRaw');
          return null;
        }
        return BusStop(id: id, name: name, coordinates: coordinates);
      }).whereType<BusStop>().toList();

    } catch (e) {
      print('MapDataService: Error fetching bus stops for route $routeId from Supabase: $e');
      rethrow;
    }
  }
}