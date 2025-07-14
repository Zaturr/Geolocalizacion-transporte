// lib/dashboard_client_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart' hide Route;
import 'dart:io'; // For Platform.isAndroid/iOS
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:google_maps_routes/google_maps_routes.dart';

// Import your custom widgets
import 'widget/top_bar.dart';
import 'widget/custom_dropdown_menu.dart';
import 'widget/route_selector_bar.dart';
import 'widget/profile_menu_body.dart';
//import 'widget/Path_Request.dart'; // NEW: Import the new screen

// Import your dashboard screens and new screens
import 'dashboard_admin_screen.dart';
import 'dashboard_driver_screen.dart';
//import 'widget/map_screen.dart';
import 'qr_scanner_screen.dart';
import 'user_settings_screen.dart';
import 'create_organization_screen.dart';
import 'support_screen.dart';

// Import services and models for routes
import 'package:PathFinder/services/map_data_service.dart';
import 'package:PathFinder/models/map_models.dart';
//import 'package:PathFinder/widget/Path_Request.dart';


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

  // GlobalKey for MapViewWidget is no longer needed here as MapViewWidget is moved
  // final GlobalKey<MapViewWidgetState> _mapViewKey = GlobalKey<MapViewWidgetState>();


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
    print("DashboardClient: Attempting to fetch routes metadata...");
    setState(() {
      _isLoadingRoutes = true;
      _currentRouteName = "Cargando rutas...";
    });
    try {
      _fetchedRoutes = await _mapDataService.fetchRoutes();
      print("DashboardClient: Fetched ${_fetchedRoutes.length} routes metadata.");

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
            print("DashboardClient: Initial route selected: ${_availableRoutes.first.name} (ID: ${_availableRoutes.first.route.id})");
            // No direct map display here, just set current route name initially
          } else {
            _currentRouteName = "No hay rutas disponibles";
            print("DashboardClient: No routes available.");
          }
        });
      }
    } catch (e) {
      print("DashboardClient: Error fetching routes: $e");
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

  // MODIFIED: This method now *navigates* to the PathRequestScreen
  Future<void> _fetchAndLoadPolylineAndBusStops(String routeId, String routeName) async {
    print("DashboardClient: Preparing to show map for route ID: $routeId and Name: $routeName");
    
    // Navigate to the new PathRequestScreen, passing the necessary route information
    //Navigator.push(
    //  context,
     // MaterialPageRoute(
        //builder: (context) => PathRequestScreen(
        //  routeId: routeId,
        //  routeName: routeName,
        //),
    //  ),
    //);
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

  // MODIFIED: _handleRouteSelected now passes routeName and ID to _fetchAndLoadPolylineAndBusStops
  void _handleRouteSelected(RouteOption selectedRouteOption) {
    print("DashboardClient: Route selected: ${selectedRouteOption.name} (ID: ${selectedRouteOption.route.id})");
    setState(() {
      _currentRouteName = selectedRouteOption.name;
    });
    _fetchAndLoadPolylineAndBusStops(selectedRouteOption.route.id, selectedRouteOption.name);
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
          // REMOVED: MapViewWidget is no longer directly in DashboardClient
          // It's now in PathRequestScreen

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
                            heroTag: "qr_scanner_client",
                            onPressed: _openQrScanner,
                            child: const Icon(Icons.qr_code_scanner),
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