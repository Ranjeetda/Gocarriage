import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class OperatorVechileRequest with ChangeNotifier {

  List<dynamic> _vehicleRequestList = [];
  bool _isLoading = false;

  List<dynamic> get vehicleRequestList => _vehicleRequestList;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleRequest() async {

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.operatorVehicleRequestList);

    try {

      final Map<String, dynamic> requestBody = {
        "operator_id": PrefUtils.getUserId(),
      };

      print("========== REQUEST ==========");
      print("URL: $url");
      print("Method: POST");
      print("Request Body: $requestBody");
      print("=============================");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body}");
      print("==============================");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {

        _vehicleRequestList = responseData['data'];

      } else {

        throw Exception(
          responseData['message'] ?? 'Failed to load vehicle request.',
        );
      }

    } catch (e) {

      print("========== ERROR ==========");
      print("Error: $e");
      print("===========================");

    } finally {

      _isLoading = false;
      notifyListeners();

    }
  }
}