import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

import 'dashboard_admin_screen.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController(); // Nuevo controlador para el código de área
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _organizationNameController.dispose();
    _addressController.dispose();
    _areaCodeController.dispose(); // Disponer el nuevo controlador
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) {
      return; // Detener si el formulario no es válido
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser; // Obtener el usuario actual
    final userId = user?.id; // Obtener el ID del usuario actual
    final userEmail = user?.email; // Obtener el correo del usuario actual

    if (userId == null || userEmail == null) { // Verificar también que el correo del usuario exista
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado o correo no disponible.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // --- Verificación para el número de teléfono de contacto (separado por código de área y número) ---
    final String areaCodeInput = _areaCodeController.text.trim();
    final String phoneNumberInput = _phoneNumberController.text.trim();

    if (areaCodeInput.isNotEmpty || phoneNumberInput.isNotEmpty) {
      // Validar que ambos campos (si no están vacíos) tienen la cantidad de dígitos correcta
      if (areaCodeInput.length != 3) { // Solo se verifica la longitud
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El código de área debe ser de 3 dígitos.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (phoneNumberInput.length != 7) { // Solo se verifica la longitud
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El número de teléfono debe ser de 7 dígitos.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // --- Se eliminó la verificación de existencia del número en la tabla 'profiles' ---
      // La lógica anterior que consultaba la base de datos para verificar si el número
      // de teléfono ya existía en la tabla 'profiles' ha sido removida.
      // Ahora, si el formato es correcto, se procede con la creación de la organización.
    }
    // --- Fin de la nueva verificación del número de teléfono ---

    try {
      // 1. Insertar la nueva organización en la tabla 'organizations'
      // El número de teléfono completo se sigue guardando en organizations para el contacto de la organización
      final String fullPhoneNumber = phoneNumberInput.isNotEmpty ? '$areaCodeInput$phoneNumberInput' : '';

      final List<Map<String, dynamic>> organizationResponse = await supabase
          .from('organizations')
          .insert({
            'name': _organizationNameController.text.trim(),
            'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            'contact_email': userEmail, // Usar el correo del usuario autenticado
            'phone_number': fullPhoneNumber.isEmpty ? null : fullPhoneNumber, // Guardar el número completo
            'created_by': userId, // Vincular la organización al creador
          })
          .select(); // Solicitar el retorno de los datos insertados

      if (organizationResponse.isEmpty || organizationResponse.first['id'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener el ID de la organización creada.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final String organizationId = organizationResponse.first['id'] as String;

      // 2. Insertar una entrada en la tabla 'user_organizations' para vincular al creador
      await supabase.from('user_organizations').insert({
        'user_id': userId,
        'organization_id': organizationId,
        'role_in_organization': 'admin', // Asignar el rol de 'admin' al creador
      });

      // 3. Actualizar el rol del usuario a 'Admin' en la tabla 'profiles'
      await supabase.from('profiles').update({
        'role': 'Admin', // Asignar el rol de Admin
      }).eq('id', userId); // Donde el ID del perfil coincide con el ID del usuario

      // 4. Actualizar el número de teléfono del perfil del usuario creador
      //    Si se proporcionó un número de teléfono en el formulario de la organización,
      //    actualizar el perfil del usuario con este número.
      //    Esta operación sobrescribirá los valores existentes en 'area_code' y 'phone_number'
      //    en la tabla 'profiles' para el usuario actual.
      if (areaCodeInput.isNotEmpty && phoneNumberInput.isNotEmpty) {
        try {
          await supabase.from('profiles').update({
            'area_code': areaCodeInput,
            'phone_number': phoneNumberInput,
          }).eq('id', userId);
        } on PostgrestException catch (e) {
          debugPrint('Error al actualizar el número de teléfono del perfil: ${e.message}');
          // No detenemos el flujo principal aquí, ya que la organización ya fue creada
          // y el rol actualizado. Este es un paso adicional.
        } catch (e) {
          debugPrint('Error inesperado al actualizar el número de teléfono del perfil: $e');
        }
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organización creada exitosamente y tu rol ha sido actualizado a Admin!'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirigir al usuario a dashboard_admin.dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardAdmin()),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear organización o actualizar rol: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear una Organización'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear una organización permite Registrar vehículos y establecer rutas que tus usuarios podrán ver.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24.0),

              TextFormField(
                controller: _organizationNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Organización',
                  hintText: 'Ej: Mi Empresa S.A.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el nombre de la organización.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Ej: Av. Principal 123, Ciudad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16.0),

              // Campos para el código de área y el número de teléfono
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _areaCodeController,
                      keyboardType: TextInputType.phone,
                      maxLength: 3, // Longitud máxima para el código de área
                      decoration: InputDecoration(
                        labelText: 'Cód. Área',
                        hintText: 'Ej: 412',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 3) { // Solo se verifica la longitud
                            return '3 dígitos'; // Mensaje actualizado
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10.0), // Espacio entre los campos de código de área y número
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      maxLength: 7, // Longitud máxima para el número de teléfono
                      decoration: InputDecoration(
                        labelText: 'Número de Teléfono',
                        hintText: 'Ej: 1234567',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 7) { // Solo se verifica la longitud
                            return '7 dígitos'; // Mensaje actualizado
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),

              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _createOrganization,
                        icon: const Icon(Icons.add_business),
                        label: const Text('Crear Organización'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
