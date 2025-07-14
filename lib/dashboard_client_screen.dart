// lib/dashboard_client_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart' hide Route;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your custom widgets
import 'widget/top_bar.dart';
import 'widget/custom_dropdown_menu.dart';
import 'widget/route_selector_bar.dart';
import 'widget/profile_menu_body.dart';

// Import your dashboard screens and new screens
import 'dashboard_admin_screen.dart';
import 'dashboard_driver_screen.dart';
import 'widget/map_screen.dart';
import 'qr_scanner_screen.dart';
import 'user_settings_screen.dart';
import 'create_organization_screen.dart';
import 'support_screen.dart';

// Import services and models for routes
import 'package:PathFinder/services/map_data_service.dart';
import 'package:PathFinder/models/map_models.dart';

class DashboardClient extends StatefulWidget {
  const DashboardClient({Key? key}) : super(key: key);

  @override
  State<DashboardClient> createState() => _DashboardClientState();
}

class _DashboardClientState extends State<DashboardClient> {
  bool _isProfileMenuOpen = false;
  String _currentRouteName = "Cargando rutas...";
  String? _userName = "Cargando...";

  late List<RouteOption> _availableRoutes = [];
  late List<Widget> _profileMenuItems;

  late MapDataService _mapDataService;
  List<Route> _fetchedRoutes = [];
  bool _isLoadingRoutes = true;

  final GlobalKey<MapViewWidgetState> _mapViewKey = GlobalKey<MapViewWidgetState>();

  @override
  void initState() {
    super.initState();
    _mapDataService = MapDataService(Supabase.instance.client);
    _fetchUserName();
    _fetchRoutes();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('username')
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

  Future<void> _fetchRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
      _currentRouteName = "Cargando rutas...";
    });
    try {
      _fetchedRoutes = await _mapDataService.fetchRoutes();

      if (mounted) {
        setState(() {
          _availableRoutes = _fetchedRoutes.map((route) {
            return RouteOption(
              name: route.name,
              onTap: () {},
              route: route,
            );
          }).toList();

          if (_availableRoutes.isNotEmpty) {
            _currentRouteName = _availableRoutes.first.name;
            _fetchAndLoadPolylineAndBusStops(_availableRoutes.first.route.id); // MODIFIED
          } else {
            _currentRouteName = "No hay rutas disponibles";
          }
        });
      }
    } catch (e) {
      print("Error fetching routes: $e");
      if (mounted) {
        setState(() {
          _currentRouteName = "Error al cargar rutas";
          _availableRoutes = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar rutas: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  // MODIFIED: Fetches polyline AND bus stops, then updates the map
  Future<void> _fetchAndLoadPolylineAndBusStops(String routeId) async {
    try {
      // Fetch polyline
      final polylineCoordinates = await _mapDataService.fetchPolylineForRoute(routeId);
      _mapViewKey.currentState?.updatePolyline(polylineCoordinates);

      // Fetch bus stops for the route
      final busStops = await _mapDataService.fetchBusStopsForRoute(routeId);
      _mapViewKey.currentState?.updateBusStops(busStops); // NEW: Update bus stops
    } catch (e) {
      print("Error loading route data for route $routeId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos de la ruta: $e")),
      );
    }
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
                  ),
      ),
    ];
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

  // MODIFIED: _handleRouteSelected to call the combined fetch method
  void _handleRouteSelected(RouteOption selectedRouteOption) {
    setState(() {
      _currentRouteName = selectedRouteOption.name;
    });
    _fetchAndLoadPolylineAndBusStops(selectedRouteOption.route.id); // MODIFIED
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
        kToolbarHeight + _topPadding + TopBar.extraSpaceAboveBar +
        (TopBar.internalVerticalPadding * 2);

    return Scaffold(
      body: Stack(
        children: [
          MapViewWidget(key: _mapViewKey),

          Column(
            children: [
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName: _userName ?? "Cargando...",
                topPadding: _topPadding,
              ),
              const SizedBox(height: 20.0),

              _isLoadingRoutes
                  ? const CircularProgressIndicator()
                  : RouteSelectorBar(
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
                            heroTag: "qr_scanner_client", // Unique HeroTag
                            onPressed: _openQrScanner,
                            child: const Icon(Icons.qr_code_scanner), // Changed icon to QR
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

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