import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class OperatorPermissionListProvider with ChangeNotifier {
  List<dynamic> _permissionList = [];
  bool _isLoading = false;

  List<dynamic> get permissionList => _permissionList;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleTypes() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.operatorPermission);

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
        _permissionList = responseData['data']['permissions']; // ✅ FIXED


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