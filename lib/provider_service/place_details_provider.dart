import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ui/model/place_details_model.dart';

class PlaceDetailsProvider extends ChangeNotifier {
  PlaceDetailsModel? _placeDetails;
  bool _isLoading = false;
  String? _error;

  PlaceDetailsModel? get placeDetails => _placeDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlaceDetails(String placeId) async {
    const apiKey = "AIzaSyDpH5LUm09CEiJX4cSan8SDp0vxuVLwCCQ";

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json"
            "?place_id=$placeId"
            "&fields=address_component,geometry"
            "&key=$apiKey",
      );

      // ✅ Print Request URL
      debugPrint("REQUEST URL: $url");

      final response = await http.get(url);

      // ✅ Print Status Code
      debugPrint("STATUS CODE: ${response.statusCode}");

      // ✅ Print Raw Response
      debugPrint("RESPONSE BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch place details");
      }

      final data = json.decode(response.body);

      if (data['status'] != "OK") {
        throw Exception(data['status']);
      }

      final result = data['result'];

      // Extract postal code
      String postalCode = "";
      for (var component in result['address_components']) {
        if ((component['types'] as List).contains("postal_code")) {
          postalCode = component['long_name'];
          break;
        }
      }

      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];

      _placeDetails = PlaceDetailsModel(
        placeId: placeId,
        postalCode: postalCode,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint("ERROR: $e");
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

}
