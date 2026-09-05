import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../resource/Utils.dart';

class PickupLocationDialog extends StatefulWidget {
  const PickupLocationDialog({super.key});

  @override
  State<PickupLocationDialog> createState() => _PickupLocationDialogState();
}

class _PickupLocationDialogState extends State<PickupLocationDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  GoogleMapController? _mapController;

  List<PlacePrediction> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  bool _isMapMoving = false;
  bool _ignoreSearchChange = false;

  String selectedAddress = "Searching location...";
  String? selectedPlaceId;
  String? selectedPincode; // ← Added
  LatLng _currentLatLng = const LatLng(28.6139, 77.2090);

  final String _apiKey = Utils.googleMapKey;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  // ───────── Get Current Location ─────────
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLatLng = latLng;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );

      await _getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // ───────── Search ─────────
  Timer? _debounce;

  void _onSearchChanged() {
    if (_ignoreSearchChange) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=${Uri.encodeComponent(input)}"
          "&key=$_apiKey"
          "&components=country:in",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          setState(() {
            _suggestions = predictions
                .map((p) => PlacePrediction(
              description: p['description'],
              placeId: p['place_id'],
              mainText: p['structured_formatting']?['main_text'] ??
                  p['description'],
              secondaryText:
              p['structured_formatting']?['secondary_text'] ?? '',
            ))
                .toList();
            _showSuggestions = true;
          });
        } else {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    }
  }

  // Helper to extract pincode from address_components
  String? _extractPincode(List<dynamic>? components) {
    if (components == null) return null;
    for (var component in components) {
      final types = component['types'] as List;
      if (types.contains('postal_code')) {
        return component['long_name'];
      }
    }
    return null;
  }

  // ───────── Select Place ─────────
  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _isLoading = true;
      selectedPlaceId = prediction.placeId;
    });

    _ignoreSearchChange = true;
    _searchController.text = prediction.mainText;
    FocusScope.of(context).unfocus();

    // Request address_components so we can get pincode
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=${prediction.placeId}"
          "&fields=geometry,formatted_address,address_component"
          "&key=$_apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        final lat = result['geometry']['location']['lat'];
        final lng = result['geometry']['location']['lng'];
        final address = result['formatted_address'];
        final pincode = _extractPincode(result['address_components']);

        final latLng = LatLng(lat, lng);

        _ignoreSearchChange = true;
        _searchController.text = address;

        setState(() {
          _currentLatLng = latLng;
          selectedAddress = address;
          selectedPincode = pincode;
          _isLoading = false;
          _showSuggestions = false;
          _suggestions = [];
        });

        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Place details error: $e");
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        _ignoreSearchChange = false;
      });
    }
  }

  // ───────── Reverse Geocode ─────────
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json"
          "?latlng=${latLng.latitude},${latLng.longitude}"
          "&key=$_apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final address = result['formatted_address'];
          final placeId = result['place_id'];
          final pincode = _extractPincode(result['address_components']);

          if (!_searchFocus.hasFocus) {
            _ignoreSearchChange = true;
            _searchController.text = address;

            Future.delayed(const Duration(milliseconds: 400), () {
              _ignoreSearchChange = false;
            });
          }

          setState(() {
            selectedAddress = address;
            selectedPlaceId = placeId;
            selectedPincode = pincode;
          });
        }
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onTap: () {
                    if (_suggestions.isNotEmpty) {
                      setState(() => _showSuggestions = true);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search area, street, landmark...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF6B7280)),
                    suffixIcon: _isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : (_searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _ignoreSearchChange = true;
                        _searchController.clear();
                        setState(() {
                          _suggestions = [];
                          _showSuggestions = false;
                        });
                        Future.delayed(
                            const Duration(milliseconds: 300), () {
                          _ignoreSearchChange = false;
                        });
                      },
                    )
                        : null),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF3B82F6), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF3B82F6), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 2),
                    ),
                  ),
                ),

                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        return InkWell(
                          onTap: () => _selectPlace(place),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 20, color: Color(0xFF6B7280)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: place.mainText,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        TextSpan(
                                          text: " ${place.secondaryText}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Map
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onCameraMove: (position) {
                    _currentLatLng = position.target;
                    if (!_isMapMoving) {
                      setState(() => _isMapMoving = true);
                    }
                  },
                  onCameraIdle: () async {
                    if (_isMapMoving) {
                      setState(() => _isMapMoving = false);
                      await _getAddressFromLatLng(_currentLatLng);
                    }
                  },
                ),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: _isMapMoving
                          ? const Color(0xFF2563EB).withOpacity(0.7)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 20,
                  child: Column(
                    children: [
                      _mapButton(Icons.add, () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      }),
                      const SizedBox(height: 8),
                      _mapButton(Icons.remove, () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      }),
                      const SizedBox(height: 8),
                      _mapButton(Icons.my_location, _getCurrentLocation),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Confirm
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'address': selectedAddress,
                        'latitude': _currentLatLng.latitude,
                        'longitude': _currentLatLng.longitude,
                        'place_id': selectedPlaceId,
                        'pincode': selectedPincode, // ← Added
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm Pickup Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: const Color(0xFF374151)),
        ),
      ),
    );
  }
}

class PlacePrediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}