import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ui/model/VehicleType.dart';
import 'URLS.dart';

class VehicleTypeProvider with ChangeNotifier {
  List<VehicleType> _vehicleTypes = [];
  bool _isLoading = false;

  String? _selectedGroup;
  int? _selectedVehicleId;

  List<VehicleType> get vehicleTypes => _vehicleTypes;
  bool get isLoading => _isLoading;

  String? get selectedGroup => _selectedGroup;
  int? get selectedVehicleId => _selectedVehicleId;

  void setSelectedGroup(String group) {
    _selectedGroup = group;
    _selectedVehicleId = null; // reset vehicle
    notifyListeners();
  }

  void setSelectedVehicle(int? id) {
    _selectedVehicleId = id;
    notifyListeners();
  }

  VehicleType? get selectedVehicleGroup {
    if (_selectedGroup == null) return null;

    try {
      return _vehicleTypes.firstWhere(
            (e) => e.group == _selectedGroup,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchVehicleType() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(URLS.vehicleTypes));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List list = data['data'] ?? [];

        _vehicleTypes =
            list.map((e) => VehicleType.fromJson(e)).toList();

        // ✅ Auto-select default group
        _selectedGroup ??= "Small Commercial Vehicles";

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