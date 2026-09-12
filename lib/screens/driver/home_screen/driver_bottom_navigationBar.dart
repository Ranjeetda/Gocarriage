import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../../eventModel/notification_event.dart';
import '../../../provider_service/status_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../../commanScreen/menu_screen.dart';
import '../../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../SocketService/driver_socket_service.dart';
import '../my_rides_screen/driver_booking_history_screen.dart';
import 'driver_home_screen.dart';

class DriverBottomNavigationbar extends StatefulWidget {
  @override
  _DriverBottomNavigationbarState createState() =>
      _DriverBottomNavigationbarState();
}

class _DriverBottomNavigationbarState extends State<DriverBottomNavigationbar> {
  int _selectedIndex = 0;
  bool isGettingLocation = false;
  bool isSwitch = false;

  String mLocation = "";
  String? latitude;
  String? longitude;

  Timer? locationTimer;

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    DriverBookingHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();

    isSwitch = PrefUtils.isDriverOnline();

    Future.delayed(const Duration(milliseconds: 300), () {
      _setCurrentLocation();
    });

    eventBus.on<NotificationEvent>().listen((event) {
      if (event.message.data['type'] == 'TRIP_COMPLETED') {
        if (!mounted) return;
        Utils.showSuccessDialog(context, event.message.data['bookingId']);
      }
    });
  }

  void startSocketLocationUpdates(Position position) {
    locationTimer?.cancel();

    locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (DriverSocketService().isConnected) {
        DriverSocketService().updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: header(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        Image.asset(ImagePaths.marker, height: 20, width: 20),
                        const SizedBox(width: 6),
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
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isSwitch,
                        onChanged: (v) {
                          showStartDialog(context, v);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF00C853),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.30),
                        trackOutlineColor:
                        WidgetStateProperty.resolveWith((states) {
                          return Colors.transparent;
                        }),
                        thumbIcon: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(Icons.check,
                                size: 16, color: Color(0xFF00C853));
                          }
                          return const Icon(Icons.close,
                              size: 16, color: Colors.grey);
                        }),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.house, color: Colors.white),
                      onPressed: () {
                        PrefUtils.clearPreferences();
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageTransition(
                            child: CustomerBottomNavigationBar(),
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 900),
                            reverseDuration:
                            const Duration(milliseconds: 900),
                          ),
                              (Route<dynamic> route) => false,
                        );
                      },
                    ),
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

      if (mounted) {
        setState(() {
          mLocation = address;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          mLocation = "Unable to get location";
        });
      }
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
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {}

    return "Unknown location";
  }

  /// STATUS UPDATE API (NO Navigator.pop here!)
  Future<bool> _statusUpdate(bool isOnline, String lat, String lng) async {
    try {
      final response = await Provider.of<StatusProvider>(context, listen: false)
          .statusUpdate(isOnline, lat, lng);

      final data = json.decode(response.body);

      if (data['success'] == true) {
        PrefUtils.setDriverOnline(isOnline);

        if (mounted) {
          setState(() {
            isSwitch = isOnline;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Status updated successfully"),
            backgroundColor: isOnline ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return true;
      } else {
        Utils.showErrorMessage(
            context, data['message'] ?? "Failed to update status");
        return false;
      }
    } catch (e) {
      Utils.showErrorMessage(
          context, "Something went wrong. Please try again.");
      return false;
    }
  }

  /// DIALOG
  void showStartDialog(BuildContext context, bool desiredOnline) {
    final bool goingOnline = desiredOnline;
    bool isDialogLoading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Online Offline Dialog",
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: goingOnline
                                    ? [
                                  const Color(0xFF00C853),
                                  const Color(0xFF00E676)
                                ]
                                    : [
                                  const Color(0xFFFF5252),
                                  const Color(0xFFFF1744)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 72,
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    goingOnline
                                        ? Icons.wifi_tethering_rounded
                                        : Icons.wifi_off_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  goingOnline ? "Go Online" : "Go Offline",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 10),
                            child: Column(
                              children: [
                                Text(
                                  goingOnline
                                      ? "You will start receiving new booking requests."
                                      : "You will stop receiving new booking requests.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    height: 1.45,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  goingOnline
                                      ? "Make sure your location is accurate."
                                      : "You can go online again anytime.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Buttons / Loading
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            child: isDialogLoading
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.2,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00C853),
                                  ),
                                ),
                              ),
                            )
                                : Row(
                              children: [
                                // Cancel
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Confirm
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setDialogState(() {
                                        isDialogLoading = true;
                                      });

                                      final bool success =
                                      await _statusUpdate(
                                        desiredOnline,
                                        latitude ?? "",
                                        longitude ?? "",
                                      );

                                      if (!context.mounted) return;

                                      if (success) {
                                        // ===== SOCKET HANDLING =====
                                        if (desiredOnline) {
                                          final int driverId = int.parse(
                                              PrefUtils.getUserId());

                                          DriverSocketService().connect(
                                              driverId: driverId);
                                          debugPrint(
                                              '🟢 Socket connected after going Online');
                                        } else {
                                          DriverSocketService()
                                              .disconnect();
                                          debugPrint(
                                              '🔴 Socket disconnected after going Offline');
                                        }

                                        // Close dialog ONLY here
                                        Navigator.pop(context);
                                      } else {
                                        setDialogState(() {
                                          isDialogLoading = false;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: goingOnline
                                          ? const Color(0xFF00C853)
                                          : const Color(0xFFFF5252),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      goingOnline
                                          ? "Go Online"
                                          : "Go Offline",
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }
}