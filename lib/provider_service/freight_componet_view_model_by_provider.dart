import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class FreightComponetViewModelByProvider with ChangeNotifier {
  Map<String, dynamic> _freightData = {};

  bool _isLoading = false;

  Map<String, dynamic> get freightData => _freightData;
  bool get isLoading => _isLoading;

  Future<void> fetchFreightComponent({
    required String modelId,
    required String modelName,
  }) async {
    _isLoading = true;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    try {
      final uri = Uri.parse(URLS.freightFleetModel).replace(
        queryParameters: {
          "vehicle_model_id": modelId,
          "model_name": modelName,
        },
      );

      debugPrint("➡️ REQUEST URL: $uri");

      final response = await http.get(
        uri,
        headers: headers,
      );

      debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        if (decoded["success"] == true) {
          // ALL API DATA
          _freightData = decoded['data'];

          debugPrint("✅ Full data loaded");
          debugPrint("DATA: $_freightData");
        } else {
          _freightData = {};
          throw Exception(
            decoded["message"] ?? "API returned success=false",
          );
        }
      } else {
        _freightData = {};
        throw Exception("Invalid API response");
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _freightData = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}