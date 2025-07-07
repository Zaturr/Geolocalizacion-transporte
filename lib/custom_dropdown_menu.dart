import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatefulWidget {
  final VoidCallback onCloseMenu;
  final List<Widget> menuItems; // A list of arbitrary widgets for the menu content
  final double topPosition; // Position is mainly for the root Positioned widget, but kept for consistency

  const CustomDropdownMenu({
    Key? key,
    required this.onCloseMenu,
    required this.menuItems,
    this.topPosition = 0, // Made optional as Overlay will handle positioning when used with LayerLink
  }) : super(key: key);

  @override
  State<CustomDropdownMenu> createState() => _CustomDropdownMenuState();
}

class _CustomDropdownMenuState extends State<CustomDropdownMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper to run action and then close the menu
  Future<void> _closeMenuWithAnimation() async {
    await _controller.reverse();
    widget.onCloseMenu();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget menuContent = SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: Material( // Wrap with Material to ensure shadows and ink splashes work correctly
        color: Colors.transparent, // Make Material transparent
        borderRadius: const BorderRadius.all(Radius.circular(15.0)), // Uniform rounded corners
        elevation: 4, // Control elevation for shadow directly on Material
        shadowColor: colorScheme.shadow.withOpacity(0.3), // Apply theme-aware shadow
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface, // Same as before
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Render the dynamic menu items passed from the parent
              ...widget.menuItems,
            ],
          ),
        ),
      ),
    );

    // If topPosition is provided (meaning it's the root Positioned), use it.
    // Otherwise, assume it's being positioned by an OverlayEntry's Positioned.
    if (widget.topPosition != 0) {
      return Positioned(
        top: widget.topPosition - 50, // Keep original position offset
        left: 0,
        child: GestureDetector(
          onTap: _closeMenuWithAnimation, // Tap outside closes
          behavior: HitTestBehavior.opaque,
          child: SizedBox( // Use SizedBox to limit tap area if width is full
            width: MediaQuery.of(context).size.width,
            child: menuContent,
          ),
        ),
      );
    } else {
      // When used in Overlay, the GestureDetector and width will be handled by the OverlayEntry
      return GestureDetector(
        onTap: _closeMenuWithAnimation,
        behavior: HitTestBehavior.translucent, // Allow tap-through if part of overlay backdrop
        child: menuContent,
      );
    }
  }
}