import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart'; // Import PostgrestException

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Attempt to sign up the user (this might also log in an existing user)
        final AuthResponse res = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (res.user == null) {
          throw Exception('Failed to create or find user during sign up.');
        }

        final User user = res.user!;

        // 2. Check if a profile already exists for this user ID
        final existingProfile = await Supabase.instance.client
            .from('profiles')
            .select('id') // Select just the ID to check for existence
            .eq('id', user.id)
            .maybeSingle();

        print('Username from controller: "${_usernameController.text.trim()}"');

        if (existingProfile == null) {
          // If no profile exists, create a new one
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'email': _emailController.text.trim(),
            'username': _usernameController.text.trim(),
            'role': 'User', // Default role
            'created_at': DateTime.now().toIso8601String(),
          });
          print('New profile created for user ${user.id}'); // Add this log
        } else {
          // If a profile already exists, UPDATE it with the new username
          print('Profile for user ${user.id} already exists. Attempting to update username.');
          await Supabase.instance.client.from('profiles').update({
            'username': _usernameController.text.trim(),
            // You might also update 'email' here if you want to sync it,
            // but usually email is handled by auth.updateUser()
            // 'email': _emailController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(), // It's good practice to update this
          }).eq('id', user.id);
          print('Profile updated for user ${user.id}'); // Add this log
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro/Inicio de Sesión Exitoso!')),
          );
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } on AuthException catch (e) {
        _showErrorDialog('Error de autenticación: ${e.message}');
      } on PostgrestException catch (e) {
        _showErrorDialog('Error de base de datos: ${e.message}');
      } catch (e) {
        _showErrorDialog('Error inesperado: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Registro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")), // Changed title for clarity
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
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Por favor introduce un Email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre de Usuario",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor introduce un nombre de usuario';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      "Registrar",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}