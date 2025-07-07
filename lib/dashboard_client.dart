import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your custom widgets
import 'top_bar.dart';
import 'custom_dropdown_menu.dart';
import 'route_selector_bar.dart';
import 'profile_menu_body.dart';

// Import your dashboard screens and new screens
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';
import 'map_screen.dart';
import 'qr_scanner_screen.dart';
import 'user_settings_screen.dart';
import 'create_organization_screen.dart';
import 'support_screen.dart'; // Make sure this is imported

class DashboardClient extends StatefulWidget {
  const DashboardClient({Key? key}) : super(key: key);

  @override
  State<DashboardClient> createState() => _DashboardClientState();
}

class _DashboardClientState extends State<DashboardClient> {
  bool _isProfileMenuOpen = false;
  String _currentRouteName = "Ruta Principal";
  String? _userName; // NEW: To store the fetched username

  late List<RouteOption> _availableRoutes;
  late List<Widget> _profileMenuItems;

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // NEW: Call to fetch username

    _availableRoutes = [
      RouteOption(
        name: "Ruta Principal",
        onTap: () {
          print("Selected: Ruta Principal");
        },
      ),
      RouteOption(
        name: "Ruta 2 (Norte)",
        onTap: () {
          print("Selected: Ruta 2 (Norte)");
        },
      ),
      RouteOption(
        name: "Ruta 3 (Sur)",
        onTap: () {
          print("Selected: Ruta 3 (Sur)");
        },
      ),
      RouteOption(
        name: "Ver todas las Rutas",
        onTap: () {
          print("Selected: Ver todas las Rutas");
        },
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileMenuItems = [
      ProfileMenuBody(
        onCloseMenu: _closeProfileMenu,
        onShowDashboardSelector: () => _showDashboardSelector(context),
        onLogout: _handleLogout,
        onNavigateToSettings: _navigateToUserSettings,
        onCreateOrganization: _navigateToCreateOrganization,
        onNavigateToSupport:
            () => _navigateToSupport(
                  context,
                  _userName,
                ), // MODIFIED: Pass username
      ),
    ];
  }

  // NEW: Method to fetch username from Supabase
  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Assuming your user's name is in a 'profiles' table linked by user.id
        // and the column name for the username is 'username' or 'name'.
        // Adjust the table name and column name as per your Supabase setup.
        final response =
            await Supabase.instance.client
                .from('profiles') // Your profiles table name
                .select('username') // The column where the username is stored
                .eq('id', user.id)
                .single(); // Expecting a single row

        if (mounted) {
          setState(() {
            _userName = response['username'] as String?;
          });
        }
      } on PostgrestException catch (e) {
        debugPrint('Error fetching user profile: ${e.message}');
        if (mounted) {
          // Fallback or show error
          setState(() {
            _userName = "Usuario"; // Default name if fetching fails
          });
        }
      } catch (e) {
        debugPrint('Unexpected error fetching user profile: $e');
        if (mounted) {
          setState(() {
            _userName = "Usuario"; // Default name if fetching fails
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = "Invitado"; // For unauthenticated users
        });
      }
    }
  }

  void _toggleProfileMenu() {
    setState(() {
      _isProfileMenuOpen = !_isProfileMenuOpen;
    });
  }

  void _closeProfileMenu() {
    setState(() {
      _isProfileMenuOpen = false;
    });
  }

  void _showDashboardSelector(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Text(
              "Seleccionar Dashboard",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    "Admin",
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap:
                      () => _navigateToReplacement(
                            context,
                            const DashboardAdmin(),
                          ),
                ),
                ListTile(
                  title: Text(
                    "Conductor",
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap:
                      () => _navigateToReplacement(
                            context,
                            const DashboardDriver(),
                          ),
                ),
              ],
            ),
          ),
    );
  }

  void _navigateToReplacement(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _handleRouteSelected(RouteOption selectedRoute) {
    setState(() {
      _currentRouteName = selectedRoute.name;
    });
    selectedRoute.onTap();
  }

  Future<void> _openQrScanner() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code Scanned: $scannedCode'),
          duration: const Duration(seconds: 3),
        ),
      );
      print('Scanned QR Code: $scannedCode');
    } else {
      print('QR Scan cancelled or no code detected.');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToUserSettings() {
    _navigateTo(context, const UserSettingsScreen());
  }

  void _navigateToCreateOrganization() {
    _navigateTo(context, const CreateOrganizationScreen());
  }

  // MODIFIED: Accepts username
  void _navigateToSupport(BuildContext context, String? userName) {
    _navigateTo(
      context,
      SupportScreen(userName: userName),
    ); // Pass username to SupportScreen
  }

  double get _topPadding {
    if (Platform.isAndroid) {
      return 1.0;
    } else if (Platform.isIOS) {
      return MediaQuery.of(context).padding.top;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula la altura total de la TopBar, incluyendo el padding del sistema y el espacio extra.
    // Se usa para posicionar otros elementos relativos a la TopBar.
    final double topBarHeightWithExtraSpace =
        kToolbarHeight + _topPadding + TopBar.extraSpaceAboveBar + // Se corrigió el acceso
        (TopBar.internalVerticalPadding * 2); // Se corrigió el acceso

    return Scaffold(
      body: Stack(
        children: [
          // [Caja 1: Fondo del Mapa]
          // Esta es la pantalla principal del mapa que ocupa todo el espacio disponible.
          const MapScreen(),

          // [Caja 2: Contenido Superior (TopBar y RouteSelectorBar)]
          // Un Column para apilar la TopBar y la RouteSelectorBar en la parte superior.
          Column(
            children: [
              // [Caja 2.1: TopBar]
              // La barra superior de la aplicación con el nombre de usuario y el botón de menú.
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName:
                    _userName ?? "Cargando...", // Muestra el nombre o "Cargando..."
                topPadding: _topPadding, // Padding superior para la barra de estado
              ),
              // [Espacio entre TopBar y RouteSelectorBar]
              // SizedBox para agregar un espacio vertical entre la barra superior y la barra de selección de ruta.
              const SizedBox(height: 20.0), // Espacio adicional de 20.0 píxeles

              // [Caja 2.2: RouteSelectorBar]
              // La barra que permite al usuario seleccionar diferentes rutas.
              RouteSelectorBar(
                currentRouteName: _currentRouteName,
                routeOptions: _availableRoutes,
                onRouteSelected: _handleRouteSelected,
              ),
              // [Caja 3: Contenido Principal Expandido]
              // El resto del espacio disponible, que puede contener otros elementos superpuestos.
              Expanded(
                child: Stack(
                  children: [
                    // [Caja 3.1: Botón Flotante (QR Scanner)]
                    // Un FloatingActionButton posicionado en la esquina superior derecha del área expandida.
                    Positioned(
                      top: 45.0, // Posición desde la parte superior
                      right: 16.0, // Posición desde la derecha
                      child: Column(
                        children: [
                          FloatingActionButton(
                            heroTag: "vistas", // Etiqueta única para el Hero
                            onPressed: _openQrScanner, // Abre el escáner QR
                            child: const Icon(Icons.layers), // Icono de capas
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // [Caja 4: Menú de Perfil Desplegable]
          // El menú desplegable del perfil, que se muestra u oculta condicionalmente.
          if (_isProfileMenuOpen)
            Positioned(
              // Posiciona el menú justo debajo de la TopBar, con un pequeño margen.
              top: topBarHeightWithExtraSpace + 25, // Ajusta la posición vertical
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _closeProfileMenu, // Cierra el menú al tocar fuera
                behavior: HitTestBehavior.opaque, // Permite detectar toques en el área transparente
                child: CustomDropdownMenu(
                  onCloseMenu: _closeProfileMenu,
                  menuItems: _profileMenuItems,
                  topPosition: 50, // Posición interna del menú (puede ajustarse)
                ),
              ),
            ),
        ],
      ),
    );
  }
}
