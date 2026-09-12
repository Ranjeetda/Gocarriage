import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/widgets/service_mode_selector.dart';


class PincodeCityProvider extends ChangeNotifier {
  String _result = "";
  bool _isLoading = false;
  ServiceMode? _suggestedMode;

  String get result => _result;
  bool get isLoading => _isLoading;
  ServiceMode? get suggestedMode => _suggestedMode;

  Future<void> checkCity(String pin1, String pin2) async {
    pin1 = pin1.trim();
    pin2 = pin2.trim();

    if (pin1.length != 6 || pin2.length != 6) {
      _result = "Please enter valid 6-digit pincodes";
      _suggestedMode = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _result = "";
    _suggestedMode = null;
    notifyListeners();

    final details1 = await _getPincodeDetails(pin1);
    final details2 = await _getPincodeDetails(pin2);

    _isLoading = false;

    if (details1 == null || details2 == null) {
      _result = "Invalid pincode(s)";
      _suggestedMode = null;
    } else if (details1['district'] == details2['district']) {
      _result = "Within City";
      _suggestedMode = ServiceMode.incity;
    } else {
      _result = "Outside City";
      _suggestedMode = ServiceMode.outcity;
    }

    notifyListeners();
  }

  Future<Map<String, String>?> _getPincodeDetails(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.postalpincode.in/pincode/$pincode"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data[0]['Status'] == "Success") {
          final postOffice = data[0]['PostOffice'][0];
          return {
            "district": postOffice['District'] ?? "",
            "state": postOffice['State'] ?? "",
          };
        }
      }
    } catch (e) {
      debugPrint("Error fetching pincode: $e");
    }
    return null;
  }

  // Optional: reset everything
  void reset() {
    _result = "";
    _isLoading = false;
    _suggestedMode = null;
    notifyListeners();
  }
}