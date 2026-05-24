import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ui/model/VehicleType.dart';
import '../ui/model/vehicle_option.dart';
import 'URLS.dart';

class VehicleTypeProvider with ChangeNotifier {
  List<VehicleType> _vehicleTypes = [];
  bool _isLoading = false;

  String? _selectedGroup;
  int? _selectedVehicleId;
  String? _selectedVehicleName;

  List<VehicleType> get vehicleTypes => _vehicleTypes;
  bool get isLoading => _isLoading;

  int? get selectedVehicleId => _selectedVehicleId;
  String? get selectedVehicleName => _selectedVehicleName;

  void setSelectedGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void setSelectedVehicle(int? id, String? name) {
    _selectedVehicleId = id;
    _selectedVehicleName = name;
    notifyListeners();
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

        // Default selection
        _selectedGroup ??= _vehicleTypes.isNotEmpty
            ? _vehicleTypes.first.group
            : null;

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


  void applyFareResponse(Map<String, dynamic> fareResponse) {
    final fares = fareResponse['data']?['fares'] ?? [];

    if (fares.isEmpty) return;

    final int vehicleTypeId = fares[0]['vehicle_type_id'];

    for (var group in _vehicleTypes) {
      for (var option in group.options) {
        if (option.id == vehicleTypeId) {
          _selectedGroup = group.group;
          _selectedVehicleId = option.id;
          _selectedVehicleName = option.name; // ✅ FIX
          notifyListeners();
          return;
        }
      }
    }
  }
}