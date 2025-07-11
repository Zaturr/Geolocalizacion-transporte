import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        // Muestra la imagen desde la ruta proporcionada con tamaño ajustado y bordes redondeados.
        ClipRRect( // ClipRRect se usa para redondear los bordes de la imagen.
          borderRadius: BorderRadius.circular(20.0), // Radio para los bordes redondeados.
          child: Image.asset(
            imagePath,
            height: 220, // Reduced height to prevent overflow.
            width: 220, // Reduced width to prevent overflow.
            fit: BoxFit.cover, // Ensures the image covers the space without distorting.
          ),
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
        const SizedBox(height: 20),
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

// Nuevo widget para el panel de bienvenida deslizante.
class WelcomePanel extends StatefulWidget {
  final PageController pageController;
  final int currentPage;
  final double panelHeight;
  final bool isDarkMode;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onWelcomeComplete;

  const WelcomePanel({
    super.key,
    required this.pageController,
    required this.currentPage,
    required this.panelHeight,
    required this.isDarkMode,
    required this.onPageChanged,
    required this.onWelcomeComplete,
  });

  @override
  State<WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel> {
  // Widget para construir los puntos indicadores de página.
  Widget _buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: widget.currentPage == index ? 25 : 10, // Más ancho si es la página actual.
      decoration: BoxDecoration(
        // Usa el color primario del esquema de Material Design para el punto activo.
        color: widget.currentPage == index ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500), // Duración de la animación.
      curve: Curves.easeInOut, // Curva de la animación.
      left: 0,
      right: 0,
      bottom: 0,
      // La altura del panel se controla con panelHeight.
      height: widget.panelHeight,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Usa el color de superficie del esquema de Material Design para adaptarse al tema.
          color: Theme.of(context).colorScheme.secondaryContainer,
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
                controller: widget.pageController,
                onPageChanged: widget.onPageChanged,
                children: [
                  // Primera página de bienvenida con imagen adaptable al tema.
                  WelcomePage(
                    title: 'Explora Rutas',
                    description: 'Descubre las mejores rutas para tus viajes y llega a tu destino sin complicaciones.',
                    // Elige la imagen según el tema actual.
                    imagePath: 'assets/bus_1.jpg',
                  ),
                  // Segunda página de bienvenida con imagen adaptable al tema.
                  WelcomePage(
                    title: 'Gestión de Envíos',
                    description: 'Administra tus paquetes y sigue su progreso en tiempo real, desde el origen hasta la entrega.',
                    // Elige la imagen según el tema actual.
                    imagePath:'assets/map_1.jpg',
                  ),
                  // Tercera página de bienvenida con imagen adaptable al tema.
                  WelcomePage(
                    title: 'Conecta con Conductores',
                    description: 'Encuentra conductores disponibles y coordina tus viajes de manera eficiente.',
                    // Elige la imagen según el tema actual.
                    imagePath:'assets/bus_2.jpg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Indicadores de página (los puntos en la parte inferior).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDot(index, context)),
            ),
            const SizedBox(height: 20),
            // Botones de navegación.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón 'Anterior' (solo visible si no es la primera página).
                if (widget.currentPage > 0)
                  ElevatedButton(
                    onPressed: () {
                      widget.pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      // Usa los colores del esquema de Material Design.
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    if (widget.currentPage < 2) {
                      // Si no es la última página, avanza a la siguiente.
                      widget.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Si es la última página, marca como vista la bienvenida y oculta el panel.
                      widget.onWelcomeComplete();
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
                  child: Text(widget.currentPage == 2 ? 'Empezar' : 'Siguiente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}