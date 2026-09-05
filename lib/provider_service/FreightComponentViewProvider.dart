import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class Freightcomponentviewprovider with ChangeNotifier {
  List<dynamic> _componentsList = [];
  bool _isLoading = false;

  List<dynamic> get componentsList => _componentsList;
  bool get isLoading => _isLoading;

  Future<void> fetchFreightComponent(String freightId) async {
    _isLoading = true;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      final url = Uri.parse(URLS.freightVehicle+freightId);
      debugPrint("➡️ REQUEST URL: $url");
      debugPrint("➡️ REQUEST HEADERS: $headers");

      final response = await http.get(url, headers: headers);

      debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _componentsList = data['data']['components'] ?? [];
        debugPrint("✅ Vehicles loaded: ${_componentsList.length}");
      } else {
        debugPrint("❌ API Error: ${data['message']}");
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _componentsList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}