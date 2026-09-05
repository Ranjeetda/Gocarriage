import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class FreightVehicleProvider with ChangeNotifier {
  List<dynamic> _vehicleList = [];
  bool _isLoading = false;

  List<dynamic> get vehicleList => _vehicleList;
  bool get isLoading => _isLoading;

  Future<void> fetchFreightVehicleList() async {
    _isLoading = true;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      final url = Uri.parse(URLS.freightVehicleModels);
      debugPrint("➡️ REQUEST URL: $url");
      debugPrint("➡️ REQUEST HEADERS: $headers");

      final response = await http.get(url, headers: headers);

      debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _vehicleList = data['data'] ?? [];
        debugPrint("✅ Vehicles loaded: ${_vehicleList.length}");
      } else {
        debugPrint("❌ API Error: ${data['message']}");
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _vehicleList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}