import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VehicleModelProvider with ChangeNotifier {
  List<dynamic> _vehicleTypesData = [];
  bool _isLoading = false;

  List<dynamic> get vehicleTypesData => _vehicleTypesData;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleModel(String brand) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.vehicleModel+brand);

    try {
      print("========== REQUEST ==========");
      print("URL: $url");
      print("Method: GET");
      print("=============================");

      final response = await http.get(url);

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body}");
      print("==============================");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        _vehicleTypesData = responseData['data'];
        notifyListeners();
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to load vehicle types.',
        );
      }
    } catch (e) {
      print("========== ERROR ==========");
      print("Error fetching vehicle types: $e");
      print("===========================");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}