import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/widgets/service_mode_selector.dart';

class PincodeCityProvider extends ChangeNotifier {
  String _result = "";
  bool _isLoading = false;
  ServiceMode? _suggestedMode;
  String? _errorMessage;          // ← new: holds the real error

  String get result => _result;
  bool get isLoading => _isLoading;
  ServiceMode? get suggestedMode => _suggestedMode;
  String? get errorMessage => _errorMessage;   // ← expose it to the UI

  Future<void> checkCity(String pin1, String pin2) async {
    pin1 = pin1.trim();
    pin2 = pin2.trim();

    // 1. Input validation
    if (pin1.length != 6 || pin2.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(pin1) ||
        !RegExp(r'^\d{6}$').hasMatch(pin2)) {
      _setError("Please enter valid 6-digit pincodes");
      return;
    }

    _isLoading = true;
    _result = "";
    _errorMessage = null;
    _suggestedMode = null;
    notifyListeners();

    try {
      final details1 = await _getPincodeDetails(pin1);
      final details2 = await _getPincodeDetails(pin2);

      // 2. One or both pincodes failed
      if (details1 == null || details2 == null) {
        _setError("Invalid pincode(s) or unable to fetch details");
        return;
      }

      // 3. Success path
      if (details1['district'] == details2['district']) {
        _result = "Within City";
        _suggestedMode = ServiceMode.incity;
      } else {
        _result = "Outside City";
        _suggestedMode = ServiceMode.outcity;
      }
      _errorMessage = null;
    } catch (e) {
      // 4. Any unexpected exception (network, JSON, etc.)
      _setError("Something went wrong: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> _getPincodeDetails(String pincode) async {
    try {
      final response = await http
          .get(Uri.parse("https://api.postalpincode.in/pincode/$pincode"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint("HTTP ${response.statusCode} for $pincode");
        return null;
      }

      final data = json.decode(response.body);

      if (data is! List || data.isEmpty) {
        return null;
      }

      final first = data[0];
      if (first['Status'] != "Success" ||
          first['PostOffice'] == null ||
          (first['PostOffice'] as List).isEmpty) {
        return null;
      }

      final postOffice = first['PostOffice'][0];
      return {
        "district": postOffice['District']?.toString() ?? "",
        "state": postOffice['State']?.toString() ?? "",
      };
    } catch (e) {
      debugPrint("Error fetching pincode $pincode: $e");
      rethrow; // let the caller decide how to show the error
    }
  }

  void _setError(String message) {
    _result = "";
    _suggestedMode = null;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _result = "";
    _isLoading = false;
    _suggestedMode = null;
    _errorMessage = null;
    notifyListeners();
  }
}