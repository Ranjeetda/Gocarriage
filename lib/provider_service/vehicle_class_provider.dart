import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../screens/model/VehicleClass.dart';
import 'URLS.dart';

class VehicleClassProvider with ChangeNotifier {
  List<VehicleClass> _classes = [];
  String? _selectedClass;

  List<VehicleClass> get classes => _classes;
  String? get selectedClass => _selectedClass;

  Future<void> fetchClasses() async {
    final response = await http.get(
      Uri.parse(URLS.vehicleModelClass),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _classes = (data['data']['classes'] as List)
            .map((e) => VehicleClass.fromJson(e))
            .toList();
        notifyListeners();
      }
    }
  }

  void setSelectedClass(String? value) {
    _selectedClass = value;
    notifyListeners();
  }
}