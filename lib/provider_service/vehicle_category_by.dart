import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VehicleCategoryBy with ChangeNotifier {
  List<dynamic> _vehicleCategaryBy = [];
  List<String> _brands = [];
  bool _isLoading = false;

  String? _selectedBrand;
  String? _selectedModel;

  List<dynamic> get vehicleCategaryBy => _vehicleCategaryBy;
  List<String> get brands => _brands;
  bool get isLoading => _isLoading;

  String? get selectedBrand => _selectedBrand;
  String? get selectedModel => _selectedModel;

  /// 🔹 Set Brand
  void setSelectedBrand(String? brand) {
    _selectedBrand = brand;
    _selectedModel = null; // reset model
    notifyListeners();
  }

  /// 🔹 Set Model
  void setSelectedModel(String? model) {
    _selectedModel = model;
    notifyListeners();
  }

  /// 🔹 Filter models by brand
  List<dynamic> get filteredModels {
    if (_selectedBrand == null) return [];

    final seenModels = <String>{};

    return _vehicleCategaryBy.where((item) {
      final isSameBrand = item['brand'] == _selectedBrand;
      final model = item['model'].toString();

      if (isSameBrand && !seenModels.contains(model)) {
        seenModels.add(model);
        return true;
      }
      return false;
    }).toList();
  }

  /// 🔹 API CALL
  Future<void> fetchVehicleCategryBy(String id) async {
    _isLoading = true;
    _selectedBrand = null;
    _selectedModel = null;
    notifyListeners();

    final url = Uri.parse("${URLS.vehicleCategoryBy}$id");

    try {
      print("========== REQUEST ==========");
      print("URL: $url");
      print("=============================");

      final response = await http.get(url);

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");
      print("==============================");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _vehicleCategaryBy = data['data']['models'] ?? [];

        /// 🔹 Extract unique brands
        final brandSet = <String>{};
        for (var item in _vehicleCategaryBy) {
          if (item['brand'] != null) {
            brandSet.add(item['brand']);
          }
        }

        _brands = brandSet.toList();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}