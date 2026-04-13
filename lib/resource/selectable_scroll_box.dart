import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/image_paths.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import '../ui/dialogBox/login_register_dialog.dart';

class SelectableScrollBox extends StatefulWidget {
  @override
  _SelectableScrollBoxState createState() => _SelectableScrollBoxState();
}

class _SelectableScrollBoxState extends State<SelectableScrollBox> {
  // ✅ Supports both IconData and image paths
  final List<Map<String, dynamic>> items = [
    {"title": "Customer", "icon": ImagePaths.appLogoVertical}, // String (image)
    {"title": "Vehicle Owner", "icon": Icons.directions_car}, // IconData
    {"title": "Driver", "icon": Icons.drive_eta},
    {"title": "Operator", "icon": Icons.support_agent},
   /* {"title": "Fuel Station", "icon": Icons.local_gas_station},
    {"title": "Restaurant", "icon": Icons.restaurant},
    {"title": "Service", "icon": Icons.build},*/
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    String role = PrefUtils.getRole().toLowerCase();

    if (role == 'owner') {
      selectedIndex = 1;
    } else if (role == 'driver') {
      selectedIndex = 2;
    } else if (role == 'operator') {
      selectedIndex = 3;
    } else {
      selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder:
                    (context) => LoginRegisterDialog(items[index]["title"]),
              );

              if (result == true) {
                setState(() {
                  selectedIndex = index;
                });
              }
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(items[index]["icon"], isSelected),
                  const SizedBox(height: 6),
                  Text(
                    items[index]["title"],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Reusable method to render icon properly
  Widget _buildIcon(dynamic icon, bool isSelected) {
    if (icon is IconData) {
      return Icon(
        icon,
        size: 40,
        color: isSelected ? Colors.blue : Colors.white,
      );
    } else if (icon is String) {
      return Image.asset(icon, width: 40, height: 40);
    } else {
      return const SizedBox();
    }
  }
}
