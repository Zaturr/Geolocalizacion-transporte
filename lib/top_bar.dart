import 'package:flutter/material.dart';


class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed; // Renamed for more generic use
  final String userName;
  final double topPadding; // Este es el padding superior del sistema (ej. altura de la barra de estado)

  const TopBar({
    Key? key,
    required this.onMenuPressed, // Updated to new callback
    required this.userName,
    required this.topPadding,
  }) : super(key: key);

  // Definir constantes para el nuevo espaciado
  // Se han hecho públicas para que puedan ser accedidas desde otros archivos.
  static const double extraSpaceAboveBar = 20.0; // Espacio adicional encima de la barra
  static const double horizontalMargin = 20.0; // Margen desde los bordes izquierdo y derecho
  static const double internalVerticalPadding = 2.0; // Padding interno de la barra (arriba y abajo)

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding( // Padding exterior para márgenes y espacio superior adicional
      padding: EdgeInsets.only(
        left: horizontalMargin, // Usando la variable pública
        right: horizontalMargin, // Usando la variable pública
        // topPadding es el padding superior del sistema. Le añadimos el espacio extra.
        top: topPadding + extraSpaceAboveBar, // Usando la variable pública
      ),
      child: Container(
        // Padding interno del contenedor de la barra.
        padding: const EdgeInsets.symmetric(
          horizontal: 22.0, // Mantener el padding horizontal interno del usuario
          vertical: internalVerticalPadding, // Aplicar el padding vertical interno (usando la variable pública)
        ),
        // La altura del contenedor interno: altura base (kToolbarHeight) + padding vertical interno
        height: kToolbarHeight + (internalVerticalPadding * 2),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(25)), // Redondeo de 25 como lo pidió el usuario
         // boxShadow: [ // Sombra habilitada para dar más profundidad
           // BoxShadow(
             // color: Colors.black26,
              //blurRadius: 8, // Aumentado el blur para una sombra más suave
              //offset: const Offset(0, 4), // Desplazamiento para la sombra
            //),
          //],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onMenuPressed, // Ahora llama a la función genérica onMenuPressed
              child: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 20.0), // Espacio entre el avatar y el texto
            Expanded(
              flex: 3,
              child: Text(
                userName,
                style: TextStyle(
                  fontSize: 22.0, // Tamaño de fuente como lo pidió el usuario
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // Ajustado para consistencia con el fondo de la superficie
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            //const Spacer(flex: 1), // Espaciador flexible
          ],
        ),
      ),
    );
  }

  @override
  // Ajustamos el preferredSize para que coincida con la altura real del widget completo.
  // Incluye:
  // 1. El padding superior del sistema (barra de estado, notch) - `topPadding`
  // 2. El espacio *extra* que queremos encima de la barra - `extraSpaceAboveBar`
  // 3. La altura real de la barra redondeada (kToolbarHeight + padding vertical interno)
  Size get preferredSize => Size.fromHeight(
    topPadding + // Padding superior del sistema
    extraSpaceAboveBar + // Espacio adicional encima de la barra (usando la variable pública)
    kToolbarHeight + // Altura base para el contenido
    (internalVerticalPadding * 2) // Padding interno superior e inferior de la barra (usando la variable pública)
  );
}
