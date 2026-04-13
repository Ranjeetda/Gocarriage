import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import '../ui/model/VehicleType.dart';
import 'URLS.dart';

class DraftVehicleProvider with ChangeNotifier {
  Map<String, dynamic> _vehicleQutation={};
  bool _isLoading = false;

  Map<String, dynamic> get vehicleQutation => _vehicleQutation;
  bool get isLoading => _isLoading;

  Future<void> fetchDraftVehicle(String vehicleId) async {
    _isLoading = true;
    //notifyListeners();

    final url = Uri.parse(URLS.draftVehicle+vehicleId);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      print("========== REQUEST ==========");
      print("URL: $url");
      print("Headers: $headers");
      print("Method: GET");
      print("=============================");

      final response = await http.get(url,headers: headers);

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("==============================");

      final responseData = json.decode(response.body);
      Utils.printFullText("Response Body: ${responseData.toString()}");

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        _vehicleQutation = responseData['data'];
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