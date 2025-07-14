// lib/widget/map_view_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:PathFinder/models/map_models.dart'; // Import your BusStop model

class MapViewWidget extends StatefulWidget {
  // NEW: Optional parameter to receive polylines from MapsRoutes
  final Set<Polyline>? polylinesFromRoutes;

  const MapViewWidget({
    Key? key,
    this.polylinesFromRoutes, // NEW: Add this to the constructor
  }) : super(key: key);

  @override
  State<MapViewWidget> createState() => MapViewWidgetState();
}

class MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  // MODIFIED: _polylines can be managed internally or updated externally
  Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final LatLng _initialCameraPosition = const LatLng(10.4806, -66.9036); // Example: Caracas, Venezuela

  @override
  void initState() {
    super.initState();
    print("MapViewWidgetState: Initialized.");
    // If initial polylines are provided, use them
    if (widget.polylinesFromRoutes != null) {
      _polylines = Set.from(widget.polylinesFromRoutes!);
    }
  }

  // NEW: Method to update polylines specifically from MapsRoutes
  void setMapsRoutesPolylines(Set<Polyline> newPolylines) {
    print("MapViewWidgetState: setMapsRoutesPolylines called with ${newPolylines.length} polylines.");
    if (mounted) {
      setState(() {
        _polylines = Set.from(newPolylines); // Directly use the set from MapsRoutes
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print("MapViewWidgetState: GoogleMapController created.");
  }

  // Keep updatePolyline if you still want to allow manual polyline updates
  // However, with Maps_routes, this might become less used for actual routes.
  // It could still be useful for other line drawings.
  void updatePolyline(List<LatLng> newPolylineCoordinates) {
    print("MapViewWidgetState: updatePolyline called with ${newPolylineCoordinates.length} points.");
    if (mounted) {
      setState(() {
        // Only clear if we are not managing polylines via setMapsRoutesPolylines
        // For now, it's safer to clear here if this method is used for distinct polylines.
        // If this method is now solely for other, non-route polylines, adjust logic.
        _polylines.clear(); // This will clear routes drawn by Maps_routes too!
                             // Consider if you want this or if setMapsRoutesPolylines should be the primary.
        if (newPolylineCoordinates.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('manual_route_polyline'), // Change ID to differentiate
              points: newPolylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
          _fitPolylineToMap(newPolylineCoordinates);
          print("MapViewWidgetState: Manual polyline added to map.");
        } else {
          print("MapViewWidgetState: No manual polyline points to add.");
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
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            );
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

    // This method is primarily for fitting to your own polyline data.
    // Maps_routes might adjust the camera on its own,
    // or you might need a more sophisticated fit that considers both polyline and markers.
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
      polylines: _polylines, // Use the internally managed _polylines
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}