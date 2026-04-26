import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:provider/provider.dart';
import '../../eventModel/notification_event.dart';
import '../../provider_service/check_area_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import '../../resource/selectable_scroll_box.dart';
import '../dialogBox/login_register_dialog.dart';
import 'customer_home_screen.dart';
import 'history_screen.dart';
import '../commanScreen/menu_screen.dart';

class CustomerBottomNavigationBar extends StatefulWidget {
  @override
  _CustomerBottomNavigationBar createState() => _CustomerBottomNavigationBar();
}

class _CustomerBottomNavigationBar extends State<CustomerBottomNavigationBar> {
  final TextEditingController searchClusterController = TextEditingController();

  int _selectedIndex = 0;
  bool isGettingLocation = false;
  bool isLoading = false;
  String mLocation = "";
  String? fromLatitude;
  String? fromLongitude;

  final List<Widget> _screens = [
    CustomerHomeScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _setCurrentLocation());


    eventBus.on<NotificationEvent>().listen((event) {
      if (event.message.data['type'] == 'TRIP_COMPLETED') {
        if (!mounted) return;
        // Close previous dialog safely
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Show success dialog
        Utils.showSuccessDialog(context, event.message.data['bookingId']);
      }
    });
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

      /// 🔹 NORMAL BOTTOM NAVIGATION (LIKE SCREENSHOT)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
            _navigateTo(MenuScreen());
            return; // 🚀 IMPORTANT: stop index update
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Trips"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  /// 🔹 HEADER UI
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          /// TOP BAR
          SelectableScrollBox(),

          const SizedBox(height: 18),
          /// 🔹 FLOATING LOCATION CARD
          Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xffE3F2FD),
                  child: Icon(Icons.location_on, color: Color(0xff4F7CFF)),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PrefUtils.getName().isEmpty?'----':PrefUtils.getName(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () {
                    _showCenterDialog(context);
                  },
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 YOUR EXISTING FUNCTIONS (UNCHANGED BELOW)

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


  void _showCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(ImagePaths.appLogo, height: 80),

                        const SizedBox(height: 12),

                        const Text(
                          "Check Area Availability",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: searchClusterController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Enter pin code",
                            prefixIcon: const Icon(Icons.pin_drop),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.textBox,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.secondarycolor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondarycolor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (searchClusterController.text.length !=
                                          6) {
                                        Utils.showCustomToast(
                                          context,
                                          "Please enter 6 digit pinCode",
                                        );
                                        return;
                                      }

                                      setDialogState(() => isLoading = true);

                                      await _checkArea(
                                        searchClusterController.text,
                                      );

                                      setDialogState(() => isLoading = false);
                                    },
                            child:
                                isLoading
                                    ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      "Submit",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ❌ CLOSE ICON (TOP RIGHT)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        if (!isLoading) {
                          Navigator.pop(context);
                        }
                      },
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
}
