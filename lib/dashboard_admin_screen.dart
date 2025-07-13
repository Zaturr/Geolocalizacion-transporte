import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your custom widgets
import 'widget/top_bar.dart';
import 'widget/custom_dropdown_menu.dart';
import 'widget/admin_profile_menu_body.dart';
import 'widget/monthly_users_chart.dart';
import 'widget/admin_quick_actions_bar.dart';
import 'company_vehicles_screen.dart'; // <--- NEW: Import the vehicles list widget

// Import your dashboard screens and new screens
import 'dashboard_client_screen.dart';
import 'dashboard_driver_screen.dart';
import 'user_settings_screen.dart';
//import 'create_organization_screen.dart'; // Comentado si no se usa directamente aquí
import 'support_screen.dart';
import 'manage_users_screen.dart';
import 'edit_admin_settings_screen.dart';

import 'route_list_screen.dart'; // <--- NEW: Import the route list screen

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  bool _isProfileMenuOpen = false;
  String _userName = "Cargando...";

  late List<Widget> _profileMenuItems;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userName = response['username'] as String? ?? user.email ?? "Admin";
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
      print("Error fetching username: $e");
      if (mounted) {
        setState(() {
          _userName = "Error";
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

  // NEW: Navigate to Route List Screen
  void _navigateToRouteList() {
    _navigateTo(context, const RouteListScreen());
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
    // Calcula la altura total de la TopBar, incluyendo el padding del sistema y el espacio extra.
    // Se usa para posicionar otros elementos relativos a la TopBar.
    final double topBarHeightWithExtraSpace =
        kToolbarHeight + _topPadding + TopBar.extraSpaceAboveBar +
        (TopBar.internalVerticalPadding * 2);

    return Scaffold(
      // [Fondo del Dashboard]
      // El color de fondo del Scaffold se establece utilizando el color 'secondaryContainer'
      // del esquema de colores de Material Design para proporcionar un contraste.
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // [Caja 1: Contenido Principal del Dashboard]
          // Un Column que contiene la TopBar y el área de contenido principal.
          Column(
            children: [
              // [Caja 1.1: TopBar]
              // La barra superior de la aplicación con el nombre de usuario y el botón de menú.
              TopBar(
                onMenuPressed: _toggleProfileMenu,
                userName: _userName,
                topPadding: _topPadding,
              ),
              // [Caja 1.2: Área de Contenido Desplazable]
              // Un área expandida y desplazable que contiene los diferentes widgets del dashboard.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // [Caja 1.2.1: Título de Resumen]
                      // Título para la sección de resumen del dashboard.
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
                      // [Caja 1.2.2: Gráfico de Usuarios Mensuales]
                      // Widget que muestra un gráfico de usuarios mensuales.
                      const MonthlyUsersChart(),
                      const SizedBox(height: 16),
                      // [Caja 1.2.3: Barra de Acciones Rápidas del Admin]
                      // Widget con botones para acciones rápidas del administrador.
                      // Se asume que este widget contendrá el botón "Rutas"
                      // y que su lógica de navegación se manejará internamente
                      // o a través de un callback si es necesario.
                      const AdminQuickActionsBar(),
                      const SizedBox(height: 16),
                      // [Caja 1.2.4: Tarjeta de Estadísticas Rápidas]
                      // Una tarjeta con información estadística clave.
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        elevation: 4,
                        // El color de fondo de la tarjeta utiliza el color 'surface' del esquema de colores,
                        // que por defecto es diferente al color 'background' del Scaffold.
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
                      // [Caja 1.2.5: Lista de Vehículos de la Compañía]
                      // Widget que muestra una lista de vehículos de la compañía.
                      const CompanyVehiclesList(),
                      const SizedBox(height: 16), // Espacio debajo de la lista de vehículos

                      // [Caja 1.2.6: Botones de Navegación Adicionales]
                      // Sección con botones para navegar a otras pantallas de administración.
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
                            // El botón "Administrar Rutas" ha sido eliminado de aquí.
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

          // [Caja 2: Menú de Perfil Desplegable]
          // El menú desplegable del perfil, que se muestra u oculta condicionalmente.
          if (_isProfileMenuOpen)
            Positioned(
              // Posiciona el menú justo debajo de la TopBar.
              top: topBarHeightWithExtraSpace,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _closeProfileMenu, // Cierra el menú al tocar fuera
                behavior: HitTestBehavior.opaque, // Permite detectar toques en el área transparente
                child: CustomDropdownMenu(
                  onCloseMenu: _closeProfileMenu,
                  menuItems: _profileMenuItems,
                  topPosition: 0, // Posición interna del menú (puede ajustarse)
                ),
              ),
            ),
        ],
      ),
    );
  }
}
