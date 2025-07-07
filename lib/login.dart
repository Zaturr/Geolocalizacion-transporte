import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar shared_preferences

import 'register.dart';
import 'dashboard_client.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';
import 'welcome_panel.dart'; // Importar el nuevo widget

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _verificandoSesion = true; // Para verificar la sesión al inicio

  // --- Propiedades para la pantalla de bienvenida ---
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _panelHeight = 0.0; // Altura del panel de bienvenida, inicialmente oculto
  bool _showWelcomePanel = false; // Controla la visibilidad del panel de bienvenida
  // --- Fin de propiedades ---

  @override
  void initState() {
    super.initState();
    _initializeAppFlow(); // Llama a la nueva función de inicialización combinada
  }

  // Función combinada para verificar sesión y mostrar bienvenida si es necesario
  Future<void> _initializeAppFlow() async {
    // Primero, verificar si hay una sesión existente
    await _verificarSesionExistente();

    // Si _verificandoSesion es true, significa que _verificarSesionExistente
    // ya navegó a otra pantalla o está en proceso, así que no continuamos.
    if (!mounted || _verificandoSesion) {
      return;
    }

    // Si no hay sesión, entonces verificar si el usuario ya vio la pantalla de bienvenida
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

    if (!hasSeenWelcome) {
      setState(() {
        _showWelcomePanel = true; // Mostrar el panel de bienvenida
      });
      // Animar el panel para que se deslice hacia arriba después de un breve retraso
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _panelHeight = MediaQuery.of(context).size.height * 0.5; // Ajusta la altura según sea necesario
          });
        }
      });
    }
    // Si hasSeenWelcome es true, _showWelcomePanel permanece false, y el formulario de login se muestra por defecto.
  }

  // Verifica si hay una sesión activa al iniciar
  Future<void> _verificarSesionExistente() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final userId = session.user.id;
        final role = await _obtenerRolUsuario(userId);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _obtenerDashboardPorRol(role),
            ),
          );
        }
      }
    } catch (e) {
      // Si hay error al verificar la sesión, mostrar login normal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar sesión: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verificandoSesion = false); // Finaliza la verificación
      }
    }
  }

  // Obtiene el rol del usuario desde Supabase
  Future<String> _obtenerRolUsuario(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String? ?? 'Usuario'; // Rol por defecto
    } catch (e) {
      return 'Usuario';
    }
  }

  // Devuelve el dashboard correspondiente al rol
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

  // Maneja el proceso de login
  Future<void> _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (res.session != null) {
          final userId = res.user!.id;
          final rol = await _obtenerRolUsuario(userId);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => _obtenerDashboardPorRol(rol),
              ),
            );
          }
        } else {
          // Este bloque se ejecuta si la sesión es nula, lo que a menudo indica credenciales inválidas
          _mostrarError('Credenciales Invalidas. Por favor verifique sus datos!');
        }
      } catch (e) {
        // Manejo de errores específicos de Supabase AuthException
        if (e is AuthException) {
          // Supabase AuthException puede contener un statusCode.
          // Un statusCode '400' o un mensaje que indique credenciales inválidas.
          if (e.statusCode == '400' || e.message.contains('Invalid login credentials') || e.message.contains('invalid_grant')) {
            _mostrarError('Credenciales Invalidas. Por favor verifique sus datos!');
          } else {
            _mostrarError('Error de autenticación: ${e.message}');
          }
        } else {
          // Cualquier otro tipo de error inesperado
          _mostrarError('Error inesperado: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  // Función para marcar que el usuario ha completado la bienvenida.
  Future<void> _setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    setState(() {
      _showWelcomePanel = false; // Oculta el panel de bienvenida
      _panelHeight = 0.0; // Anima el panel hacia abajo
    });
  }

  // Función para mostrar el panel de bienvenida de nuevo
  void _showWelcomePanelAgain() {
    setState(() {
      _showWelcomePanel = true;
      _panelHeight = MediaQuery.of(context).size.height * 0.5; // Restablece la altura del panel
      _currentPage = 0; // Opcional: Reinicia a la primera página de bienvenida
    });
    // Retrasar la llamada a jumpToPage para asegurar que el PageView esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) { // Verificar si el controlador tiene clientes adjuntos
        _pageController.jumpToPage(0); // Asegura que el PageView salte a la primera página
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose(); // Disponer el controlador de página
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Muestra carga mientras verifica la sesión
    if (_verificandoSesion) {
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
          // Contenido principal del formulario de Login
          Positioned.fill( // <-- Se añadió Positioned.fill aquí
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: Image.asset(
                          // Cambia la imagen del logo según el tema
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
                        controller: _emailController,
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
                        controller: _passwordController,
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
                        onPressed: _isLoading ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
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
                      const SizedBox(height: 15), // Espacio adicional para el nuevo botón
                      // Nuevo botón para mostrar la bienvenida de nuevo
                      TextButton(
                        onPressed: _showWelcomePanelAgain,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.tertiary, // Un color diferente para destacarlo
                        ),
                        child: const Text("Mostrar Bienvenida"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Panel de Bienvenida (mostrado condicionalmente)
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
              onWelcomeComplete: _setWelcomeSeen,
            ),
        ],
      ),
    );
  }
}
