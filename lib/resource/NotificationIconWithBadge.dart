import 'package:flutter/material.dart';

import 'image_paths.dart';

class NotificationIconWithBadge extends StatelessWidget {
  final int notificationCount;

  const NotificationIconWithBadge({Key? key, required this.notificationCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const ImageIcon(
            AssetImage(ImagePaths.appLogo),
            size: 25.0,
            color: Colors.white,
          ),
          onPressed: () {
    /*        Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NotificationListScreen()),
            );*/
          },
        ),
        if (notificationCount > 0) // Only show badge if count > 0
          Positioned(
            right: 8, // Position badge on top-right
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                notificationCount > 99 ? '99+' : '$notificationCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
