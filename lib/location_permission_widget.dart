import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionWidget extends StatefulWidget {
  @override
  _LocationPermissionWidgetState createState() => _LocationPermissionWidgetState();
}

class _LocationPermissionWidgetState extends State<LocationPermissionWidget> {
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    setState(() {
      _locationPermissionStatus = status;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionStatus = status;
    });
  }

  Widget _buildPermissionStatus() {
    switch (_locationPermissionStatus) {
      case PermissionStatus.granted:
        return Text('Permisos de Ubicacion Concedidos !');
      case PermissionStatus.denied:
        return Column(
          children: [
            Text('Permisos de Ubicacion Negados.'),
            ElevatedButton(
              onPressed: _requestLocationPermission,
              child: Text('Pedir Permisos'),
            ),
          ],
        );
      case PermissionStatus.permanentlyDenied:
        return Column(
          children: [
            Text(
              'Permisos de Ubicacion permanentemente denegados. Por favor habilite los permisos en los ajustes de Applicacion',
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () {
               openAppSettings(); // Abre la pagina de configuracion
              },
              child: Text('Abrir la configuracion de la App'),
            ),
          ],
        );
      case PermissionStatus.limited:
        return Text('Permisos de ubicación Limitados.');
      case PermissionStatus.restricted:
        return Text('Permisos de ubicación limitados a este dispositivo.');
      default:
        return Text('Verificando permisos de ubicación...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildPermissionStatus(),
        ],
      ),
    );
  }
}