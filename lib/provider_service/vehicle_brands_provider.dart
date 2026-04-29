import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ui/model/VehicleType.dart';
import 'URLS.dart';

class VehicleBrandsProvider with ChangeNotifier {
  List<String> _vehicleBrands = [];
  String? _selectedBrand;
  bool _isLoading = false;

  List<String> get vehicleBrands => _vehicleBrands;
  String? get selectedBrand => _selectedBrand;
  bool get isLoading => _isLoading;

  void setSelectedBrand(String value) {
    _selectedBrand = value;
    notifyListeners();
  }

  Future<void> fetchBrands() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(URLS.vehicleBrand));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _vehicleBrands = List<String>.from(data['data']['brands']);
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