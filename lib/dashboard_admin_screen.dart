// lib/dashboard_admin.dart

import 'package:flutter/material.dart' hide Route;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your custom widgets
import 'widget/top_bar.dart';
import 'widget/custom_dropdown_menu.dart';
import 'widget/admin_profile_menu_body.dart';
import 'widget/monthly_users_chart.dart';
import 'widget/admin_quick_actions_bar.dart';
import 'widget/company_vehicles_dashboard_widget.dart'; // <--- NEW IMPORT for dashboard widget


// Import your dashboard screens and new screens
import 'dashboard_client_screen.dart'; // Ensure correct path for screens
import 'dashboard_driver_screen.dart';
import 'user_settings_screen.dart';
import 'support_screen.dart';
import 'manage_users_screen.dart';
import 'edit_admin_settings_screen.dart';
import 'route_list_screen.dart';
import 'company_vehicles_screen.dart'; // <--- NEW IMPORT for the main screen


class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  bool _isProfileMenuOpen = false;
  String _userName = "Cargando...";
  String? _organizationId; // New: to store the organization ID for the dashboard widget
  bool _isLoadingOrgId = true; // New: to track org ID loading
  String? _orgIdErrorMessage; // New: to store org ID loading errors

  late List<Widget> _profileMenuItems;

  @override
  void initState() {
    super.initState();
    _fetchUserNameAndOrganizationId(); // Modified to fetch both
  }

  Future<void> _fetchUserNameAndOrganizationId() async {
    setState(() {
      _isLoadingOrgId = true;
      _orgIdErrorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch username
      final userResponse = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();

      // Fetch organization ID created by this user
      final List<Map<String, dynamic>> organizationsResponse = await Supabase.instance.client
          .from('organizations')
          .select('id')
          .eq('created_by', user.id);

      if (mounted) {
        setState(() {
          _userName = userResponse['username'] as String? ?? user.email ?? "Admin";
          if (organizationsResponse.isNotEmpty && organizationsResponse.first['id'] != null) {
            _organizationId = organizationsResponse.first['id'] as String;
          } else {
            _orgIdErrorMessage = 'No organization found for this user.';
            print('DashboardAdmin: No organization found for user ID: ${user.id}');
          }
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _userName = "Error";
          _orgIdErrorMessage = 'Database Error: ${e.message}';
        });
      }
      print("PostgrestException fetching user/org: $e");
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = "Error";
          _orgIdErrorMessage = 'An unexpected error occurred: $e';
        });
      }
      print("Error fetching user/org: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrgId = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileMenuItems = [
      AdminProfileMenuBody(
        onCloseMenu: _closeProfileMenu,
        onShowDashboardSelector: () => _showDashboardSelector(context),
        onLogout: _handleLogout,
        onNavigateToSettings: _navigateToUserSettings,
        onCreateOrganization: () { /* Admin menu doesn't offer 'create organization' directly now */ },
        onNavigateToSupport: _navigateToSupport,
        onNavigateToManageUsers: _navigateToManageUsers,
        onNavigateToEditAdminSettings: _navigateToEditAdminSettings,
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
                "Conductor",
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => _navigateToReplacement(context, const DashboardDriver()),
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

  void _navigateToSupport() {
    _navigateTo(context, const SupportScreen());
  }

  void _navigateToManageUsers() {
    _navigateTo(context, const ManageUsersScreen());
  }

  void _navigateToEditAdminSettings() {
    _navigateTo(context, const EditAdminSettingsScreen());
  }

  void _navigateToRouteList() {
    _navigateTo(context, const RouteListScreen());
  }

  // Navigate to the full Company Vehicles Management Screen
  void _navigateToCompanyVehicles() {
    _navigateTo(context, const CompanyVehiclesScreen());
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
    final double topBarHeightWithExtraSpace =
        kToolbarHeight + _topPadding + TopBar.extraSpaceAboveBar +
        (TopBar.internalVerticalPadding * 2);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Column(
            children: [
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName: _userName,
                topPadding: _topPadding,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Resumen del Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const MonthlyUsersChart(),
                      const SizedBox(height: 16),
                      AdminQuickActionsBar(
                        onVehiclesPressed: _navigateToCompanyVehicles,
                      ),
                      const SizedBox(height: 16),
                      // Display the dashboard summary widget
                      CompanyVehiclesDashboardWidget(
                        organizationId: _organizationId, // Pass the fetched organization ID
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        elevation: 4,
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estadísticas Rápidas',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text('Vehículos Activos: 15/20', style: Theme.of(context).textTheme.bodyLarge),
                              Text('Rutas Activas Hoy: 5', style: Theme.of(context).textTheme.bodyLarge),
                              Text('Quejas Pendientes: 2', style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _navigateToManageUsers,
                              icon: const Icon(Icons.people_alt),
                              label: const Text('Administrar Usuarios'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _navigateToEditAdminSettings,
                              icon: const Icon(Icons.settings),
                              label: const Text('Configuración de la Administración'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isProfileMenuOpen)
            Positioned(
              top: topBarHeightWithExtraSpace,
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