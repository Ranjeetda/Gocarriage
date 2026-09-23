import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../provider_service/accept_reject_trip_provider.dart';
import '../../../provider_service/booking_provider.dart';
import '../../../provider_service/driver_booing_request_provider.dart';
import '../../../provider_service/driver_booking_ongoing_provider.dart';
import '../../../provider_service/driver_trip_start_provider.dart';
import '../../../provider_service/driver_otp_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../SocketService/driver_socket_service.dart';
import '../widgetScreen/ride_action_buttons.dart';

String googleApiKey = Utils.googleMapKey;

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreen();
}

class _DriverHomeScreen extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String? mBookingId;

  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  bool isLoading = false;
  bool isValidateLoading = false;
  String buttonName = "ARRIVED";

  // Stable key prevents GoogleMap from being recreated → stops black screen
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );
      DriverSocketService().attachProvider(bookingProvider);
      context.read<DriverBookingOngoingProvider>().fetchBooking();
    });
  }

  /// ================= ICONS =================
  Future<void> _loadIcons() async {
    _truckIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      ImagePaths.truck,
    );
    _pickupIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      ImagePaths.flag,
    );
    _dropIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      ImagePaths.house,
    );
    if (mounted) {
      setState(() {});
    }
  }

  /// ================= LOCATION =================
  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      // STEP 1: Get last known position (FAST)
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        _currentLocation =
            LatLng(lastPosition.latitude, lastPosition.longitude);
        _showOnlyDriver();
      }

      // STEP 2: Get accurate position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _showOnlyDriver();

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  /// ================= ROUTE =================
  Future<void> drawRoute(LatLng pickup, LatLng drop) async {
    if (_currentLocation == null) return;

    _markers.clear();
    _polylines.clear();

    _markers.addAll([
      Marker(
        markerId: const MarkerId("driver"),
        position: _currentLocation!,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickup,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId("drop"),
        position: drop,
        icon: _dropIcon ?? BitmapDescriptor.defaultMarker,
      ),
    ]);

    final points = await _fetchRoute(_currentLocation!, drop);

    if (points.isEmpty) {
      debugPrint("Route points empty — skipping bounds");
      if (mounted) setState(() {});
      return;
    }

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: points,
        width: 5,
        color: Colors.blue,
      ),
    );

    if (!mounted) return;
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 300));

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_bounds(points), 80),
      );
    }
  }

  /// ================= DIRECTIONS =================
  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${start.latitude},${start.longitude}"
        "&destination=${end.latitude},${end.longitude}"
        "&mode=driving"
        "&alternatives=false"
        "&key=$googleApiKey";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint("Directions API HTTP error: ${response.statusCode}");
        return [];
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        debugPrint(
          "Directions API error: ${data['status']} | ${data['error_message']}",
        );
        return [];
      }

      if (data['routes'] == null || data['routes'].isEmpty) {
        debugPrint("No routes returned");
        return [];
      }

      final polyline = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(polyline);
    } on TimeoutException {
      debugPrint("Directions request timed out");
      return [];
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    List<LatLng> list = [];
    int index = 0, lat = 0, lng = 0;

    while (index < poly.length) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      list.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return list;
  }

  LatLngBounds _bounds(List<LatLng> list) {
    if (list.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(20.5937, 78.9629),
        northeast: const LatLng(20.5937, 78.9629),
      );
    }

    double x0 = list.first.latitude,
        x1 = list.first.latitude,
        y0 = list.first.longitude,
        y1 = list.first.longitude;

    for (LatLng p in list) {
      if (p.latitude > x1) x1 = p.latitude;
      if (p.latitude < x0) x0 = p.latitude;
      if (p.longitude > y1) y1 = p.longitude;
      if (p.longitude < y0) y0 = p.longitude;
    }

    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  /// ================= DRIVER ONLY =================
  void _showOnlyDriver() {
    if (_currentLocation == null) return;

    _markers.clear();
    _polylines.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: _currentLocation!,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    if (mounted) setState(() {});
  }

  /// ================= ACCEPT / REJECT =================
  Future<void> _acceptRejectRide(String type, String bookingId) async {
    setState(() => isLoading = true);

    http.Response response = await Provider.of<AcceptRejectTripProvider>(
      context,
      listen: false,
    ).acceptRejectTrip(type, bookingId);

    setState(() => isLoading = false);

    final data = json.decode(response.body);

    if (data['success'] == true) {
      context.read<BookingProvider>().clearRide();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<DriverBookingOngoingProvider>(
          context,
          listen: false,
        ).fetchBooking();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  Future<void> _driverRide() async {
    setState(() => isLoading = true);

    http.Response response = await Provider.of<StartTripeProvider>(
      context,
      listen: false,
    ).startTrip();

    setState(() => isLoading = false);

    final data = json.decode(response.body);

    if (data['success'] == true) {
      String? nextStatus;
      if (data.containsKey('data') &&
          data['data'] != null &&
          data['data'].containsKey('nextStatus') &&
          data['data']['nextStatus'] != null) {
        nextStatus = data['data']['nextStatus'];
      }

      if (nextStatus != null) {
        setState(() {
          buttonName = nextStatus!;
        });

        debugPrint("Next Status: $nextStatus");
        if (nextStatus == 'LOADING') {
          _showOtpDialog(context);
        } else if (nextStatus == 'COMPLETED') {
          _handleTripCompletedOnlyDriver();
          Provider.of<DriverBookingOngoingProvider>(context, listen: false)
              .clearBooking();
        }
      } else {
        setState(() {
          buttonName = "ARRIVED";
          debugPrint("nextStatus not found in response");
        });
      }
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final String googleMapsUrl = "google.navigation:q=$lat,$lng";
    final String appleMapsUrl = "https://maps.apple.com/?q=$lat,$lng";
    final String webUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(Uri.parse(googleMapsUrl));
        } else {
          await launchUrl(Uri.parse(webUrl),
              mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(Uri.parse(appleMapsUrl));
        } else {
          await launchUrl(Uri.parse(webUrl),
              mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not open maps: $e");
      if (mounted) {
        Utils.showErrorMessage(context, "Could not open map application");
      }
    }
  }

  /// ================= HANDLE TRIP COMPLETED =================
  Future<void> _handleTripCompletedOnlyDriver() async {
    if (_mapController == null) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation = LatLng(position.latitude, position.longitude);

    _markers.clear();
    _polylines.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: _currentLocation!,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    if (mounted) setState(() {});

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
    );
  }

  Future<bool> _verifyOtp(String pinCode) async {
    try {
      final response = await Provider.of<DriverOtpProvider>(
        context,
        listen: false,
      ).verifyOtp(pinCode, mBookingId ?? "");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print("VERIFY OTP ${data['message']}");
        return true;
      } else {
        Utils.showCustomToast(context, data['message'] ?? "Invalid OTP");
        return false;
      }
    } catch (e) {
      print("Exception ${e.toString()}");
      Utils.showCustomToast(context, "Something went wrong");
      return false;
    }
  }

  void _showOtpDialog(BuildContext parentContext) {
    final TextEditingController otpController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(ImagePaths.appLogo, height: 80),
                    const SizedBox(height: 12),
                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double availableWidth = constraints.maxWidth;
                        double fieldWidth = (availableWidth - 40) / 6;

                        return PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          enableActiveFill: true,
                          autoDisposeControllers: false,
                          cursorColor: AppColors.secondarycolor,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 50,
                            fieldWidth: fieldWidth,
                            activeFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                            inactiveColor: AppColors.textBox,
                            selectedColor: AppColors.secondarycolor,
                            activeColor: AppColors.secondarycolor,
                          ),
                          onChanged: (value) {},
                          onCompleted: (value) async {
                            if (value.length == 6 && !isLoading) {
                              setDialogState(() => isLoading = true);

                              bool isSuccess = await _verifyOtp(value);

                              setDialogState(() => isLoading = false);

                              if (isSuccess) {
                                Navigator.of(dialogContext).pop();
                              }
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
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
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (otpController.text.trim().length != 6) {
                            Utils.showCustomToast(
                              context,
                              "Please enter valid 6 digit OTP",
                            );
                            return;
                          }
                          setDialogState(() => isLoading = true);

                          bool isSuccess = await _verifyOtp(
                            otpController.text.trim(),
                          );

                          setDialogState(() => isLoading = false);

                          if (isSuccess) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        child: isLoading
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
            );
          },
        );
      },
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    context.read<DriverBooingRequestProvider>();

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _upcomingCard(),
                _ongoingCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      key: _mapKey, // ← Critical for preventing black screen
      initialCameraPosition: CameraPosition(
        target: _currentLocation!,
        zoom: 15,
      ),
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  /// ================= UPCOMING =================
  Widget _upcomingCard() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final ride = provider.upcomingRide;

        if (ride == null) return const SizedBox();

        final pickup = LatLng(
          ride['pickup']['lat'],
          ride['pickup']['lng'],
        );
        final drop = LatLng(
          ride['drop']['lat'],
          ride['drop']['lng'],
        );

        mBookingId = ride['bookingId'];

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => drawRoute(pickup, drop),
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "NEW REQUEST",
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      Utils.formatIsoDate(ride["pickupDate"]),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LOCATION TIMELINE ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.radio_button_checked, color: Colors.green, size: 22),
                            Container(
                              width: 2,
                              height: 35,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 22),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PICKUP",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ride['pickup']['address'] ?? "Unknown Location",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.navigation, color: Colors.green, size: 20),
                                    onPressed: () => _openNavigation(pickup.latitude, pickup.longitude),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "DROP OFF",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ride['drop']['address'] ?? "Unknown Location",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.navigation, color: Colors.red, size: 20),
                                    onPressed: () => _openNavigation(drop.latitude, drop.longitude),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // --- FARE & DISTANCE ---
                    Row(
                      children: [
                        _infoChip(
                          icon: Icons.map_outlined,
                          label: "Distance",
                          value: "${ride['distance'] ?? "0"} km",
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        _infoChip(
                          icon: Icons.payments_outlined,
                          label: "Net Fare",
                          value: "₹ ${ride['fare'] ?? "0"}",
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- ACTION BUTTONS ---
                    RideActionButtons(
                      isAccepted: true,
                      ride: ride,
                      onAction: (status, bookingId) async {
                        await _acceptRejectRide(status, bookingId);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= ONGOING =================
  Widget _ongoingCard() {
    return Consumer<DriverBookingOngoingProvider>(
      builder: (context, provider, _) {
        final ride = provider.bookingData;
        if (ride == null) return const SizedBox();

        final pickup = LatLng(
          ride['fromLocation']['lat'],
          ride['fromLocation']['lng'],
        );
        final drop = LatLng(
          ride['toLocation']['lat'],
          ride['toLocation']['lng'],
        );

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => drawRoute(pickup, drop),
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ONGOING TRIP",
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      Utils.formatIsoDate(ride["createdAt"]),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LOCATION TIMELINE ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.radio_button_checked, color: Colors.green, size: 22),
                            Container(
                              width: 2,
                              height: 35,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 22),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PICKUP",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ride['fromLocation']['address'] ?? "Unknown Location",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.navigation, color: Colors.green, size: 20),
                                    onPressed: () => _openNavigation(pickup.latitude, pickup.longitude),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "DROP OFF",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ride['toLocation']['address'] ?? "Unknown Location",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.navigation, color: Colors.red, size: 20),
                                    onPressed: () => _openNavigation(drop.latitude, drop.longitude),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // --- FARE & DISTANCE ---
                    Row(
                      children: [
                        _infoChip(
                          icon: Icons.map_outlined,
                          label: "Distance",
                          value: "${ride['distance'] ?? "0"} km",
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        _infoChip(
                          icon: Icons.payments_outlined,
                          label: "Net Fare",
                          value: "₹ ${ride['fare'] ?? "0"}",
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- ACTION BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          _driverRide();
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    buttonName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
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
    );
  }
}