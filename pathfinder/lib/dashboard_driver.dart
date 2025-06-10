import 'package:flutter/material.dart';
import 'location_permission_widget.dart';
import 'dashboard_admin.dart';
import 'dashboard_client.dart';
import 'map_screen.dart';
import 'dart:io'; // Import para Platform.operatingSystem

class DashboardDriver extends StatefulWidget {
  const DashboardDriver({Key? key}) : super(key: key);

  @override
  State<DashboardDriver> createState() => _DashboardDriverState();
}

class _DashboardDriverState extends State<DashboardDriver> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _showDashboardSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Dashboard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Admin"),
              onTap: () => _navigateTo(context, const DashboardAdmin()),
            ),
            ListTile(
              title: const Text("Cliente"),
              onTap: () => _navigateTo(context, const DashboardClient()),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  double get _topPadding {
    if (Platform.isAndroid) {
      return 25.0; // Android usualmente maneja esto bien
    } else if (Platform.isIOS) {
      return MediaQuery.of(context).padding.top; // Obtener el padding del área segura superior para iOS
    } else {
      return 0.0; // Predeterminado para otras plataformas
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: _topPadding),
                height: kToolbarHeight + _topPadding,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleMenu,
                      child: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 3,
                      child: const Text(
                        "Nombre del Conductor", // Placeholder para el nombre del usuario
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    const MapScreen(),
                    Positioned(
                      bottom: 16.0,
                      right: 16.0,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            heroTag: "button1",
                            onPressed: () {
                              // TODO: Agregar funcionalidad para el primer botón
                            },
                            child: const Icon(Icons.navigation),
                          ),
                          const SizedBox(height: 8.0),
                          FloatingActionButton(
                            heroTag: "button2",
                            onPressed: () {
                              // TODO: Agregar funcionalidad para el segundo botón
                            },
                            child: const Icon(Icons.layers),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isMenuOpen)
            Positioned(
              top: kToolbarHeight + _topPadding,
              left: 0,
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6, // Ajustar el ancho según sea necesario
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 16.0),
                            const Text("Nombre del Conductor", style: TextStyle(fontWeight: FontWeight.bold)), // Placeholder
                          ],
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text("Opción 1"),
                        onTap: () {
                          _closeMenu();
                          // TODO: Agregar acción para la Opción 1
                        },
                      ),
                      ListTile(
                        title: const Text("Opción 2"),
                        onTap: () {
                          _closeMenu();
                          // TODO: Agregar acción para la Opción 2
                        },
                      ),
                      ListTile(
                        title: const Text("Opción 3"),
                        onTap: () {
                          _closeMenu();
                          // TODO: Agregar acción para la Opción 3
                        },
                      ),
                      ListTile(
                        title: const Text("Opción 4"),
                        onTap: () {
                          _closeMenu();
                          // TODO: Agregar acción para la Opción 4
                        },
                      ),
                      ListTile(
                        title: const Text("Cambiar Dashboard"),
                        onTap: () {
                          _closeMenu();
                          _showDashboardSelector(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}