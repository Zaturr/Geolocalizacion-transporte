import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Importar package_info_plus

import 'login.dart';
import 'dashboard_client.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';
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
    final session = Supabase.instance.client.auth.currentSession;
    String initialRoute = '/login';
    if (session != null) {
      initialRoute = '/dashboard';
    }

    // Ejecutar la aplicación
    runApp(MyApp(initialRoute: initialRoute));
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

class MyApp extends StatefulWidget { // Cambiado a StatefulWidget
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = '/login'});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Llamar a la verificación de la versión de la aplicación después de que el widget se ha construido.
    // Esto asegura que el contexto esté disponible para mostrar diálogos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion(context);
    });
  }

  // Función para comparar versiones (ej. "1.0.0" vs "1.0.1")
  // Retorna -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2
  int _compareVersions(String v1, String v2) {
    final List<int> parts1 = v1.split('.').map(int.parse).toList();
    final List<int> parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < parts1.length || i < parts2.length; i++) {
      final int p1 = (i < parts1.length) ? parts1[i] : 0;
      final int p2 = (i < parts2.length) ? parts2[i] : 0;

      if (p1 < p2) return -1; // v1 es menor que v2
      if (p1 > p2) return 1;  // v1 es mayor que v2
    }
    return 0; // Las versiones son iguales
  }

  // Función para verificar la versión de la aplicación
  Future<void> _checkAppVersion(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentAppVersion = packageInfo.version;
      debugPrint('Versión actual de la aplicación: $currentAppVersion');

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_versions')
          .select('latest_version, min_supported_version')
          .order('updated_at', ascending: false) // Obtener la versión más reciente
          .limit(1)
          .single();

      final String latestVersion = response['latest_version'] as String;
      final String minSupportedVersion = response['min_supported_version'] as String;

      debugPrint('Última versión disponible: $latestVersion');
      debugPrint('Versión mínima soportada: $minSupportedVersion');

      final int compareToLatest = _compareVersions(currentAppVersion, latestVersion);
      final int compareToMinSupported = _compareVersions(currentAppVersion, minSupportedVersion);

      if (compareToMinSupported < 0) {
        // La versión actual es menor que la mínima soportada (actualización obligatoria)
        _showUpdateDialog(
          context,
          'Actualización Obligatoria',
          'Tu versión de la aplicación ($currentAppVersion) está desactualizada y ya no es compatible. Por favor, actualiza a la versión $latestVersion o superior para continuar.',
          isCritical: true,
        );
      } else if (compareToLatest < 0) {
        // Hay una nueva versión disponible (actualización recomendada)
        _showUpdateDialog(
          context,
          'Actualización Disponible',
          'Hay una nueva versión de la aplicación ($latestVersion) disponible. Estás usando la versión $currentAppVersion. ¡Actualiza para disfrutar de las últimas mejoras!',
          isCritical: false,
        );
      } else {
        debugPrint('La aplicación está actualizada o por encima de la versión mínima.');
      }
    } catch (e) {
      debugPrint('Error al verificar la versión de la aplicación: $e');
      // Puedes optar por no mostrar un diálogo al usuario en caso de error de verificación,
      // o mostrar uno genérico si es crítico para el funcionamiento.
    }
  }

  // Muestra un diálogo de actualización
  void _showUpdateDialog(BuildContext context, String title, String message, {required bool isCritical}) {
    showDialog(
      context: context,
      barrierDismissible: !isCritical, // Si es crítica, no se puede cerrar tocando fuera
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            if (!isCritical)
              TextButton(
                child: const Text('Más Tarde'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cierra el diálogo
                },
              ),
            TextButton(
              child: const Text('Actualizar Ahora'),
              onPressed: () {
                // TODO: Implementar la lógica para redirigir al usuario a la tienda de aplicaciones
                // Por ejemplo, usando el paquete 'url_launcher'
                debugPrint('Redirigir a la tienda de aplicaciones para actualizar.');
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinder',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: widget.initialRoute,
      routes: {
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
  late Future<Widget> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _determineDashboard();
  }

  Future<String> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String? ?? 'User';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'User';
    }
  }

  Widget _getDashboardByRole(String role) {
    switch (role) {
      case 'Administrador':
        return const DashboardAdmin();
      case 'Conductor':
        return const DashboardDriver();
      case 'Cliente':
      case 'Usuario':
      default:
        return const DashboardClient();
    }
  }

  Future<Widget> _determineDashboard() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return Container();
      }

      final userId = session.user.id;
      final role = await _getUserRole(userId);
      return _getDashboardByRole(role);
    } catch (e) {
      print('Error determining dashboard: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          print('FutureBuilder error: ${snapshot.error}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const SizedBox.shrink();
        } else if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const SizedBox.shrink();
        }
      },
    );
  }
}
