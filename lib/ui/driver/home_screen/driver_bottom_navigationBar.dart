import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../SocketService/driver_location_update_socket_service.dart';
import '../../../eventModel/notification_event.dart';
import '../../../provider_service/status_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../../commanScreen/menu_screen.dart';
import '../my_rides_screen/driver_booking_history_screen.dart';
import 'driver_home_screen.dart';
import 'package:http/http.dart' as http;

class DriverBottomNavigationbar extends StatefulWidget {
  @override
  _DriverBottomNavigationbarState createState() =>
      _DriverBottomNavigationbarState();
}

class _DriverBottomNavigationbarState
    extends State<DriverBottomNavigationbar> {
  final TextEditingController searchClusterController =
  TextEditingController();

  int _selectedIndex = 0;
  bool isGettingLocation = false;
  bool isLoading = false;
  bool isSwitch = false;

  String mLocation = "";
  String? latitude;
  String? longitude;

  Timer? locationTimer;

  /// ✅ Removed MenuScreen from here
  final List<Widget> _screens = [
    DriverHomeScreen(),
    DriverBookingHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      _setCurrentLocation();
    });

    isSwitch = PrefUtils.isDriverOnline();

    eventBus.on<NotificationEvent>().listen((event) {
      if (event.message.data['type'] == 'TRIP_COMPLETED') {
        if (!mounted) return;
        Utils.showSuccessDialog(
            context, event.message.data['bookingId']);
      }
    });
  }

  /// SOCKET LOCATION UPDATE
  void startSocketLocationUpdates(Position position) {
    DriverLocationUpdateSocketService()
        .connectSocket(PrefUtils.getToken());

    locationTimer?.cancel();

    locationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (timer) {
        DriverLocationUpdateSocketService().updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: header(),
      ),

      body: _screens[_selectedIndex],

      /// ✅ FIXED NAVIGATION
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60,
        backgroundColor: Colors.transparent,
        color: AppColors.primaryColor,
        buttonBackgroundColor: Colors.black,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.menu, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          if (index == 2) {
            /// 👉 OPEN MENU SCREEN
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
      ),
    );
  }

  /// HEADER
  Widget header() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 5,
        left: 20,
        bottom: 10,
      ),
      color: AppColors.primaryColor,
      child: Row(
        children: [
          Image.asset(ImagePaths.appLogoVertical,
              height: 50, width: 50),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        Image.asset(ImagePaths.marker,
                            height: 20, width: 20),
                        const SizedBox(width: 6),

                        /// ✅ FIXED TITLE LOGIC
                        Text(
                          _selectedIndex == 0
                              ? (PrefUtils.getName().isNotEmpty
                              ? PrefUtils.getName()
                              : "Home")
                              : "Past Booking",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Switch(
                      value: isSwitch,
                      onChanged: (v) {
                        setState(() => isSwitch = v);
                        showStartDialog(context, isSwitch);
                      },
                      activeColor: Colors.green,
                    ),

                    const SizedBox(width: 5),

                    const Icon(Icons.notifications_none_outlined,
                        size: 28, color: Colors.white),

                    const SizedBox(width: 8),
                  ],
                ),

                Text(
                  mLocation,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// LOCATION
  Future<void> _setCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      mLocation = "Fetching location...";
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude.toString();
      longitude = position.longitude.toString();

      startSocketLocationUpdates(position);

      final address = await _getAddressFromPosition(position);

      setState(() {
        mLocation = address;
      });
    } catch (e) {
      setState(() {
        mLocation = "Unable to get location";
      });
    }
  }

  Future<String> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {}

    return "Unknown location";
  }

  /// STATUS UPDATE API
  Future<void> _statusUpdate(
      bool isOnline,
      String lat,
      String lng) async {
    http.Response response =
    await Provider.of<StatusProvider>(context, listen: false)
        .statusUpdate(isOnline, lat, lng);

    var data = json.decode(response.body);

    if (data['success'] == true) {
      PrefUtils.setDriverOnline(isOnline);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  /// DIALOG
  void showStartDialog(BuildContext context, bool isTrue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isTrue ? "Go Online?" : "Go Offline?"),
        content: Text(isTrue
            ? "Start receiving bookings"
            : "Stop receiving bookings"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _statusUpdate(
                  isTrue, latitude ?? "", longitude ?? "");
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}