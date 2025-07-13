import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Controlador para el PageView, que permite navegar entre las páginas de bienvenida.
  final PageController _pageController = PageController();
  // Índice de la página actual del PageView.
  int _currentPage = 0;
  // Altura del panel de bienvenida, utilizada para la animación de deslizamiento.
  double _panelHeight = 0.0; // Inicialmente oculto

  @override
  void initState() {
    super.initState();
    // Llama a la función para verificar si es la primera vez que se abre la aplicación.
    _checkFirstLaunch();
  }

  // Función asíncrona para verificar si la aplicación se ha lanzado antes.
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Obtiene el valor booleano de 'hasSeenWelcome'. Si no existe, por defecto es false.
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

    if (hasSeenWelcome) {
      // Si el usuario ya vio la bienvenida, navega directamente a la pantalla de inicio de sesión.
      // Usamos addPostFrameCallback para asegurar que la navegación ocurre después de que el widget se ha construido.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    } else {
      // Si es la primera vez, muestra el panel de bienvenida.
      // Retraso para que la pantalla de splash sea visible antes de que el panel aparezca.
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          // Anima el panel para que se deslice hacia arriba.
          _panelHeight = MediaQuery.of(context).size.height * 0.5; // Ajusta la altura según sea necesario
        });
      });
    }
  }

  // Función para marcar que el usuario ha completado la bienvenida.
  Future<void> _setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  @override
  void dispose() {
    _pageController.dispose(); // Libera los recursos del PageController.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determina si el tema actual es oscuro.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // El cuerpo del Scaffold es un Stack para superponer el fondo y el panel deslizante.
      body: Stack(
        children: [
          // Fondo de la pantalla de bienvenida.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // Usa colores del esquema de Material Design para el degradado.
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono o logo de tu aplicación.
                  // Puedes reemplazar esto con una imagen de tu logo si lo deseas.
                  Icon(
                    Icons.directions_bus, // Ejemplo de icono
                    size: 100,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido a Pathfinder',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu compañero de viaje inteligente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Panel deslizante de bienvenida.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500), // Duración de la animación.
            curve: Curves.easeInOut, // Curva de la animación.
            left: 0,
            right: 0,
            bottom: 0,
            // La altura del panel se controla con _panelHeight.
            height: _panelHeight,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Usa el color de superficie del esquema de Material Design.
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    // PageView para mostrar diferentes contenidos de bienvenida.
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index; // Actualiza el índice de la página actual.
                        });
                      },
                      children: [
                        // Primera página de bienvenida con imagen adaptable al tema.
                        WelcomePage(
                          title: 'Explora Rutas',
                          description: 'Descubre las mejores rutas para tus viajes y llega a tu destino sin complicaciones.',
                          // Elige la imagen según el tema actual.
                          imagePath: isDarkMode ? 'assets/images/map_dark.png' : 'assets/images/map_light.png',
                        ),
                        // Segunda página de bienvenida con imagen adaptable al tema.
                        WelcomePage(
                          title: 'Gestión de Envíos',
                          description: 'Administra tus paquetes y sigue su progreso en tiempo real, desde el origen hasta la entrega.',
                          // Elige la imagen según el tema actual.
                          imagePath: isDarkMode ? 'assets/images/shipping_dark.png' : 'assets/images/shipping_light.png',
                        ),
                        // Tercera página de bienvenida con imagen adaptable al tema.
                        WelcomePage(
                          title: 'Conecta con Conductores',
                          description: 'Encuentra conductores disponibles y coordina tus viajes de manera eficiente.',
                          // Elige la imagen según el tema actual.
                          imagePath: isDarkMode ? 'assets/images/driver_dark.png' : 'assets/images/driver_light.png',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Indicadores de página (los puntos en la parte inferior).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => buildDot(index, context)),
                  ),
                  const SizedBox(height: 20),
                  // Botones de navegación.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón 'Anterior' (solo visible si no es la primera página).
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            // Usa los colores del esquema de Material Design.
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Anterior'),
                        ),
                      const Spacer(), // Espacio flexible entre botones.
                      // Botón 'Siguiente' o 'Empezar'.
                      ElevatedButton(
                        onPressed: () async {
                          if (_currentPage < 2) {
                            // Si no es la última página, avanza a la siguiente.
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Si es la última página, marca como vista la bienvenida y navega a login.
                            await _setWelcomeSeen();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          // Usa el color primario del tema.
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Text(_currentPage == 2 ? 'Empezar' : 'Siguiente'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir los puntos indicadores de página.
  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: _currentPage == index ? 25 : 10, // Más ancho si es la página actual.
      decoration: BoxDecoration(
        // Usa el color primario del esquema de Material Design para el punto activo.
        color: _currentPage == index ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// Widget para representar cada página individual de bienvenida.
class WelcomePage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath; // Cambiado de IconData a String para la ruta de la imagen.

  const WelcomePage({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath, // Ahora requiere la ruta de la imagen.
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Muestra la imagen desde la ruta proporcionada.
        Image.asset(
          imagePath,
          height: 80, // Ajusta el tamaño de la imagen según sea necesario.
          width: 80,
          // Puedes añadir un colorFilter si quieres que la imagen se adapte al tema,
          // pero esto depende de la imagen y si es monocromática.
          // color: Theme.of(context).primaryColor, // Ejemplo de color si la imagen lo permite
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface, // Color de texto adaptable al tema.
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // Color de texto adaptable al tema.
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
