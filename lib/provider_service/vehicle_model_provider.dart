import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VehicleModelProvider with ChangeNotifier {
  List<Map<String, dynamic>> _models = [];
  Map<String, dynamic>? _selectedModel;
  bool _isLoading = false;

  List<Map<String, dynamic>> get models => _models;
  Map<String, dynamic>? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;


  /// 🔹 SET SELECTED MODEL (MATCH FROM LIST)
  void setSelectedModelById(int? id) {
    if (id == null) {
      _selectedModel = null;
    } else {
      try {
        _selectedModel = _models.firstWhere(
              (item) => item['id'] == id,
        );
      } catch (e) {
        _selectedModel = null;
      }
    }
    notifyListeners();
  }

  /// 🔹 SET SELECTED MODEL (FULL OBJECT)
  void setSelectedModel(Map<String, dynamic>? model) {
    _selectedModel = model;
    notifyListeners();
  }

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

      if (response.statusCode == 200 && responseData['success'] == true) {
        _models = List<Map<String, dynamic>>.from(responseData['data']['models'],);

        _selectedModel = null; // reset selection

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