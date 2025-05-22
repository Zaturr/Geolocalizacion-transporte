import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // Requerido por StreamSubscription
import 'package:android_intent_plus/android_intent.dart'; // Requerido por Android-specific settings opening


class MapScreen extends StatefulWidget {

  // Constructor simplificado(ya notoma initialPosition, locationName)
  const MapScreen({
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition; // Guarda la ubicacion del usuario
  final Set<Marker> _markers = {}; // guarda marcadores de mapa
  BitmapDescriptor _currentLocationIcon = BitmapDescriptor.defaultMarker; // Icono de posicion para el usuario
  LatLng? _initialCameraPosition; // Posicion inicial de camara
  StreamSubscription<Position>? _positionSubscription; // Subscripcion a las actualizaciones de lugar
  bool _isLoading = true; // Indicador para mostrar cuando se esta haciendo Fetching

  @override
  void initState() {
    super.initState();
    _initializeMap(); // Inicializa los componentes de mapa y locacion
  }

  @override
  void dispose() {
    _positionSubscription?.cancel(); //Cancela las actualizaciones de locacion cuando el widget muere
    _mapController.dispose(); // Se deshace del controlador de mapas
    super.dispose();
  }

  //Inicializa el mapa, checkea permisos y carga el icono de localizacion
  Future<void> _initializeMap() async {
    await _checkLocationPermission(); // Check de permisos de locacion
    await _loadCustomMarkerIcon(); // Carga el icono de locacion del usuario
  }

  /// Carga el icono de locacion del usuario
  Future<void> _loadCustomMarkerIcon() async {
    _currentLocationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/user_location_icon.png', // Path al icono de localizacion
    );
  }

  /// Checkea y pide los permisos de locacion
  /// If permissions are granted and location services are enabled, it starts location updates.
  /// si los permisos han sido garantizados y los servicios han sido habilitados, comienza las actualizaciones de locacion
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        if (mounted) {
          await _showPermissionDeniedDialog(); // Muestra un dialogo si el permiso ha sido negado
        }
        setState(() { _isLoading = false; }); // deja de cargar si los permisos no han sido concedidos
        return;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        await _showLocationServiceDisabledDialog(); // muestra un dialogo si los permisos han sido deshabilitados
      }
      setState(() { _isLoading = false; }); // deja de cargar si los permisos han sido deshabilitados
      return;
    }

    _startLocationUpdates(); // comienza a hacer fetch
  }

  /// comienza con las actualizaciones de locaciony pone la camaraen la posicion inicial
  Future<void> _startLocationUpdates() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Peticion de locacion de alta precision
      );
      if (mounted) {
        setState(() {
          _initialCameraPosition = LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          _updateCurrentLocationMarker(); // Agrega el marcador a la locacion
          _isLoading = false; // Se esconde el icono de carga cuandoel mapa esta listo
        });
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Actualiza el mapa cada 10 metros
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateCurrentLocationMarker(); // Actualiza marcador
            _updateCameraPosition(); // Mantiene el mapa actualizado
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de ubicación: ${e.toString()}')),
        );
        setState(() { _isLoading = false; }); // Deja de cargar despues de un error
      }
    }
  }

  /// actualiza el marcador en el mapa para mostrar la posicion actual del usuario
  void _updateCurrentLocationMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation'); // Remueve marcador obsoleto

    if (_currentPosition != null && _currentLocationIcon != BitmapDescriptor.defaultMarker) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _currentLocationIcon,
          rotation: _currentPosition!.heading ?? 0, // Gira el marcador basado en la orientacion cardinal del usuario
          anchor: const Offset(0.5, 0.5), // Centra el marcador en la posicion
        ),
      );
    }
  }

  /// Anima la camara a la posicion actualizada
  void _updateCameraPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  ///Muestra un dialogo para informar que se han otorgado los permisos
  Future<void> _showPermissionDeniedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Ubicación Requerido'),
        content: const Text('Esta aplicación necesita permiso de ubicación para funcionar correctamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              /// openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Muestra un dialogo al usuario informando que los servicios de ubicacion estan desactivados
  Future<void> _showLocationServiceDisabledDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicio de Ubicación Desactivado'),
        content: const Text('Por favor, habilita los servicios de ubicación para usar esta función.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // intent especifico para android---->abre location source settings
              const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.LOCATION_SOURCE_SETTINGS',
              );
              intent.launch();
            },
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );
  }

  /// Callback cuando GoogleMap es creado
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_initialCameraPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialCameraPosition!,
            zoom: 15, // Default zoom level
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // si cargar o posicion inicial no disponible aun mostrar indicador de barra de progreso
    if (_isLoading || _initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // si no, muestra GoogleMap
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _initialCameraPosition!,
        zoom: 15, // Nivel de zoom inicial
      ),
      markers: _markers, // Muestra el marcador de usuario actual
      myLocationEnabled: true, // Muestra el marcador por defecto del usuario
      myLocationButtonEnabled: true, // Muestra el boton para recentrarla camara
    );
  }
}
