import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'login.dart';
import 'dashboard_client.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';
// import 'splash.dart'; // Ya no es necesario si la lógica de bienvenida está en login.dart
import 'themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');

    await initializeDateFormatting('es');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // Initial check for existing session
    // This part correctly sets the initial route based on session presence.
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      runApp(const MyApp(initialRoute: '/dashboard'));
    } else {
      // Si no hay sesión, siempre ir a la pantalla de login, que ahora maneja la bienvenida.
      runApp(const MyApp(initialRoute: '/login'));
    }
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = '/login'}); // Cambiado el valor por defecto a '/login'

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinder',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {
        // '/splash': (context) => const SplashScreen(), // Esta ruta ya no es necesaria
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardWrapper(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  // We still use Future<Widget> because during the loading phase,
  // we want to show a CircularProgressIndicator.
  late Future<Widget> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future when the state is created
    _dashboardFuture = _determineDashboard();
  }

  Future<String> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      // Ensure 'role' is not null and is a String
      return response['role'] as String? ?? 'User';
    } catch (e) {
      // Log the error for debugging
      print('Error fetching user role: $e');
      return 'User'; // Default to 'User' on error
    }
  }

  Widget _getDashboardByRole(String role) {
    switch (role) {
      case 'Admin':
        return const DashboardAdmin();
      case 'Driver':
        return const DashboardDriver();
      case 'Client': // Ensure your database 'role' actually stores 'Client' if that's the default/fallback
      case 'User': // Also handle 'User' if that's a possible role for clients
      default:
        return const DashboardClient();
    }
  }

  Future<Widget> _determineDashboard() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // If no session, navigate to login and prevent going back to wrapper
        // Use post-frame callback to ensure context is available and widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        // Return a temporary empty/loading widget while navigation happens
        return Container(); // or Scaffold(body: Center(child: Text('Redirecting...')))
      }

      final userId = session.user.id;
      final role = await _getUserRole(userId);
      return _getDashboardByRole(role);
    } catch (e) {
      print('Error determining dashboard: $e');
      // If any error occurs, navigate to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return Container(); // Temporary widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while the future is resolving
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // This case should ideally not be reached if pushReplacementNamed works
          // But as a fallback, display an error or redirect again
          print('FutureBuilder error: ${snapshot.error}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const SizedBox.shrink(); // Empty widget while redirecting
        } else if (snapshot.hasData && snapshot.data != null) {
          // If the future successfully returned a dashboard widget, display it
          return snapshot.data!;
        } else {
          // Fallback, if snapshot.data is null for some reason
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const SizedBox.shrink(); // Empty widget while redirecting
        }
      },
    );
  }
}
