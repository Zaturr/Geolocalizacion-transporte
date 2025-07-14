// lib/widget/route_selector_bar.dart
import 'package:flutter/material.dart'hide Route;
import 'package:PathFinder/widget/custom_dropdown_menu.dart';
import 'package:PathFinder/models/map_models.dart'; // Import your Route model

// Define a simple data structure for your route options
class RouteOption {
  final String name;
  final VoidCallback onTap;
  final Route route; // NEW: Hold the full Route object

  RouteOption({required this.name, required this.onTap, required this.route});
}

class RouteSelectorBar extends StatefulWidget {
  final String currentRouteName;
  final List<RouteOption> routeOptions;
  final ValueChanged<RouteOption> onRouteSelected; // Callback when a route is selected

  const RouteSelectorBar({
    Key? key,
    required this.currentRouteName,
    required this.routeOptions,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  State<RouteSelectorBar> createState() => _RouteSelectorBarState();
}

class _RouteSelectorBarState extends State<RouteSelectorBar> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink(); // Used to link the overlay position to the button

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero); // Get global position of the bar

    // Build the list of menu items (ListTiles) specifically for routes
    final List<Widget> routeMenuItems = widget.routeOptions.map((option) {
      return ListTile(
        title: Text(
          option.name,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        onTap: () {
          _hideOverlay(); // Hide overlay first
          widget.onRouteSelected(option); // Then call the parent callback
        },
      );
    }).toList();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background GestureDetector to dismiss the overlay when tapped outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Position the dropdown menu relative to the RouteSelectorBar
          Positioned(
            left: offset.dx, // Align with the left edge of the bar
            top: offset.dy + size.height + 8.0, // Position slightly below the bar
            width: size.width, // Match the width of the bar
            child: CustomDropdownMenu( // Reusing your generic CustomDropdownMenu
              onCloseMenu: _hideOverlay,
              menuItems: routeMenuItems, // Pass the dynamically created ListTiles
              topPosition: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (_overlayEntry == null) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.currentRouteName,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }
}