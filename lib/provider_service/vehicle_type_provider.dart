import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ui/model/VehicleType.dart';
import 'URLS.dart';

class VehicleTypeProvider with ChangeNotifier {
  List<VehicleType> _vehicleTypes=[];
  bool _isLoading = false;

  List<dynamic> get vehicleTypes => _vehicleTypes;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleType() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.vehicleTypes);

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
        _vehicleTypes = responseData['data'] .map<VehicleType>((e) => VehicleType.fromJson(e))
            .toList();
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