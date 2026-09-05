import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/cluster_check_provider.dart';
import 'package:gocarriage_universal/resource/image_paths.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/screens/dashboardScreen/vehicle_selection_sheet.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:provider/provider.dart';
import '../../provider_service/URLS.dart';
import '../../provider_service/booking_trip.dart';
import '../../provider_service/bottom_navigation_provider.dart';
import '../../provider_service/check_area_provider.dart';
import '../../provider_service/distance_provider.dart';
import '../../provider_service/driver_booing_request_provider.dart';
import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/myrides_provider.dart';
import '../../provider_service/near_by_vehicle_provider.dart';
import '../../provider_service/place_details_provider.dart';
import '../../resource/Utils.dart';
import '../widgets/selectable_scroll_box.dart';
import '../auth/login_screen.dart';
import '../dialogBox/driver_bottom_sheet.dart';
import '../model/RecentLocation.dart';
import '../model/booking_trip_request.dart';
import '../model/location_modal.dart';
import '../model/special_requirements.dart';
import 'package:http/http.dart' as http;

import '../widgets/service_mode_selector.dart';
import '../widgets/status_dialog.dart';

class BookVehicleScreen extends StatefulWidget {
  const BookVehicleScreen({super.key});

  @override
  State<BookVehicleScreen> createState() => _BookVehicleScreenState();
}

class _BookVehicleScreenState extends State<BookVehicleScreen> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final searchClusterController = TextEditingController();
  final metrialController = TextEditingController();
  final weightController = TextEditingController();

  bool isWithinCity = true;
  bool isBookingType = true;
  bool isGettingLocation = false;
  bool isLoading = false;
  bool isBookingLoading = false;
  bool sameCluster = false;
  bool isShow = false;
  String? fromLatitude;
  String? fromLongitude;

  String? toLatitude;
  String? toLongitude;

  String bookingMode = "NOW";
  String clusterId = "";
  String distance = "";
  String mDistance = "";
  String mDuration = "";
  String vehicleType = "";
  String weightUnit = "";
  String mfromLable = "";
  String mtoLable = "";
  String? mPrice;
  String selectedRole = 'Customer';
  String mButtonName = 'Find City Vehicles';

  String mLocation = "";
  String? mPincode1;
  String? mPincode2;
  BookingTripRequest? globalBookingRequest;
  Map<String, dynamic>? nearbyData;
  Map<String, dynamic>? fareData;

  String? selectedRequirement;
  final Map<String, bool> specialRequirements = {
    "Container": false,
    "Extra Length": false,
    "Covered": false,
    "Hydraulic": false,
    "Extra Large": false,
  };
  String selectedUnit = "KG";
  final List<String> units = ["KG", "TON", "GM"];

  int currentPage = 1;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    localData();
    if (PrefUtils.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bookingAllRideService(page: currentPage);
      });
    }
  }

  Future<void> _bookingAllRideService({
    int page = 1,
    bool isRefresh = false,
  }) async {
    if (isRefresh) currentPage = 1;
    try {
      await Provider.of<MyridesProvider>(context, listen: false).validateList(
        endpoint: URLS.bookingAllRide,
        page: currentPage,
        limit: limit,
        append: !isRefresh && page > 1,
      );
    } catch (error) {
      showStatusDialog(
        context,
        type: StatusType.error,
        title: 'Something went wrong!',
        message: error.toString(),
        primaryLabel: 'Recent booking failed',
        onPrimary: () => Navigator.of(context).pop(),
      );
    }
  }

  void showWaitingForDriver() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DriverBottomSheet();
      },
    );
  }

  Future<void> localData() async {
    globalBookingRequest = await PrefUtils.getBookingRequest();

    if (globalBookingRequest != null) {
      fromController.text = globalBookingRequest!.fromLocation.address;
      toController.text = globalBookingRequest!.toLocation.address;
      vehicleType = globalBookingRequest!.vehicleType;
      weightUnit = globalBookingRequest!.weightUnit;
      toLatitude = globalBookingRequest!.toLocation.lat.toString();
      toLongitude = globalBookingRequest!.toLocation.lng.toString();
      fromLatitude = globalBookingRequest!.fromLocation.lat.toString();
      fromLongitude = globalBookingRequest!.fromLocation.lng.toString();
      mPincode1 = PrefUtils.getpinCode1();
      mPincode2 = PrefUtils.getpinCode2();
      _checkCluster(PrefUtils.getpinCode1(), PrefUtils.getpinCode2());
      _checkDistance(PrefUtils.getpinCode1(), PrefUtils.getpinCode2());
      print(globalBookingRequest!.weight);
    }
  }

  Future<void> _checkArea(String pinCode) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Provider.of<CheckAreaProvider>(
        context,
        listen: false,
      ).checkArea(pinCode);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        if (data['success'] == true && data['exists'] == true) {
          setState(() {
            mLocation = " 🟢 ${searchClusterController.text} ";
            mfromLable = "Service is available";
          });
        } else {
          setState(() {
            mLocation = " 🔴 ${searchClusterController.text} ";
            mfromLable = "Service is not available";
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        print("Exception${e.toString()}");
        isLoading = false;
      });
    }
  }

  Future<void> _checkCluster(String pinCode1, String pinCode2) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Provider.of<ClusterCheckProvider>(
        context,
        listen: false,
      ).clusterCheck(pinCode1, pinCode2);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        sameCluster = data['sameCluster'];
        isShow = true;
        if (sameCluster == true) {
          mtoLable = "Service is available";
          mfromLable = "Service is available";
          clusterId = data['cluster_id'].toString();
          nearByVehicleData(
            bookingMode,
            toLatitude.toString(),
            fromLongitude.toString(),
          );
        } else {
          mtoLable = "Service is not available";
          mfromLable = "Service is not available";
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print("_checkCluster ${data['message']}");
      }
    } catch (e) {
      print("Exception${e.toString()}");
      isLoading = false;
    }
  }

  Future<void> _checkDistance(String pinCode1, String pinCode2) async {
    try {
      final response = await Provider.of<DistanceProvider>(
        context,
        listen: false,
      ).fetchDistance(pinCode1, pinCode2);

      print("Distance calculate ============>${response.toString()}");
      distance =
          double.parse(response['distance']!.replaceAll(" km", "")).toString();
      mDistance = response['distance']!;
      mDuration = response['duration']!;
      print("distance ${distance}");
    } catch (e) {
      print("Exception${e.toString()}");
    }
  }

  Future<void> _bookingTripe(BookingTripRequest bookingRequest) async {
    setState(() {
      isBookingLoading = true;
    });

    http.Response response = await Provider.of<BookingTrip>(
      context,
      listen: false,
    ).bookingTrip(bookingRequest);
    var responseData = json.decode(response.body);
    setState(() {
      isBookingLoading = false;
    });

    if (responseData['success'] == true) {
      setState(() {
        fromController.text = "";
        toController.text = "";
        vehicleType = "";
        weightUnit = "";
        mtoLable = "";
        mfromLable = "";
        PrefUtils.setPinCode1("");
        PrefUtils.setPinCode2("");
        PrefUtils.clearBookingRequest();
      });
      showStatusDialog(
        context,
        type: StatusType.success,
        title: 'Success',
        message: responseData['message'],
        primaryLabel: 'Close',
        onPrimary: () => Navigator.of(context).pop(),
      );
    } else {
      setState(() {
        isBookingLoading = false;
      });
      showStatusDialog(
        context,
        type: StatusType.error,
        title: 'Something went wrong!',
        message: responseData['message'],
        primaryLabel: 'Booking failed',
        onPrimary: () => Navigator.of(context).pop(),
      );
    }
  }

  void nearByVehicleData(String bookingMode, String lat, String lng) async {
    final response = await Provider.of<NearByVehicleProvider>(
      context,
      listen: false,
    ).fetchNearByVehicle(bookingMode, lat, lng);

    nearbyData = response;
    List<int> vehicleTypeIds = List<int>.from(
      nearbyData?['data']['vehicleTypeIds'] ?? [],
    );
    fareCalculateData(clusterId, distance, vehicleTypeIds);
    print(response);
  }

  void fareCalculateData(
    String clusterId,
    String totalDistance,
    List<int> vehicleTypeIds,
  ) async {
    final response = await Provider.of<FareCalculateProvider>(
      context,
      listen: false,
    ).fetchFareCalculate(clusterId, totalDistance, vehicleTypeIds);
    fareData = response;
  }

  @override
  Widget build(BuildContext context) {
    context.read<DriverBooingRequestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // _buildTopRoleBar(),
            SelectableScrollBox(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBookingCard(),
                    const SizedBox(height: 16),
                    _buildBanner(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildWhyChooseUs(),
                    const SizedBox(height: 16),
                    Consumer<MyridesProvider>(
                      builder: (context, provider, _) {
                        final upcomingRides = provider.cureentRideListData;
                        return _buildRecentBookings(upcomingRides);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildNeedHelp(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOOKING CARD ─────────────────────────────────────────────────────────
  Widget _buildBookingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ServiceModeSelector(
              onChanged: (mode) {
                debugPrint('Selected: $mode');
                setState(() {
                  if (mode.toString().replaceAll('ServiceMode.', '') ==
                      'incity') {
                    mButtonName = 'Find City Vehicles';
                  } else if (mode.toString().replaceAll('ServiceMode.', '') ==
                      'outcity') {
                    mButtonName = 'Find OutCity Vehicles';
                  } else if (mode.toString().replaceAll('ServiceMode.', '') ==
                      'rental') {
                    mButtonName = 'Find Rentals';
                  } else if (mode.toString().replaceAll('ServiceMode.', '') ==
                      'international') {
                    mButtonName = 'Get International Quote';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            // Location fields
            _locationRow(),
            const SizedBox(height: 16),
            // Vehicle + Schedule row
            Row(
              children: [
                Expanded(child: _vehicleDropdownTile()),
                const SizedBox(width: 12),
                Expanded(child: _scheduleTile()),
              ],
            ),
            const SizedBox(height: 16),
            // Find Vehicles button
            _findVehiclesButton(),
          ],
        ),
      ),
    );
  }

  Widget _locationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon column
        Column(
          children: [
            const SizedBox(height: 14),
            const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 22),
            ...List.generate(
              5,
              (_) => Container(
                width: 2,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.grey.shade300,
              ),
            ),
            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 22),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _locationField(
                label: 'Pickup Location',
                controller: fromController,
                serviceLabel: mfromLable,
                onClear: () {
                  setState(() {
                    mfromLable = '';
                    mPincode1 = null;
                    fromController.clear();
                  });
                },
              ),
              const SizedBox(height: 10),
              _locationField(
                label: 'Drop Location',
                controller: toController,
                serviceLabel: mtoLable,
                onClear: () {
                  setState(() {
                    mtoLable = '';
                    mPincode2 = null;
                    toController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationField({
    required String label,
    required TextEditingController controller,
    required String serviceLabel,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, TextEditingValue value, child) {
            return GestureDetector(
              onTap:
                  () => _openLocationBottomSheet(
                    label == 'Pickup Location'
                        ? 'Pickup Location'
                        : 'Drop Location',
                    controller,
                  ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.text.isEmpty
                            ? 'Enter ${label.toLowerCase()}'
                            : value.text,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              value.text.isEmpty ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (value.text.isNotEmpty)
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      )
                    else
                      const Icon(
                        Icons.my_location,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (serviceLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: null,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.my_location,
                    size: 12,
                    color: const Color(0xFF2563EB),
                  ),
                  label: Text(
                    'Use Current',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  serviceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        serviceLabel == 'Service is available'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: null,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.my_location,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                  label: const Text(
                    'Use Current',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _vehicleDropdownTile() {
    return GestureDetector(
      onTap: () {
        if (sameCluster == true) {
          showVehicleBottomSheet(context, mPincode1!, mPincode2!);
        } else {
          Utils.showCustomToast(context, "Service is not available");
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 18,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select Vehicle Type',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  Text(
                    vehicleType.isNotEmpty ? vehicleType : 'Select Type',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleTile() {
    return GestureDetector(
      onTap: () async {
        setState(() {
          isWithinCity = false;
          bookingMode = "SCHEDULE";
        });
        await selectPickupDate();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Schedule (Optional)',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  Text(
                    pickupDateController.text.isNotEmpty
                        ? pickupDateController.text
                        : 'Select Date',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _findVehiclesButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (fromController.text.isEmpty) {
            Utils.showErrorMessage(context, 'Please search pickup location.');
            return;
          } else if (toController.text.isEmpty) {
            Utils.showErrorMessage(context, 'Please search drop location.');
            return;
          } else if (vehicleType == "") {
            Utils.showErrorMessage(context, 'Please select vehicle type.');
            return;
          }
          globalBookingRequest = BookingTripRequest(
            bookingMode: bookingMode,
            tripType: "Single",
            vehicleType: vehicleType!,
            fromLocation: LocationModal(
              address: fromController.text.trim(),
              lat: double.parse(fromLatitude!),
              lng: double.parse(fromLongitude!),
            ),
            toLocation: LocationModal(
              address: toController.text.trim(),
              lat: double.parse(toLatitude!),
              lng: double.parse(toLongitude!),
            ),
            materialName: "General",
            weight: double.parse(vehicleType),
            weightUnit: 'KG',
            customerId: int.parse(PrefUtils.getUserId()),
            specialRequirements: SpecialRequirements(
              container: false,
              extraLength: false,
              covered: false,
              hydraulic: false,
              extraLarge: false,
            ),
          );

          if (PrefUtils.isLoggedIn()) {
            showWaitingForDriver();
            _bookingTripe(globalBookingRequest!);
          } else {
            PrefUtils.saveBookingRequest(globalBookingRequest!);
            PrefUtils.setRole('customer');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        },
        child:
            isBookingLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  mButtonName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  // ─── BANNER ───────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Image.asset(ImagePaths.banner, fit: BoxFit.fill),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Quick Booking',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'My Bookings',
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFF0FDF4),
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Live Tracking',
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
      },
      {
        'icon': Icons.calculate_outlined,
        'label': 'Rate Calculator',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            actions.asMap().entries.map((entry) {
              final index = entry.key;
              final a = entry.value;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  switch (index) {
                    case 0:
                      print("Quick Booking Clicked");
                      // Navigator.push(...);
                      break;

                    case 1:
                      print("My Bookings Clicked");
                      context.read<BottomNavigationProvider>().changeIndex(1);

                      break;

                    case 2:
                      print("Live Tracking Clicked");
                      break;

                    case 3:
                      print("Rate Calculator Clicked");
                      break;
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: a['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── WHY CHOOSE US ────────────────────────────────────────────────────────
  Widget _buildWhyChooseUs() {
    final items = [
      {
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF2563EB),
        'title': 'Verified Vehicles',
        'sub': '100% Verified & Trusted',
      },
      {
        'icon': Icons.security_outlined,
        'color': const Color(0xFF16A34A),
        'title': 'Safe & Secure',
        'sub': 'Your Safety is Our Priority',
      },
      {
        'icon': Icons.wifi_tethering,
        'color': const Color(0xFFEA580C),
        'title': 'Live Tracking',
        'sub': 'Track in Real-time',
      },
      {
        'icon': Icons.local_offer_outlined,
        'color': const Color(0xFFDB2777),
        'title': 'Best Prices',
        'sub': 'Transparent Pricing',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Choose Us',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children:
                items.map((item) {
                  return Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item['sub'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── RECENT BOOKINGS ──────────────────────────────────────────────────────
  Widget _buildRecentBookings(List<dynamic> rides) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<BottomNavigationProvider>().changeIndex(2);
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
              /*  final result = Utils.convertMillisecondsToDateAndTime(
                  int.parse(rides[index]['default_booking_hour'].toString()),
                );

                String mDate = result['date'].toString();
                String mTime = result['time'].toString();*/

                return _recentBookingTile(
                  from: rides[index]['fromLocation']['address'],
                  to: rides[index]['toLocation']['address'],
                  date: '--',
                  time: '--',
                  status: rides[index]['status'],
                  price: "₹${rides[index]['estimated_price'] ?? '--'}",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentBookingTile({
    required String from,
    required String to,
    required String date,
    required String time,
    required String status,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFF2563EB),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                to,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              time,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const Text(
              'View Details',
              style: TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
            ),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
      ],
    );
  }

  // ─── NEED HELP ────────────────────────────────────────────────────────────
  Widget _buildNeedHelp() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Our support team is ready to assist you',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, size: 14),
            label: const Text(
              'Contact Support',
              style: TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCATION BOTTOM SHEET (unchanged logic) ─────────────────────────────
  void _openLocationBottomSheet(
    String label,
    TextEditingController controller,
  ) async {
    final TextEditingController searchController = TextEditingController(
      text: controller.text,
    );
    final FocusNode searchFocusNode = FocusNode();
    List<RecentLocation> recentLocations = await PrefUtils.getRecentLocations();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool showRecent =
                searchController.text.isEmpty && recentLocations.isNotEmpty;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!searchFocusNode.hasFocus && searchController.text.isEmpty) {
                searchFocusNode.requestFocus();
              }
            });

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            "Select $label",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              FocusScope.of(sheetContext).unfocus();
                              if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GooglePlaceAutoCompleteTextField(
                        textEditingController: searchController,
                        focusNode: searchFocusNode,
                        googleAPIKey: Utils.googleMapKey,
                        debounceTime: 600,
                        countries: const ["in"],
                        isLatLngRequired: false,
                        inputDecoration: InputDecoration(
                          hintText: "Search location",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        itemBuilder: (context, index, prediction) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.blueGrey,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    prediction.description ?? "",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        seperatedBuilder: const Divider(height: 1),
                        isCrossBtnShown: true,
                        itemClick: (prediction) async {
                          final selected = prediction.description ?? "";
                          controller.text = selected;
                          searchController.text = selected;
                          if (!mounted) return;
                          final provider = Provider.of<PlaceDetailsProvider>(
                            context,
                            listen: false,
                          );
                          await provider.fetchPlaceDetails(prediction.placeId!);
                          if (!mounted) return;
                          final details = provider.placeDetails;
                          if (details != null) {
                            await PrefUtils.addLocation(
                              location: selected,
                              postalCode: details.postalCode,
                              lat: details.lat,
                              lng: details.lng,
                            );
                            if (label == "Pickup Location") {
                              mPincode1 = details.postalCode;
                              PrefUtils.setPinCode1(mPincode1!);
                              fromLatitude = details.lat.toString();
                              fromLongitude = details.lng.toString();
                            } else {
                              mPincode2 = details.postalCode;
                              PrefUtils.setPinCode2(mPincode2!);
                              toLatitude = details.lat.toString();
                              toLongitude = details.lng.toString();
                            }
                          }
                          if (mPincode1 != null && mPincode2 != null) {
                            _checkCluster(mPincode1!, mPincode2!);
                            _checkDistance(mPincode1!, mPincode2!);
                          } else if (mPincode1 != null) {
                            _checkArea(mPincode1!);
                          }
                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showRecent) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Recent Searches",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: recentLocations.length,
                          itemBuilder: (context, index) {
                            final loc = recentLocations[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.history,
                                color: Colors.grey,
                              ),
                              title: Text(
                                loc.location,
                                style: const TextStyle(fontSize: 15),
                              ),
                              onTap: () async {
                                controller.text = loc.location;
                                searchController.text = loc.location;
                                await PrefUtils.addLocation(
                                  location: loc.location,
                                  postalCode: loc.postalCode,
                                  lat: loc.lat,
                                  lng: loc.lng,
                                );
                                if (label == "Pickup Location") {
                                  mPincode1 = loc.postalCode;
                                  PrefUtils.setPinCode1(mPincode1!);
                                  fromLatitude = loc.lat.toString();
                                  fromLongitude = loc.lng.toString();
                                } else {
                                  mPincode2 = loc.postalCode;
                                  PrefUtils.setPinCode2(mPincode2!);
                                  toLatitude = loc.lat.toString();
                                  toLongitude = loc.lng.toString();
                                }
                                if (mPincode1 != null && mPincode2 != null) {
                                  _checkCluster(mPincode1!, mPincode2!);
                                  _checkDistance(mPincode1!, mPincode2!);
                                } else if (mPincode1 != null) {
                                  _checkArea(mPincode1!);
                                }
                                if (Navigator.of(sheetContext).canPop()) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── DATE / TIME PICKERS (unchanged) ─────────────────────────────────────
  Future<void> selectPickupDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      pickupDateController.text =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
      setState(() {});
    }
  }

  Future<void> selectPickupTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      pickupTimeController.text = picked.format(context);
      setState(() {});
    }
  }

  // ─── VEHICLE BOTTOM SHEET (unchanged) ────────────────────────────────────
  Future<void> showVehicleBottomSheet(
    BuildContext context,
    String pincode1,
    String pincode2,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: VehicleSelectionSheet(
            pincode1,
            pincode2,
            mDistance,
            mDuration,
            fareData,
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        vehicleType = result["vehicleType"] ?? "";
        mPrice = result["price"]?.toString() ?? "0";
      });
    }
  }
}
