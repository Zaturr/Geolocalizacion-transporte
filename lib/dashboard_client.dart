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
  String _currentRouteName = "Cargando rutas..."; // Initial state while loading
  String? _currentRouteId; // NEW: To store the ID of the currently selected route
  String? _userName; // To store the fetched username

  late List<RouteOption> _availableRoutes = []; // Initialize to an empty list
  List<Map<String, dynamic>> _currentRouteStops = []; // NEW: To store the fetched stops for the current route

  late List<Widget> _profileMenuItems;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchRoutes();
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
        onNavigateToSupport: () => _navigateToSupport(context, _userName),
      ),
    ];
  }

  // MODIFIED: Method to fetch routes including their IDs
  Future<void> _fetchRoutes() async {
    try {
      final response = await Supabase.instance.client
          .from('routes')
          .select('id, name') // Select both id and name
          .order('name', ascending: true); // Optional: order routes alphabetically

      if (mounted) {
        setState(() {
          _availableRoutes = [];

          for (var routeData in response) {
            final String routeId = routeData['id'] as String;
            final String routeName = routeData['name'] as String;
            _availableRoutes.add(
              RouteOption(
                id: routeId,
                name: routeName,
                onTap: () {
                  // This onTap will be called by RouteSelectorBar.
                  // The actual handling is in _handleRouteSelected.
                },
              ),
            );
          }

          // Set the initial current route to the first one fetched or a default
          if (_availableRoutes.isNotEmpty) {
            _currentRouteName = _availableRoutes[0].name;
            _currentRouteId = _availableRoutes[0].id;
            _fetchStopsForRoute(_currentRouteId!); // Fetch stops for the initial route
          } else {
            _currentRouteName = "No hay rutas disponibles";
            _currentRouteId = null;
          }
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Error fetching routes: ${e.message}');
      if (mounted) {
        setState(() {
          _currentRouteName = "Error al cargar rutas";
          _currentRouteId = null;
          _availableRoutes = [
            RouteOption(id: '', name: "Error al cargar", onTap: () {}),
          ];
        });
      }
    } catch (e) {
      debugPrint('Unexpected error fetching routes: $e');
      if (mounted) {
        setState(() {
          _currentRouteName = "Error desconocido";
          _currentRouteId = null;
          _availableRoutes = [
            RouteOption(id: '', name: "Error desconocido", onTap: () {}),
          ];
        });
      }
    }
  }

  // NEW: Method to fetch stops for a given routeId
  Future<void> _fetchStopsForRoute(String routeId) async {
    try {
      // Query the 'paradas' table where 'Ruta' (foreign key) matches the routeId
      // and 'organizacion_id' matches the current user's organization_id if applicable
      // (assuming MapScreen doesn't need to filter by organization, but it's good practice)
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('paradas')
          .select('Nombre_Parada, Coordenadas') // Select the stop name and coordinates
          .eq('Ruta', routeId); // Filter by the selected route's ID

      if (mounted) {
        setState(() {
          _currentRouteStops = response;
          debugPrint('Fetched stops for route $routeId: $_currentRouteStops');
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Error fetching stops for route $routeId: ${e.message}');
      if (mounted) {
        setState(() {
          _currentRouteStops = []; // Clear stops on error
        });
        // Optionally show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar paradas: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error fetching stops: $e');
      if (mounted) {
        setState(() {
          _currentRouteStops = []; // Clear stops on error
        });
        // Optionally show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado al cargar paradas: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Method to fetch username from Supabase
  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response =
            await Supabase.instance.client
                .from('profiles') // Your profiles table name
                .select('username') // The column where the username is stored
                .eq('id', user.id)
                .single();

        if (mounted) {
          setState(() {
            _userName = response['username'] as String?;
          });
        }
      } on PostgrestException catch (e) {
        debugPrint('Error fetching user profile: ${e.message}');
        if (mounted) {
          setState(() {
            _userName = "Usuario";
          });
        }
      } catch (e) {
        debugPrint('Unexpected error fetching user profile: $e');
        if (mounted) {
          setState(() {
            _userName = "Usuario";
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = "Invitado";
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
      builder: (context) => AlertDialog(
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
              onTap: () => _navigateToReplacement(
                context,
                const DashboardAdmin(),
              ),
            ),
            ListTile(
              title: Text(
                "Conductor",
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => _navigateToReplacement(
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

  // MODIFIED: _handleRouteSelected now fetches stops
  void _handleRouteSelected(RouteOption selectedRoute) {
    setState(() {
      _currentRouteName = selectedRoute.name;
      _currentRouteId = selectedRoute.id;
      _currentRouteStops = []; // Clear previous stops while loading new ones
    });
    // Fetch stops for the newly selected route
    if (_currentRouteId != null && _currentRouteId!.isNotEmpty) {
      _fetchStopsForRoute(_currentRouteId!);
    } else {
      debugPrint('Selected route has no ID or empty ID. Cannot fetch stops.');
    }
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
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToUserSettings() {
    _navigateTo(context, const UserSettingsScreen());
  }

  void _navigateToCreateOrganization() {
    _navigateTo(context, const CreateOrganizationScreen());
  }

  void _navigateToSupport(BuildContext context, String? userName) {
    _navigateTo(
      context,
      SupportScreen(userName: userName),
    );
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
    final double topBarHeightWithExtraSpace =
        kToolbarHeight + _topPadding + TopBar.extraSpaceAboveBar + (TopBar.internalVerticalPadding * 2);

    return Scaffold(
      body: Stack(
        children: [
          // [Caja 1: Fondo del Mapa]
          // Pass the fetched stops to MapScreen
          MapScreen(
            routeStops: _currentRouteStops, // Pass the list of stops
          ),

          // [Caja 2: Contenido Superior (TopBar y RouteSelectorBar)]
          Column(
            children: [
              // [Caja 2.1: TopBar]
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName: _userName ?? "Cargando...",
                topPadding: _topPadding,
              ),
              const SizedBox(height: 20.0),

              // [Caja 2.2: RouteSelectorBar]
              RouteSelectorBar(
                currentRouteName: _currentRouteName,
                routeOptions: _availableRoutes,
                onRouteSelected: _handleRouteSelected,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 45.0,
                      right: 16.0,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            heroTag: "vistas",
                            onPressed: _openQrScanner,
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

          // [Caja 4: Menú de Perfil Desplegable]
          if (_isProfileMenuOpen)
            Positioned(
              top: topBarHeightWithExtraSpace + 25,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _closeProfileMenu,
                behavior: HitTestBehavior.opaque,
                child: CustomDropdownMenu(
                  onCloseMenu: _closeProfileMenu,
                  menuItems: _profileMenuItems,
                  topPosition: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }
}