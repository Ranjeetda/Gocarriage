import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../SocketService/driver_know_book_socket_service.dart';
import '../../../provider_service/accept_reject_trip_provider.dart';
import '../../../provider_service/audio_provider.dart';
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

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  bool isLoading = false;
  String buttonName = "ARRIVED";
  var mBookingId;
  bool _isDrawingRoute = false;

  // Default fallback location (Patna)
  final LatLng _defaultLocation = const LatLng(25.5941, 85.1376);

  @override
  void initState() {
    super.initState();
    _loadIcons(); // Load icons first
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

  // ================= ICONS =================
  Future<void> _loadIcons() async {
    try {
      _truckIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(60, 60)),
        ImagePaths.truck,
      );

      _pickupIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        ImagePaths.flag,
      );

      _dropIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        ImagePaths.house,
      );

      if (mounted) {
        setState(() {});
        _showOnlyDriver(); // Refresh marker with custom icon
      }
    } catch (e) {
      debugPrint("Icon loading error: $e");
    }
  }

  // ================= LOCATION =================
  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Utils.showErrorMessage(context, "Location permission is required");
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 12));

      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Location error: $e");
      _setDefaultLocation();
    }

    if (mounted) {
      _showOnlyDriver();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  void _setDefaultLocation() {
    _currentLocation = _defaultLocation;
    if (mounted) _showOnlyDriver();
  }

  void _showOnlyDriver() {
    if (_currentLocation == null) return;

    _markers.clear();
    _polylines.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: _currentLocation!,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.5),
      ),
    );

    if (mounted) setState(() {});
  }

  // ================= OLA/UBER STYLE ROUTE =================
  Future<void> drawRoute(LatLng pickup, LatLng drop) async {
    if (_currentLocation == null || _isDrawingRoute) return;
    _isDrawingRoute = true;

    try {
      _markers.clear();
      _polylines.clear();

      _markers.addAll([
        Marker(
          markerId: const MarkerId("driver"),
          position: _currentLocation!,
          icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
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

      List<LatLng> routeToPickup = await _fetchRoute(_currentLocation!, pickup);
      if (routeToPickup.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("to_pickup"),
            points: routeToPickup,
            color: Colors.blue,
            width: 7,
            geodesic: true,
          ),
        );
      }

      List<LatLng> routeToDrop = await _fetchRoute(pickup, drop);
      if (routeToDrop.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("to_drop"),
            points: routeToDrop,
            color: Colors.green,
            width: 7,
            geodesic: true,
          ),
        );
      }

      if (mounted) setState(() {});

      if (_mapController != null &&
          (routeToPickup.isNotEmpty || routeToDrop.isNotEmpty)) {
        await Future.delayed(const Duration(milliseconds: 400));
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBounds([...routeToPickup, ...routeToDrop]),
            90,
          ),
        );
      }
    } catch (e) {
      debugPrint("Route drawing error: $e");
    } finally {
      _isDrawingRoute = false;
    }
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start.latitude},${start.longitude}&"
        "destination=${end.latitude},${end.longitude}&"
        "mode=driving&key=$GOOGLE_API_KEY";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data['status'] != 'OK' || data['routes'].isEmpty) return [];

      final points = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(points);
    } catch (e) {
      debugPrint("Directions API error: $e");
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty && _currentLocation != null) {
      return LatLngBounds(
        southwest: _currentLocation!,
        northeast: _currentLocation!,
      );
    }
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ================= YOUR EXISTING METHODS (UNTOUCHED) =================
  Future<void> _acceptRejectRide(String type, String bookingId) async {
    setState(() => isLoading = true);
    Provider.of<AudioProvider>(context, listen: false).stop();
    try {
      http.Response response = await Provider.of<AcceptRejectTripProvider>(
        context,
        listen: false,
      ).acceptRejectTrip(type, bookingId);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        context.read<BookingProvider>().clearRide();
        context.read<DriverBookingOngoingProvider>().fetchBooking();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        Utils.showErrorMessage(context, data['message']);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _driverRide() async {
    setState(() => isLoading = true);
    try {
      http.Response response =
          await Provider.of<StartTripeProvider>(
            context,
            listen: false,
          ).startTrip();
      final data = json.decode(response.body);

      if (data['success'] == true) {
        if (data['data']?['nextStatus'] != null) {
          setState(() => buttonName = data['data']['nextStatus']);
          if (buttonName == 'LOADING') {
            _showOtpDialog(context);
          }
        }
      } else {
        Utils.showErrorMessage(context, data['message']);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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

    setState(() {});

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
                                  setDialogState(() => isLoading = true);
                                  bool isSuccess = await _verifyOtp(
                                    otpController.text.trim(),
                                  );
                                  setDialogState(() => isLoading = false);
                                  if (isSuccess) {
                                    Navigator.of(dialogContext).pop();
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
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
    final initialPosition = _currentLocation ?? _defaultLocation;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 15),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }
      },
    );
  }

  // ================= UPCOMING CARD (YOUR ORIGINAL UI - UNCHANGED) =================
  Widget _upcomingCard() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final ride = provider.upcomingRide;
        if (ride == null) return const SizedBox.shrink();

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
                onAction:
                    (status, bookingId) => _acceptRejectRide(status, bookingId),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= ONGOING CARD (YOUR ORIGINAL UI - UNCHANGED) =================
  Widget _ongoingCard() {
    return Consumer<DriverBookingOngoingProvider>(
      builder: (context, provider, _) {
        final ride = provider.bookingData;
        if (ride == null) return const SizedBox.shrink();

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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
