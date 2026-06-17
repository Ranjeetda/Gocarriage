import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../provider_service/place_provider.dart';

class PlacePickerScreen extends StatefulWidget {
  final String hintText;

  PlacePickerScreen(
      this.hintText,
      );

  @override
  _PlacePickerScreenState createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  LatLng? _currentLatLng;
  Set<Marker> _markers = {};
  bool isTure = false;

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Fetch current GPS location and place marker safely
  Future<void> _setCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng;latLng = LatLng(position.latitude, position.longitude);
    final address = await _getAddressFromLatLng(latLng);

    if (!mounted) return;
    setState(() {
      _currentLatLng = latLng;
      _controller.text = address;
      _markers = {
        Marker(
          markerId: const MarkerId("current_location"),
          position: latLng,
          infoWindow: InfoWindow(title: address),
          draggable: true,
          onDragEnd: (newPos) => _updateMarker(newPos),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 15),
      ),
    );

    Provider.of<PlaceProvider>(context, listen: false)
        .updateSelectedPlaceLocation(
        latLng.latitude, latLng.longitude, address);
  }

  /// Convert LatLng to human-readable address
  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
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

  /// Update marker and provider when dragged or tapped
  Future<void> _updateMarker(LatLng pos) async {
    if (!mounted) return;

    final address = await _getAddressFromLatLng(pos);

    setState(() {
      _currentLatLng = pos;
      _controller.text = address;
      _markers = {
        Marker(
          markerId: const MarkerId("current_location"),
          position: pos,
          infoWindow: InfoWindow(title: address),
          draggable: true,
          onDragEnd: (newPos) => _updateMarker(newPos),
        ),
      };
    });

    Provider.of<PlaceProvider>(context, listen: false)
        .updateSelectedPlaceLocation(pos.latitude, pos.longitude, address);
  }

  Future<void> _updateMarker1(LatLng pos, String mAddress) async {
    if (!mounted) return;

    setState(() {
      _currentLatLng = pos;
      _markers = {
        Marker(
          markerId: const MarkerId("current_location"),
          position: pos,
          infoWindow: InfoWindow(title: mAddress),
          draggable: true,
          onDragEnd: (newPos) => _updateMarker(newPos),
        ),
      };
    });

    Provider.of<PlaceProvider>(context, listen: false)
        .updateSelectedPlaceLocation(pos.latitude, pos.longitude, mAddress);
  }

  /// Animate camera to marker
  void _moveCamera(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = Provider.of<PlaceProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          // Back arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: Text(
          "Search Location",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF023E8A),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;
            final availableHeight = constraints.maxHeight - viewInsets;

            return SizedBox(
              height: availableHeight,
              child: Column(
                children: [
                  /// Search Field
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_controller.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  placeProvider.clearSearchResults();
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _setCurrentLocation,
                            ),
                          ],
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length >= 4) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                                () => placeProvider.searchPlaces(value),
                          );
                        }
                      },
                      onSubmitted: (value) {
                        if (value.length >= 4) placeProvider.searchPlaces(value);
                      },
                    ),
                  ),

                  if (placeProvider.isLoading) const LinearProgressIndicator(),

                  /// Search Results OR Map
                  if (placeProvider.places.isNotEmpty &&
                      placeProvider.selectedPlace == null)
                    Expanded(
                      child: ListView.separated(
                        itemCount: placeProvider.places.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.grey),
                        itemBuilder: (context, index) {
                          final place = placeProvider.places[index];
                          return InkWell(
                            onTap: () {
                              isTure = true;
                              final latLng =
                              LatLng(place.latitude, place.longitude);
                              _updateMarker1(latLng, place.placeName);
                              _controller.text = place.placeName;
                              _moveCamera(latLng);
                              FocusScope.of(context).unfocus();
                              placeProvider.selectPlace(place);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Center(
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.yellow.shade200,
                                              Colors.yellow.shade700,
                                            ],
                                            center: Alignment.center,
                                            radius: 0.8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            "assets/ions/ic_location.png",
                                            width: 14,
                                            height: 14,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        AutoSizeText(
                                          place.placeName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          maxLines: 3,
                                          minFontSize: 10,
                                          overflow: TextOverflow.visible,
                                          wrapWords: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(25.594305, 85.114582),
                          zoom: 13,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_currentLatLng != null)
                            _moveCamera(_currentLatLng!);
                        },
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onTap: _updateMarker,
                      ),
                    ),

                  /// Confirm Location Button
                  if (_currentLatLng != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pop(
                              context, placeProvider.selectedPlace),
                          child: const Text(
                            "Confirm Location",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
