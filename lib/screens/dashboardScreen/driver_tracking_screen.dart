import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:gocarriage_universal/resource/image_paths.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import '../../provider_service/URLS.dart';

class DriverTrackingScreen extends StatefulWidget {
  final double fromLat;
  final double fromLang;
  final double toLat;
  final double toLang;

  const DriverTrackingScreen({
    Key? key,
    required this.fromLat,
    required this.fromLang,
    required this.toLat,
    required this.toLang,
  }) : super(key: key);

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  GoogleMapController? mapController;
  IO.Socket? socket;

  Marker? carMarker;
  BitmapDescriptor? carIcon;

  Set<Polyline> polylines = {};
  Set<Marker> staticMarkers = {};

  LatLng currentPosition = const LatLng(28.6139, 77.2090); // default Delhi
  double currentHeading = 0.0;

  final String socketUrl = URLS.bookingBaseUrl;
  final String customerJwt = PrefUtils.getToken();

  Timer? animationTimer;
  bool isAnimating = false;

  LatLng get pickupLocation => LatLng(widget.fromLat, widget.fromLang);
  LatLng get dropLocation => LatLng(widget.toLat, widget.toLang);

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _addStaticMarkers();
    _connectSocket();
  }

  Future<void> _loadCarIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      ImagePaths.truck, // make sure this is a top-view car/truck icon
    );
    if (mounted) {
      setState(() => carIcon = icon);
    }
  }

  void _addStaticMarkers() {
    staticMarkers = {
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Pickup"),
      ),
      Marker(
        markerId: const MarkerId("drop"),
        position: dropLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Drop"),
      ),
    };
  }

  void _connectSocket() {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': customerJwt})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('✅ SOCKET CONNECTED');
    });

    socket!.onDisconnect((_) {
      debugPrint('❌ SOCKET DISCONNECTED');
    });

    socket!.on("DRIVER_LOCATION_UPDATE", (data) {
      if (data == null || data['location'] == null) return;

      try {
        final double lat = (data['location']['lat'] as num).toDouble();
        final double lng = (data['location']['lng'] as num).toDouble();

        final LatLng newPosition = LatLng(lat, lng);

        // Calculate proper bearing
        final double heading = _calculateBearing(currentPosition, newPosition);

        _animateCar(currentPosition, newPosition, heading);

        currentPosition = newPosition;
        currentHeading = heading;

        _drawRoute(newPosition);
      } catch (e) {
        debugPrint("Location update error: $e");
      }
    });
  }

  /// Proper bearing calculation (0–360 degrees)
  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double dLon = (end.longitude - start.longitude) * math.pi / 180;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _drawRoute(LatLng driverPosition) {
    // Simple straight line for now (Ola/Uber use Directions API)
    // You should replace this with Google Directions polyline later
    polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        color: AppColors.primaryColor.withOpacity(0.8),
        width: 5,
        points: [
          driverPosition,
          pickupLocation,
          // Uncomment if you want full trip route
          // dropLocation,
        ],
      ),
    };

    if (mounted) setState(() {});
  }

  void _animateCar(LatLng start, LatLng end, double heading) {
    if (carIcon == null || isAnimating) return;

    animationTimer?.cancel();
    isAnimating = true;

    const int steps = 40; // higher = smoother
    int step = 0;

    animationTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      step++;

      // Linear interpolation (you can add easing later)
      final double t = step / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * t;
      final double lng = start.longitude + (end.longitude - start.longitude) * t;

      final position = LatLng(lat, lng);

      if (mounted) {
        setState(() {
          carMarker = Marker(
            markerId: const MarkerId("car"),
            position: position,
            rotation: heading,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon: carIcon!,
            zIndex: 2,
          );
        });
      }

      // Smooth camera follow (only every few steps to avoid lag)
      if (step % 4 == 0 && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 16.5,
              tilt: 0,
              bearing: heading, // optional: rotate map with car
            ),
          ),
        );
      }

      if (step >= steps) {
        timer.cancel();
        isAnimating = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Track Driver',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition,
          zoom: 15,
        ),
        markers: {
          ...staticMarkers,
          if (carMarker != null) carMarker!,
        },
        polylines: polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    socket?.dispose();
    mapController?.dispose();
    super.dispose();
  }
}