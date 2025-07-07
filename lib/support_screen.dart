import 'package:flutter/material.dart';
import 'gemini_chat_screen.dart'; // Import the chat screen
import 'package:url_launcher/url_launcher.dart'; // For launching URLs (email, phone)

class SupportScreen extends StatelessWidget {
  final String? userName;

  const SupportScreen({Key? key, this.userName}) : super(key: key);

  // Helper to launch URLs
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView for potential overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards horizontally
          children: [
            // --- AI Assistant Section (Moved to Top) ---
            Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              color: colorScheme.primary, // Make the AI section prominent
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    //Icon(Icons.robot, size: 48, color: colorScheme.onPrimary),
                    const SizedBox(height: 12),
                    Text(
                      'Asistente de IA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Obtén ayuda instantánea con nuestro asistente virtual.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GeminiChatScreen(userName: userName)),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Iniciar Chat con Asistente AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.onPrimary, // Button background contrasts with card
                        foregroundColor: colorScheme.primary,   // Text/icon color matches card background
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Frequently Asked Questions Section ---
            Text(
              'Preguntas Frecuentes (FAQ)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surfaceVariant,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.help_outline, color: colorScheme.primary),
                    title: Text(
                      'El mapa no carga o muestra errores.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      _showSolutionDialog(context, 'Solución para el Mapa',
                          'Asegúrate de tener una conexión a internet estable. Si el problema persiste, intenta reiniciar la aplicación o verifica los permisos de ubicación.');
                    },
                  ),
                  Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.login, color: colorScheme.primary),
                    title: Text(
                      'No puedo iniciar sesión.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      _showSolutionDialog(context, 'Solución para Inicio de Sesión',
                          'Verifica tu conexión a internet, tu nombre de usuario y contraseña. Si olvidaste tu contraseña, usa la opción "Olvidé mi contraseña" en la pantalla de inicio de sesión.');
                    },
                  ),
                  Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.route, color: colorScheme.primary),
                    title: Text(
                      'Problemas con la asignación de rutas.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      _showSolutionDialog(context, 'Solución para Rutas',
                          'Asegúrate de que tu perfil de conductor esté activo y tus credenciales actualizadas. Contacta a tu administrador si el problema persiste.');
                    },
                  ),
                  Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.payment, color: colorScheme.primary),
                    title: Text(
                      'Consultas sobre pagos y facturación.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      _showSolutionDialog(context, 'Solución para Pagos',
                          'Para consultas de pagos, por favor revisa la sección de "Historial de Pagos" en tu perfil o contacta a nuestro equipo de finanzas directamente.');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Contact Us Section ---
            Text(
              'Contáctanos Directamente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surfaceVariant,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email, color: colorScheme.secondary),
                    title: Text(
                      'Enviar un Correo Electrónico',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    subtitle: Text(
                      'soporte@pathfinder.com',
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                    onTap: () {
                      _launchUrl('mailto:soporte@pathfinder.com?subject=Soporte%20Pathfinder');
                    },
                  ),
                  Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.phone, color: colorScheme.secondary),
                    title: Text(
                      'Llamar a Soporte',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    subtitle: Text(
                      '+58 212 123 4567',
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                    onTap: () {
                      _launchUrl('tel:+582121234567');
                    },
                  ),
                  Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.web, color: colorScheme.secondary),
                    title: Text(
                      'Visita nuestro Sitio Web',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    subtitle: Text(
                      'www.pathfinder.com/ayuda',
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                    onTap: () {
                      _launchUrl('https://www.pathfinder.com/ayuda'); // Replace with your actual help URL
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Any other relevant information or disclaimers
            Text(
              'Nuestro equipo de soporte está disponible de Lunes a Viernes, de 9:00 AM a 5:00 PM (hora de Venezuela).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to show solution dialogs
  void _showSolutionDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(content, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}