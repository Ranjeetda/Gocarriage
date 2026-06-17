import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/image_paths.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../provider_service/URLS.dart';
import '../../resource/app_colors.dart';

class DriverTrackingScreen extends StatefulWidget {
  final double fromLat;
  final double fromLang;
  final double toLat;
  final double toLang;

  const DriverTrackingScreen(
      this.fromLat, this.fromLang, this.toLat, this.toLang,
      {Key? key})
      : super(key: key);

  @override
  State<DriverTrackingScreen> createState() =>
      _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  late GoogleMapController mapController;
  late IO.Socket socket;

  Marker? carMarker;
  BitmapDescriptor? carIcon;

  Set<Polyline> polylines = {};
  Set<Marker> staticMarkers = {};

  LatLng currentPosition = const LatLng(28.6139, 77.2090);

  final String socketUrl = URLS.bookingBaseUrl;
  final String customerJwt = PrefUtils.getToken();

  Timer? animationTimer;

  LatLng get pickupLocation =>
      LatLng(widget.fromLat, widget.fromLang);

  LatLng get dropLocation =>
      LatLng(widget.toLat, widget.toLang);

  @override
  void initState() {
    super.initState();
    loadCarIcon();
    addStaticMarkers();
    connectSocket();
  }

  /// Load custom car icon
  Future<void> loadCarIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      ImagePaths.truck,
    );

    setState(() {
      carIcon = icon;
    });
  }

  /// Add pickup & drop markers
  void addStaticMarkers() {
    staticMarkers = {
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Pickup"),
      ),
      Marker(
        markerId: const MarkerId("drop"),
        position: dropLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Drop"),
      ),
    };
  }

  /// Connect Socket
  void connectSocket() {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': customerJwt})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('✅ SOCKET CONNECTED');
    });

    socket.on("DRIVER_LOCATION_UPDATE", (data) {
      final double lat =
      (data['location']['lat'] as num).toDouble();
      final double lng =
      (data['location']['lng'] as num).toDouble();

      final LatLng newPosition = LatLng(lat, lng);

      final double heading =
      calculateHeading(currentPosition, newPosition);

      animateCar(currentPosition, newPosition, heading);

      currentPosition = newPosition;

      drawRoute(newPosition);
    });
  }

  /// Calculate rotation angle
  double calculateHeading(LatLng start, LatLng end) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;

    double angle = atan2(dx, dy) * 180 / pi;

    if (angle < 0) angle += 360;

    return angle;
  }

  /// Draw polyline
  void drawRoute(LatLng driverPosition) {
    polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: [
          driverPosition,
          pickupLocation,
          dropLocation,
        ],
      ),
    };

    setState(() {});
  }

  /// Animate car smoothly
  void animateCar(
      LatLng start, LatLng end, double heading) {
    if (carIcon == null) return;

    animationTimer?.cancel();

    const int steps = 30;
    int step = 0;

    animationTimer =
        Timer.periodic(const Duration(milliseconds: 30),
                (timer) {
              step++;

              final lat = start.latitude +
                  (end.latitude - start.latitude) *
                      (step / steps);

              final lng = start.longitude +
                  (end.longitude - start.longitude) *
                      (step / steps);

              final position = LatLng(lat, lng);

              setState(() {
                carMarker = Marker(
                  markerId: const MarkerId("car"),
                  position: position,
                  rotation: heading,
                  flat: true,
                  anchor: const Offset(0.5, 0.5),
                  icon: carIcon!,
                );
              });

              mapController
                  .animateCamera(CameraUpdate.newLatLng(position));

              if (step >= steps) {
                timer.cancel();
              }
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Track',
          style: TextStyle(
              fontSize: 16, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition,
          zoom: 16,
        ),
        markers: {
          ...staticMarkers,
          if (carMarker != null) carMarker!,
        },
        polylines: polylines,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    socket.dispose();
    super.dispose();
  }
}