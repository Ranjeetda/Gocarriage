import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/ui/operatorScreen/operator_booing_screen.dart';
import 'package:gocarriage_universal/ui/operatorScreen/vehicles_changes_screen.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import '../commanScreen/menu_screen.dart';
import 'operator_home_screen.dart';

class OperatorBottomNavigationbar extends StatefulWidget {
  @override
  _OperatorBottomNavigationbar createState() => _OperatorBottomNavigationbar();
}

class _OperatorBottomNavigationbar extends State<OperatorBottomNavigationbar> {

  int _selectedIndex = 0;
  bool isGettingLocation = false;
  bool isLoading = false;
  String mLocation = "";
  String? fromLatitude;
  String? fromLongitude;

  /// 🔹 Removed MenuScreen from here
  final List<Widget> _screens = [
    OperatorHomeScreen(),
    OperatorBooingScreen(),
    VehiclesChangesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _setCurrentLocation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F4F7),

      body: Stack(
        children: [
          /// 🔹 TOP GRADIENT BACKGROUND
          Container(
            height: 180,
            decoration: BoxDecoration(color: AppColors.primaryColor),
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔹 HEADER
                _buildHeader(),

                /// 🔹 BODY
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),

      /// 🔹 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) {
            /// 👉 Open MenuScreen instead of replacing body
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MenuScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.change_circle), label: "Vehicle Change"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }

  /// 🔹 HEADER UI
  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Image.asset(ImagePaths.appLogoVertical, height: 50, width: 50),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                PrefUtils.getName(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_none_outlined,
            size: 28,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  /// 🔹 LOCATION FUNCTION
  Future<void> _setCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      mLocation = "Fetching location...";
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      fromLatitude = position.latitude.toString();
      fromLongitude = position.longitude.toString();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        mLocation = "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      mLocation = "Unable to get location";
    }

    setState(() => isGettingLocation = false);
  }
}