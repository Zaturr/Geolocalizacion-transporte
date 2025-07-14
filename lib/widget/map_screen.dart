// lib/widget/map_view_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:PathFinder/models/map_models.dart'; // Import your BusStop model

class MapViewWidget extends StatefulWidget {
  const MapViewWidget({Key? key}) : super(key: key);

  @override
  State<MapViewWidget> createState() => MapViewWidgetState();
}

class MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final LatLng _initialCameraPosition = const LatLng(10.4806, -66.9036); // Example: Caracas, Venezuela

  @override
  void initState() {
    super.initState();
    print("MapViewWidgetState: Initialized.");
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print("MapViewWidgetState: GoogleMapController created.");
  }

  void updatePolyline(List<LatLng> newPolylineCoordinates) {
    print("MapViewWidgetState: updatePolyline called with ${newPolylineCoordinates.length} points.");
    if (mounted) {
      setState(() {
        _polylines.clear();
        if (newPolylineCoordinates.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('selected_route'),
              points: newPolylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
          _fitPolylineToMap(newPolylineCoordinates);
          print("MapViewWidgetState: Polyline added to map.");
        } else {
          print("MapViewWidgetState: No polyline points to add.");
        }
      });
    }
  }

  void updateBusStops(List<BusStop> busStops) {
    print("MapViewWidgetState: updateBusStops called with ${busStops.length} bus stops.");
    if (mounted) {
      setState(() {
        _markers.clear(); // Clear existing markers
        if (busStops.isNotEmpty) {
          for (var stop in busStops) {
            _markers.add(
              Marker(
                markerId: MarkerId(stop.id),
                position: stop.coordinates,
                infoWindow: InfoWindow(title: stop.name),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Example icon
              ),
            );
            // Optional: print individual stop added
            // print("MapViewWidgetState: Added marker for stop: ${stop.name} at ${stop.coordinates}");
          }
          print("MapViewWidgetState: ${busStops.length} markers added to map.");
        } else {
          print("MapViewWidgetState: No bus stops to add as markers.");
        }
      });
    }
  }

  void _fitPolylineToMap(List<LatLng> polylineCoordinates) {
    if (_mapController == null || polylineCoordinates.isEmpty) {
      print("MapViewWidgetState: Cannot fit polyline, map controller null or polyline empty.");
      return;
    }

    LatLngBounds bounds;
    if (polylineCoordinates.length == 1) {
      bounds = LatLngBounds(
        southwest: polylineCoordinates.first,
        northeast: polylineCoordinates.first,
      );
      print("MapViewWidgetState: Fitting map to single point.");
    } else {
      double minLat = polylineCoordinates.first.latitude;
      double minLon = polylineCoordinates.first.longitude;
      double maxLat = polylineCoordinates.first.latitude;
      double maxLon = polylineCoordinates.first.longitude;

      for (var latLng in polylineCoordinates) {
        if (latLng.latitude < minLat) minLat = latLng.latitude;
        if (latLng.latitude > maxLat) maxLat = latLng.latitude;
        if (latLng.longitude < minLon) minLon = latLng.longitude;
        if (latLng.longitude > maxLon) maxLon = latLng.longitude;
      }
      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLon),
        northeast: LatLng(maxLat, maxLon),
      );
      print("MapViewWidgetState: Fitting map to polyline bounds.");
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50))
        .then((_) {
          print("MapViewWidgetState: Camera animated to new bounds.");
        }).catchError((e) {
          print("MapViewWidgetState: Error animating camera: $e");
        });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _initialCameraPosition,
        zoom: 12.0,
      ),
      polylines: _polylines,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}