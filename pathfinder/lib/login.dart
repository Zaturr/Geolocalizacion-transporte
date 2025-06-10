import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register.dart';
import 'dashboard_client.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';

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

  @override
  void initState() {
    super.initState();
    _verificarSesionExistente();
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
        setState(() => _verificandoSesion = false);
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
          _mostrarError('Error de inicio de sesión, verifica tus credenciales');
        }
      } catch (e) {
        _mostrarError('Error: $e');
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: SingleChildScrollView(
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
                    'assets/LogoW.png',
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
                // Campo de email
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
                // Campo de contraseña
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
                  obscureText: true, // Texto oculto para contraseña
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Botón de inicio de sesión
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
                // Enlace a registro
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}