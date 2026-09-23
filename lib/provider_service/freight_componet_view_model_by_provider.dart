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

      // ================= REQUEST =================
      debugPrint("========== API REQUEST ==========");
      debugPrint("URL      : $uri");
      debugPrint("Method   : GET");
      debugPrint("Headers  : $headers");
      debugPrint("Query    : ${uri.queryParameters}");
      debugPrint("================================");

      final response = await http.get(uri, headers: headers);

      // ================= RESPONSE =================
      debugPrint("========== API RESPONSE ==========");
      debugPrint("Status Code : ${response.statusCode}");
      debugPrint("Body        : ${response.body}");
      debugPrint("=================================");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        if (decoded["success"] == true) {
          _freightData = decoded["data"];

          debugPrint("✅ Success");
          debugPrint("Freight Data: $_freightData");
        } else {
          _freightData = {};
          debugPrint("❌ API Message: ${decoded["message"]}");
          throw Exception(decoded["message"] ?? "API returned success=false");
        }
      } else {
        _freightData = {};
        throw Exception("Invalid API response");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Exception: $e");
      debugPrint("StackTrace: $stackTrace");
      _freightData = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFreightByFleetId({
    required String fleetId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    try {
      final uri = Uri.parse("${URLS.baseUrl}/freight/fleet/$fleetId");

      debugPrint("========== API REQUEST (BY FLEET ID) ==========");
      debugPrint("URL      : $uri");
      debugPrint("Method   : GET");
      debugPrint("Headers  : $headers");
      debugPrint("================================");

      final response = await http.get(uri, headers: headers);

      debugPrint("========== API RESPONSE (BY FLEET ID) ==========");
      debugPrint("Status Code : ${response.statusCode}");
      debugPrint("Body        : ${response.body}");
      debugPrint("=================================");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        if (decoded["success"] == true) {
          _freightData = decoded["data"];
          debugPrint("✅ Success");
        } else {
          _freightData = {};
          debugPrint("❌ API Message: ${decoded["message"]}");
        }
      } else {
        _freightData = {};
        debugPrint("❌ Invalid response or status code");
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
