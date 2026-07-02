import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:provider/provider.dart';

import '../../provider_service/check_area_provider.dart';
import '../auth/login_screen.dart';
import '../dialogBox/login_register_dialog.dart';

class SelectableScrollBox extends StatefulWidget {
  @override
  _SelectableScrollBoxState createState() => _SelectableScrollBoxState();
}

class _SelectableScrollBoxState extends State<SelectableScrollBox> {
  final TextEditingController searchClusterController = TextEditingController();

  final List<Map<String, dynamic>> items = [
    {"label": "Customer", "icon": Icons.person_outline},
    {"label": "Vehicle Owner", "icon": Icons.directions_car_outlined},
    {"label": "Driver", "icon": Icons.local_shipping_outlined},
    {"label": "Operator", "icon": Icons.headset_mic_outlined},
  ];

  int selectedIndex = 0;
  bool isGettingLocation = false;
  bool isLoading = false;
  String mLocation = "";
  String? fromLatitude;
  String? fromLongitude;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _setCurrentLocation());

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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 TOP HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// LEFT SIDE (Name + Location)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PrefUtils.getName().isEmpty ? 'Guest' : PrefUtils.getName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    mLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),

              /// RIGHT SIDE (Arrow + Notification)
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _showCenterDialog(context);
                    },
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),

                  const SizedBox(width: 8),

                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔹 ROLE SELECTOR
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () async {
                    if (items[index]["label"] == 'Customer') {
                      PrefUtils.setRole('customer');
                    } else if (items[index]["label"] == 'Vehicle Owner') {
                      PrefUtils.setRole('owner');
                    } else if (items[index]["label"] == 'Driver') {
                      PrefUtils.setRole('driver');
                    } else if (items[index]["label"] == 'Operator') {
                      PrefUtils.setRole('operator');
                    }
                    selectedIndex = index;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    ); /*
                    final result = await showDialog(
                      context: context,
                      builder: (context) =>
                          LoginRegisterDialog(items[index]["label"]),
                    );


                    if (result == true) {
                      setState(() {
                        selectedIndex = index;
                      });
                    }
                    */
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          items[index]['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          items[index]['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= FUNCTIONS =================

  Future<void> _checkArea(String pinCode) async {
    setState(() => isLoading = true);

    try {
      final response = await Provider.of<CheckAreaProvider>(
        context,
        listen: false,
      ).checkArea(pinCode);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true && data['exists'] == true) {
          mLocation =
              "🟢 ${searchClusterController.text} ${data['cluster']['name']}";
        } else {
          mLocation = "🔴 ${searchClusterController.text} ${data['name']}";
        }
      }
    } catch (e) {
      debugPrint("CheckArea Error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _setCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      mLocation = "Fetching location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          mLocation = "Location services are disabled";
          isGettingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          mLocation = "Permission denied";
          isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          mLocation =
              "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      setState(() {
        mLocation = "Unable to get location";
      });
    }

    setState(() {
      isGettingLocation = false;
    });
  }

  void _showCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const Center(child: Text("Dialog Here")),
    );
  }
}
