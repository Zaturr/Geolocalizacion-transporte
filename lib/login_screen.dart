// lib/screens/login_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your custom widgets
import 'widget/welcome_panel.dart';

// Import your dashboard screens
import 'dashboard_client_screen.dart';
import 'dashboard_admin_screen.dart';
import 'dashboard_driver_screen.dart';
import 'register_screen.dart';

// NEW: Import the controller and service
import 'package:PathFinder/services/auth_service.dart';
import 'package:PathFinder/controllers/login_controller.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();

  // --- Propiedades para la pantalla de bienvenida (gestionadas por la UI) ---
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _panelHeight = 0.0; // Altura del panel de bienvenida, inicialmente oculto
  bool _showWelcomePanel = false; // Controla la visibilidad del panel de bienvenida
  // --- Fin de propiedades ---

  @override
  void initState() {
    super.initState();
    // Initialize controller and pass AuthService
    _controller = LoginController(AuthService(Supabase.instance.client));
    
    // Set up callbacks from controller to UI for navigation and welcome panel display
    _controller.onLoginSuccess = _navigateToDashboard;
    _controller.onWelcomePanelShown = _showWelcomePanelUI;

    // Add listener for general state changes (e.g., error messages, loading)
    _controller.addListener(_onControllerChange);

    // Start the app flow (session check or welcome panel)
    _controller.initializeAppFlow();
  }

  void _onControllerChange() {
    // Show error dialog if an error message is present
    if (_controller.errorMessage != null && mounted) {
      _mostrarError(_controller.errorMessage!);
      // REMOVED: _controller._setErrorMessage(null);
      // The controller now handles clearing its own error message internally
      // when a new operation starts.
    }
    // Rebuild UI if other states like _isLoading or _verificandoSesion change
    // This is important because ListenableBuilder only rebuilds parts of the tree,
    // but the overall Scaffold structure and conditional rendering (like _verificandoSesion)
    // are outside the ListenableBuilder.
    setState(() {});
  }

  // Callback from controller to navigate to appropriate dashboard
  void _navigateToDashboard(String role) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _obtenerDashboardPorRol(role),
        ),
      );
    }
  }

  // Callback from controller to show the welcome panel
  void _showWelcomePanelUI() {
    if (mounted) {
      setState(() {
        _showWelcomePanel = true; // Show the welcome panel
      });
      // Animate the panel to slide up after a brief delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _panelHeight = MediaQuery.of(context).size.height * 0.7; // Adjust height as needed
          });
        }
      });
    }
  }

  // Obtiene el rol del usuario desde Supabase (logic moved to AuthService)
  // This method is now only for mapping role string to Widget
  Widget _obtenerDashboardPorRol(String role) {
    switch (role) {
      case 'Administrador':
        return const DashboardAdmin();
      case 'Conductor':
        return const DashboardDriver();
      case 'Usuario':
      default:
        return const DashboardClient();
    }
  }

  // Muestra un diálogo de error
  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Inicio de Sesión'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Function to mark that the user has completed the welcome.
  Future<void> _setWelcomeSeenUI() async {
    await _controller.setWelcomeSeen(); // Delegate to controller
    if (mounted) {
      setState(() {
        _showWelcomePanel = false; // Hide the welcome panel
        _panelHeight = 0.0; // Animate the panel down
      });
    }
  }

  // Function to show the welcome panel again
  void _showWelcomePanelAgainUI() {
    _controller.showWelcomePanelAgain(); // Delegate to controller
    if (mounted) {
      setState(() {
        _showWelcomePanel = true;
        _panelHeight = MediaQuery.of(context).size.height * 0.7;
        _currentPage = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose(); // Dispose the controller
    _pageController.dispose(); // Dispose the page controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show loading while verifying session
    if (_controller.verificandoSesion) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio de Sesión"),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main login form content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListenableBuilder(
                    listenable: _controller, // Listen to controller for isLoading and errorMessage
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30.0),
                            child: Image.asset(
                              isDarkMode ? 'assets/LogoW.png' : 'assets/LogoB.png',
                              height: 420,
                              width: 420,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.account_circle, size: 120);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '¡Bienvenido de vuelta!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _controller.emailController, // Use controller's text controller
                            decoration: InputDecoration(
                              labelText: "Correo Electrónico",
                              labelStyle: theme.textTheme.bodyLarge,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                            ),
                            style: theme.textTheme.bodyLarge,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _controller.passwordController, // Use controller's text controller
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              labelStyle: theme.textTheme.bodyLarge,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                            ),
                            obscureText: true,
                            style: theme.textTheme.bodyLarge,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _controller.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      await _controller.login(); // Delegate login to controller
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: _controller.isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Iniciar Sesión"),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.secondary,
                            ),
                            child: const Text("¿No tienes cuenta? Regístrate"),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: _showWelcomePanelAgainUI, // Call UI method
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.tertiary,
                            ),
                            child: const Text("Mostrar Bienvenida"),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Welcome Panel (conditionally displayed)
          if (_showWelcomePanel)
            WelcomePanel(
              pageController: _pageController,
              currentPage: _currentPage,
              panelHeight: _panelHeight,
              isDarkMode: isDarkMode,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              onWelcomeComplete: _setWelcomeSeenUI, // Call UI method
            ),
        ],
      ),
    );
  }
}