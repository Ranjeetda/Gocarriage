import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import '../ui/pleacePickerScreen/place_model.dart';
import 'URLS.dart';

class PlaceProvider with ChangeNotifier {
  List<Place> _places = [];
  Place? _selectedPlace;
  bool _isLoading = false;

  List<Place> get places => _places;
  Place? get selectedPlace => _selectedPlace;
  bool get isLoading => _isLoading;

  /// Clear the current search results
  void clearSearchResults() {
    _places = [];
    _selectedPlace = null;
    notifyListeners();
  }

  /// 🔎 Search places from API
  Future<void> searchPlaces(String query) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.placeApi);
    final headers = {
      "Content-Type": "application/json",
      "Authorization": PrefUtils.getToken()!,
    };
    final body = jsonEncode({"address": query,"limit":"10"});

    // Debug prints
    debugPrint("🔗 URL: $url");
    debugPrint("📩 Headers: $headers");
    debugPrint("📦 Request Body: $body");

    try {
      _selectedPlace = null;
      _places.clear();

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      final data = json.decode(response.body);
      debugPrint("📦 Response Body: ${data.toString()}");

      if (response.statusCode == 200) {
        if (data["status"] == true && data["data"] != null) {
          final List<dynamic> results = data["data"];
          _places = results.map((e) => Place.fromJson(e)).toList();
        } else {
          _places = [];
        }
      } else {
        _places = [];
      }
    } catch (e) {
      _places = [];
      debugPrint("❌ Error searching places: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 📍 Select a place
  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  /// ✏️ Update or add a selected place
  void updateSelectedPlaceLocation(double lat, double lng, String mPlaceName) {
    if (_selectedPlace != null) {
      _selectedPlace = _selectedPlace!.copyWith(
        latitude: lat,
        longitude: lng,
        placeName: mPlaceName,
      );
    } else {
      _selectedPlace = Place(
        latitude: lat,
        longitude: lng,
        placeName: mPlaceName,
        placeId: '',
      );
    }
    notifyListeners();
  }
}
