import 'package:flutter/material.dart';


class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed; // Renamed for more generic use
  final String userName;
  final double topPadding;

  const TopBar({
    Key? key,
    required this.onMenuPressed, // Updated to new callback
    required this.userName,
    required this.topPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: topPadding + 10,
      ),
      height: preferredSize.height + 20,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only( // Changed to const for minor optimization
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuPressed, // Now calls the generic onMenuPressed
            child: CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            flex: 3,
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface, // Adjusted for consistency with surface background
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + topPadding + 10);
}