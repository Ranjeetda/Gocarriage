import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';

class FareCalculateProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _fareData;
  Map<String, dynamic>? get fareData => _fareData;

  String? _error;
  String? get error => _error;

  Future<Map<String, dynamic>?> fetchFareCalculate(
      String clusterId, String totalDistance, List<int> vehicleTypeIds) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse(URLS.fareCalculate);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final requestBody = {
      "cluster_id": int.parse(clusterId),
      "total_distance": double.parse(totalDistance),
      "vehicle_type_ids": vehicleTypeIds
    };

    try {
      print("📤 REQUEST URL: $url");
      print("📤 REQUEST BODY: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        debugPrint("📥 DECODED RESPONSE:");
        debugPrint(const JsonEncoder.withIndent('  ').convert(responseData));

        if (responseData['success'] == true) {
          _fareData = responseData;

          print("✅ SUCCESS: Fare fetched");
          print("💰 Fare Data: ${responseData['data']}");

          return responseData;
        } else {
          _error = responseData['message'] ?? "Something went wrong";
          print("❌ API ERROR: $_error");
          return null;
        }
      } else {
        _error = "Server error: ${response.statusCode}";
        print("❌ SERVER ERROR: $_error");
        return null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ EXCEPTION: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}