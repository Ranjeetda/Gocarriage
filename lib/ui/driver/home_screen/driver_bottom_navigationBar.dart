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
  _DriverBottomNavigationbarState createState() => _DriverBottomNavigationbarState();
}

class _DriverBottomNavigationbarState extends State<DriverBottomNavigationbar> {
  final TextEditingController searchClusterController = TextEditingController();
  int _selectedIndex = 0;
  bool isGettingLocation = false;
  bool isLoading = false;
  bool isSwitch = false;
  String mLocation = "";

  String? latitude;
  String? longitude;
  Timer? locationTimer;

  final List<Widget> _screens = [
    DriverHomeScreen(),
    DriverBookingHistoryScreen(),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300), () {
      _setCurrentLocation();
    });
    setState(() {
      print("=========>${PrefUtils.isDriverOnline()}");
      if(PrefUtils.isDriverOnline()){
        isSwitch=true;
      }else{
        isSwitch=false;

      }
    });
    eventBus.on<NotificationEvent>().listen((event) {
      if (event.message.data['type'] == 'TRIP_COMPLETED') {
        if (!mounted) return;
        // Show success dialog
        Utils.showSuccessDialog(context, event.message.data['bookingId']);
      }
    });
  }

  void startSocketLocationUpdates(Position position) {
    DriverLocationUpdateSocketService().connectSocket(PrefUtils.getToken());
    locationTimer?.cancel(); // prevent duplicate timers

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



  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permission permanently denied. Enable it in settings.',
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: header(),
      ),

      body: _screens[_selectedIndex],

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
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  void showStartDialog(BuildContext context, bool isTrue) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevents tap outside to close (optional)
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(ImagePaths.appLogo, height: 120),
                        const SizedBox(height: 20),

                         Text(
                          isTrue?"Ready to Start?":"Duty OFF",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),

                        isTrue?const Text(
                          "You’re going to Turn on Online status.\n"
                              "You will be Receiving Booking Request",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ):Text(
                          "You’re going to Turn off Online status.\n"
                              "You will be not get Receive Booking Request",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            isTrue==false?Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  setStateDialog(() => isLoading = true);

                                  await _statusUpdate(
                                  false,
                                  latitude ?? "",
                                  longitude ?? "",
                                  );
                                  setStateDialog(() => isLoading = false);

                                },
                                child: isLoading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ): Text("Turn Off"),
                              ),
                            ):SizedBox(),
                            isTrue==false?const SizedBox(width: 12):SizedBox(),

                            isTrue?Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB50082),
                                ),
                                onPressed: () async {
                                  setStateDialog(() => isLoading = true);

                                  await _statusUpdate(
                                    true,
                                    latitude ?? "",
                                    longitude ?? "",
                                  );
                                  setStateDialog(() => isLoading = false);

                                },
                                child: isLoading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "Turn On",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ):SizedBox(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ❌ Close Icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Future<void> _statusUpdate(
      bool isOnline,
      String mLatitude,
      String mLongitude,
      ) async {

    http.Response response =
    await Provider.of<StatusProvider>(context, listen: false)
        .statusUpdate(isOnline, mLatitude, mLongitude);

    var data = json.decode(response.body);

    if (data['success'] == true) {
      if(data['message']=="Driver is now online and available for bookings"){
        PrefUtils.setDriverOnline(true);
        print("API IFFFF=========>${PrefUtils.isDriverOnline()}");

      }else if(data['message']=="Driver is now offline"){
        PrefUtils.setDriverOnline(false);
        print("API Else=========>${PrefUtils.isDriverOnline()}");


      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }
  Future<void> _setCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      mLocation = "Fetching location...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      setState(() {
        isGettingLocation = false;
        mLocation = "";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isGettingLocation = false;
          mLocation = "";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isGettingLocation = false;
        mLocation = "Permission denied permanently";
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
      startSocketLocationUpdates(position);
      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');
      final address = await _getAddressFromPosition(position);
      setState(() {
        mLocation = address;
      });
    } catch (e) {
      setState(() {
        mLocation = "Unable to get location";
      });
      debugPrint("Error getting location: $e");
    }
  }



  Future<String> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
    return "Unknown location";
  }

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
          Image.asset(ImagePaths.appLogoVertical, height: 50, width: 50),
          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Image.asset(ImagePaths.marker, height: 20, width: 20),
                          const SizedBox(width: 6),
                          Text(
                            _selectedIndex == 0
                                ? PrefUtils.getName().isNotEmpty
                                ? PrefUtils.getName()
                                : "Home"
                                : _selectedIndex == 1
                                ? "Past Booking"
                                : "Menu",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    Switch(
                      value: isSwitch,
                      onChanged: (v) {
                        setState(() => isSwitch = v);
                         showStartDialog(context,isSwitch);
                      },
                      activeColor: Colors.green,
                    ),

                    SizedBox(width: 5),

                    Stack(
                      alignment: Alignment.topRight,
                      children: const [
                        Icon(Icons.notifications_none_outlined,
                            size: 28, color: Colors.white),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),

                  ],
                ),

                Text(
                  mLocation,
                  style: TextStyle(color: Colors.white70),
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
}
