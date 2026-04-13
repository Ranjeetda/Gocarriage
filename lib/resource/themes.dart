import "package:flutter/material.dart";

import "app_colors.dart";

BoxDecoration listDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25.0),
    boxShadow: const [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 6.0,
      )
    ],
  );
}
BoxDecoration pageCardDecoration() {
  return const BoxDecoration(
    color: AppColors.primaryColor,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30.0),
      bottomRight: Radius.circular(30.0),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 6.0,
      )
    ],
  );
}
