import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class OpratorSearchRegistrationNumber with ChangeNotifier {

  Map<String, dynamic>? _vehicleNumberData;
  bool _isLoading = false;

  Map<String, dynamic>? get vehicleNumberData => _vehicleNumberData;
  bool get isLoading => _isLoading;

  Future<void> fetchSearchRegistration(String number) async {

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.searchRegistrationNumber + number);

    try {

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      print("Request URL: $url");
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      final responseData = json.decode(response.body);

      /// Handle both success and error responses
      if (response.statusCode == 200 || response.statusCode == 404) {

        _vehicleNumberData = responseData;

      } else {

        _vehicleNumberData = {
          "success": false,
          "message": "Server error (${response.statusCode})"
        };

      }

    } catch (e) {

      print("Error fetching vehicle: $e");

      _vehicleNumberData = {
        "success": false,
        "message": "Something went wrong"
      };

    } finally {

      _isLoading = false;
      notifyListeners();

    }
  }
}