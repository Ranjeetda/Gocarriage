import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'URLS.dart';

class SearchDriverProvider with ChangeNotifier {
  Map<String, dynamic> _driverListData = {};
  bool _isLoading = false;

  Map<String, dynamic> get driverListData => _driverListData;
  bool get isLoading => _isLoading;

  Future<void> fetchDriver(String phone) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse("${URLS.searchDriverByPhone}/$phone");

    try {
      if (kDebugMode) {
        print("========== REQUEST ==========");
        print("URL: $url");
        print("Method: GET");
        print("=============================");
      }

      final response = await http.get(url);

      if (kDebugMode) {
        print("========== RESPONSE ==========");
        print("Status Code: ${response.statusCode}");
        print("Body: ${response.body}");
        print("==============================");
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        _driverListData = responseData;
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to load driver.');
      }
    } catch (e) {
      if (kDebugMode) {
        print("========== ERROR ==========");
        print("Error fetching driver: $e");
        print("===========================");
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}