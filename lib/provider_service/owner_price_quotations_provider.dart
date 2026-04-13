import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import '../ui/model/VehicleType.dart';
import 'URLS.dart';

class OwnerPriceQuotationsProvider with ChangeNotifier {
  List<dynamic> _priceQutation=[];
  bool _isLoading = false;

  List<dynamic> get priceQutation => _priceQutation;
  bool get isLoading => _isLoading;

  Future<void> fetchPriceQuotation() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.quatationsService);

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
      print("Body: ${response.body}");
      print("==============================");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        _priceQutation = responseData['data'];
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