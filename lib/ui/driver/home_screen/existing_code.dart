import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../SocketService/driver_know_book_socket_service.dart';
import '../../../provider_service/accept_reject_trip_provider.dart';
import '../../../provider_service/booking_provider.dart';
import '../../../provider_service/driver_booing_request_provider.dart';
import '../../../provider_service/driver_booking_ongoing_provider.dart';
import '../../../provider_service/driver_trip_start_provider.dart';
import '../../../provider_service/verify_otp_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../widgetScreen/ride_action_buttons.dart';

const String GOOGLE_API_KEY = "AIzaSyDpH5LUm09CEiJX4cSan8SDp0vxuVLwCCQ";

class ExistingCode extends StatefulWidget {
  const ExistingCode({super.key});

  @override
  State<ExistingCode> createState() => _ExistingCode();
}

class _ExistingCode extends State<ExistingCode> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  var mBookingId;

  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  bool isLoading = false;
  bool isValidateLoading = false;
  String buttonName = "ARRIVED";

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

      DriverKnowBookSocketService()
        ..attachProvider(bookingProvider)
        ..connectDriverSocket(int.parse(PrefUtils.getUserId()));

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
      // 🔥 STEP 1: Get last known position (FAST)
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        _currentLocation =
            LatLng(lastPosition.latitude, lastPosition.longitude);
        _showOnlyDriver();
      }

      // 🔥 STEP 2: Get accurate position (SLOW but precise)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8), // avoid freeze
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _showOnlyDriver();

      // Move camera smoothly
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

    // ✅ CRITICAL FIX
    if (points.isEmpty) {
      debugPrint("Route points empty — skipping bounds");
      setState(() {});
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
        "&key=$GOOGLE_API_KEY";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint("Directions API HTTP error: ${response.statusCode}");
        return [];
      }

      final data = json.decode(response.body);

      // Google API–level errors (VERY important)
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
        southwest: LatLng(20.5937, 78.9629),
        northeast: LatLng(20.5937, 78.9629),
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

    setState(() {});
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  Future<void> _driverRide() async {
    setState(() => isLoading = true);

    http.Response response =
    await Provider.of<StartTripeProvider>(
      context,
      listen: false,
    ).startTrip();

    setState(() => isLoading = false);

    final data = json.decode(response.body);

    if (data['success'] == true) {
      if (data.containsKey('data') &&
          data['data'] != null &&
          data['data'].containsKey('nextStatus') &&
          data['data']['nextStatus'] != null) {
        setState(() {
          buttonName = data['data']['nextStatus'];
        });

        print("Next Status: $buttonName");
        if (buttonName == 'LOADING') {
          _showOtpDialog(context);
        }
      } else {
        setState(() {
          buttonName = "ARRIVED";
          print("nextStatus not found in response");
        });
      }
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  /// ================= HANDLE TRIP COMPLETED =================
  Future<void> _handleTripCompletedOnlyDriver() async {
    if (_mapController == null) return;

    // Get latest location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation = LatLng(position.latitude, position.longitude);

    // Clear old markers and polylines
    _markers.clear();
    _polylines.clear();

    // Add only truck marker
    _markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: _currentLocation!,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    setState(() {});

    // Move camera to driver location
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
    );
  }

  Future<bool> _verifyOtp(String pinCode) async {
    try {
      final response = await Provider.of<VerifyOtpProvider>(
        context,
        listen: false,
      ).verifyOtp(pinCode, mBookingId);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print("VERIFY OTP ${data['message']}");
        return true; // ✅ success
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
                    /// 🔷 LOGO
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

                    /// 🔢 OTP FIELD (Responsive)
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

                          /// 🔥 AUTO SUBMIT
                          onCompleted: (value) async {
                            if (value.length == 6 && !isLoading) {
                              setDialogState(() => isLoading = true);

                              bool isSuccess = await _verifyOtp(value);

                              setDialogState(() => isLoading = false);

                              if (isSuccess) {
                                Navigator.of(
                                  dialogContext,
                                ).pop(); // ✅ close dialog
                              }
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    /// 🔘 SUBMIT BUTTON
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
                          if (otpController.text.trim().length != 6) {
                            Utils.showCustomToast(
                              context,
                              "Please enter valid 6 digit OTP",
                            );
                            return;
                          }
                          print("OTP ===========>${otpController.text.trim()}");
                          setDialogState(() => isLoading = true);

                          bool isSuccess = await _verifyOtp(
                            otpController.text.trim(),
                          );

                          setDialogState(() => isLoading = false);

                          if (isSuccess) {
                            Navigator.of(
                              dialogContext,
                            ).pop(); // ✅ close dialog
                          }
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
              children: [_upcomingCard(), _ongoingCard()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation ?? const LatLng(20.5937, 78.9629),
        zoom: 12,
      ),
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (c) => _mapController = c,
    );
  }

  /// ================= UPCOMING =================
  Widget _upcomingCard() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final ride = provider.upcomingRide;

        if (ride == null) return const SizedBox();

        final pickup = LatLng(
          ride['fromLocation']['lat'],
          ride['fromLocation']['lng'],
        );
        final drop = LatLng(
          ride['toLocation']['lat'],
          ride['toLocation']['lng'],
        );

        mBookingId = ride['bookingId'];

        WidgetsBinding.instance.addPostFrameCallback(
              (_) => drawRoute(pickup, drop),
        );

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                Utils.formatIsoDate(ride["createdAt"]),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),
              Text("📍 ${ride['fromLocation']['address']}"),
              const SizedBox(height: 8),
              Text("🏁 ${ride['toLocation']['address']}"),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${ride['distance'] ?? "--"}"),
                  Text(
                    "₹ ${ride['fare'] ?? "--"}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              RideActionButtons(
                isAccepted: true,
                ride: ride,
                onAction: (status, bookingId) async {
                  await _acceptRejectRide(status, bookingId);
                },
              ),
            ],
          ),
        );
      },
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                Utils.formatIsoDate(ride["createdAt"]),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),
              Text("📍 ${ride['fromLocation']['address']}"),
              const SizedBox(height: 8),
              Text("🏁 ${ride['toLocation']['address']}"),
              const SizedBox(height: 10),

              /* Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name : ${ride['customer']['name']??"--"}"),
                  Text(
                    "Phone: ${ride['customer']['phone']??"--"}",
                    style: const TextStyle(
                        fontSize: 16),
                  ),
                ],
              ),*/
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Distance : ${ride['distance'] ?? "--"}"),
                  Text(
                    "₹ ${ride['fare'] ?? "--"}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarycolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _driverRide();
                    if (buttonName == "COMPLETED") {
                      _handleTripCompletedOnlyDriver();
                      provider.clearBooking();
                    }
                  },
                  child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    buttonName,
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
        );
      },
    );
  }
}
