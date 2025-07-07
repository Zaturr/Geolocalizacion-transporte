// lib/dashboard_driver.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your custom widgets
import 'top_bar.dart';
import 'custom_dropdown_menu.dart';
import 'route_selector_bar.dart';
import 'driver_profile_menu_body.dart'; // Import the driver-specific menu

// Import your dashboard screens and new screens
import 'dashboard_admin.dart';
import 'dashboard_client.dart';
import 'map_screen.dart';
import 'qr_scanner_screen.dart';
import 'user_settings_screen.dart';
import 'create_organization_screen.dart';
import 'support_screen.dart';
import 'edit_organization_settings_screen.dart';

class DashboardDriver extends StatefulWidget {
  const DashboardDriver({super.key});

  @override
  State<DashboardDriver> createState() => _DashboardDriverState();
}

class _DashboardDriverState extends State<DashboardDriver> {
  bool _isProfileMenuOpen = false;
  String _currentRouteName = "Ruta Principal";

  // State variable to hold the username
  String _userName = "Cargando..."; // Initial loading state

  late List<RouteOption> _availableRoutes;
  late List<Widget> _profileMenuItems;

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Call the method to fetch the username

    _availableRoutes = [
      RouteOption(name: "Ruta Principal", onTap: () {
        print("Selected: Ruta Principal");
        // Add logic to update map or other UI based on route
      }),
      RouteOption(name: "Ruta 2", onTap: () {
        print("Selected: Ruta 2");
      }),
      RouteOption(name: "Ruta 3", onTap: () {
        print("Selected: Ruta 3");
      }),
      RouteOption(name: "Ver todas las Rutas", onTap: () {
        print("Selected: Ver todas las Rutas");
      }),
    ];
  }

  // --- NEW METHOD TO FETCH USERNAME ---
  Future<void> _fetchUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Assuming you have a 'profiles' table with 'id' and 'username' columns
        final response = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();

        if (mounted) { // Check if the widget is still in the tree
          setState(() {
            _userName = response['username'] as String? ?? user.email ?? "Conductor"; // Use username, fallback to email, then "Conductor"
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = "No Logueado";
          });
        }
      }
    } catch (e) {
      print("Error fetching username for driver: $e");
      if (mounted) {
        setState(() {
          _userName = "Error"; // Indicate an error in fetching
        });
      }
    }
  }
  // --- END NEW METHOD ---


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileMenuItems = [
      DriverProfileMenuBody( // Use the NEW DriverProfileMenuBody
        onCloseMenu: _closeProfileMenu,
        onShowDashboardSelector: () => _showDashboardSelector(context),
        onLogout: _handleLogout,
        onNavigateToSettings: _navigateToUserSettings,
        onCreateOrganization: _navigateToCreateOrganization, // Still pass this, as it's required by the base ProfileMenuBody constructor
        onNavigateToSupport: _navigateToSupport,
        onNavigateToEditOrganization: _navigateToEditOrganizationSettings, // Pass the handler for the new button
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
              onTap: () => _navigateToReplacement(context, const DashboardAdmin()),
            ),
            ListTile(
              title: Text(
                "Cliente",
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => _navigateToReplacement(context, const DashboardClient()),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
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

  void _navigateToSupport() {
    _navigateTo(context, const SupportScreen());
  }

  void _navigateToEditOrganizationSettings() {
    _navigateTo(context, const EditOrganizationSettingsScreen());
  }

  double get _topPadding {
    if (Platform.isAndroid) {
      return 25.0;
    } else if (Platform.isIOS) {
      return MediaQuery.of(context).padding.top;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topBarHeight = kToolbarHeight + _topPadding + 10;


    return Scaffold(
      body: Stack(
        children: [
          const MapScreen(),

          Column(
            children: [
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName: _userName ?? "Cargando...", // Display fetched name or a loading text
                topPadding: _topPadding,
              ),
              RouteSelectorBar(
                currentRouteName: _currentRouteName,
                routeOptions: _availableRoutes,
                onRouteSelected: _handleRouteSelected,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 40.0,
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

          if (_isProfileMenuOpen)
            Positioned(
              top: topBarHeight,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _closeProfileMenu,
                behavior: HitTestBehavior.opaque,
                child: CustomDropdownMenu(
                  onCloseMenu: _closeProfileMenu,
                  menuItems: _profileMenuItems,
                  topPosition: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}