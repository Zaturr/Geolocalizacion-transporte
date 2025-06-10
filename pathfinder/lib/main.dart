import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'login.dart';
import 'dashboard_client.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';

import 'splash.dart';
import 'themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');//se intenta cargar las apikeys del archivo.env

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,           //url repo supabase
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,  //key supabase
    );

    // chequeo de sesion existente
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      //si la session existe, navega directamente al dashboard correspondiente
      runApp(const MyApp(initialRoute: '/dashboard'));
    } else {
      // si no se encuentra la session se muestra la pagina de splash
      runApp(const MyApp(initialRoute: '/splash'));
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

  const MyApp({super.key, this.initialRoute = '/splash'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinder',
      theme: lightTheme,          //tema claro
      darkTheme: darkTheme,       //tema oscuro
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {//rutas relativas de archivos
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardWrapper(),
      },
      debugShowCheckedModeBanner: false,//deshabilita el banner de debug
    );
  }
}

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}
//clase futura que resuelve el dashboard correspondiente a las credenciales del
//usuario, si no se consigue una sesion valida se redirecciona a login.dart
class _DashboardWrapperState extends State<DashboardWrapper> {
  late Future<Widget> _dashboardFuture;

  Future<String> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String? ?? 'User';
    } catch (e) {
      return 'User';
    }
  }
//trigger si la session si es valida
  Widget _getDashboardByRole(String role) {
    switch (role) {
      case 'Administrator':
        return const DashboardAdmin();
      case 'Driver':
        return const DashboardDriver();
      case 'User':
      default:
        return const DashboardClient();
    }
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _determineDashboard();
  }

  Future<Widget> _determineDashboard() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        return const LoginScreen();
      }

      final userId = session.user.id;
      final role = await _getUserRole(userId);
      return _getDashboardByRole(role);
    } catch (e) {
      // si ocurre algun error se redirecciona hacia login.dart
      return const LoginScreen();
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
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}