
import 'package:flutter/material.dart'hide Route;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteCreationMapWidget extends StatefulWidget {
  // Callback para cuando la cámara del mapa se detiene, devolviendo la posición central.
  final ValueChanged<LatLng> onCameraIdle;
  // Posición inicial de la cámara del mapa.
  final LatLng initialCameraPosition;
  // Marcadores adicionales a mostrar en el mapa (paradas ya agregadas).
  final Set<Marker> additionalMarkers;

  const RouteCreationMapWidget({
    Key? key,
    required this.onCameraIdle,
    required this.initialCameraPosition,
    this.additionalMarkers = const {},
  }) : super(key: key);

  @override
  State<RouteCreationMapWidget> createState() => _RouteCreationMapWidgetState();
}

class _RouteCreationMapWidgetState extends State<RouteCreationMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _currentMapCenter; // Para almacenar la posición central del mapa
  final Set<Marker> _currentMarkers = {}; // Marcadores que se mostrarán en el mapa

  @override
  void initState() {
    super.initState();
    _currentMapCenter = widget.initialCameraPosition;
    _updateCentralMarker(_currentMapCenter!);
  }

  @override
  void didUpdateWidget(covariant RouteCreationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualiza los marcadores adicionales si cambian
    if (widget.additionalMarkers != oldWidget.additionalMarkers) {
      _updateCentralMarker(_currentMapCenter!); // Asegura que el marcador central se mantenga
    }
  }

  // Actualiza la posición del marcador central
  void _updateCentralMarker(LatLng position) {
    setState(() {
      _currentMarkers.clear();
      _currentMarkers.add(
        Marker(
          markerId: const MarkerId('centralMarker'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Marcador azul para la selección
          infoWindow: const InfoWindow(title: 'Arrastra el mapa para moverme'),
          draggable: false, // El marcador no es arrastrable directamente, el mapa se arrastra
        ),
      );
      // Añade los marcadores adicionales proporcionados por el widget padre
      _currentMarkers.addAll(widget.additionalMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: widget.initialCameraPosition,
        zoom: 13.0,
      ),
      markers: _currentMarkers, // Muestra el marcador central y los adicionales
      myLocationButtonEnabled: false, // Deshabilita el botón de ubicación por defecto
      zoomControlsEnabled: false, // Deshabilita los controles de zoom por defecto
      onCameraMove: (position) {
        // Actualiza la posición del marcador central mientras el mapa se mueve
        setState(() {
          _currentMapCenter = position.target;
          _updateCentralMarker(_currentMapCenter!);
        });
      },
      onCameraIdle: () {
        // Cuando la cámara se detiene, notifica al widget padre la posición final del marcador
        if (_currentMapCenter != null) {
          widget.onCameraIdle(_currentMapCenter!);
        }
      },
    );
  }
}
