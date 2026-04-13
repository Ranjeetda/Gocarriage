import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';



class OperatorVehiclePostRequestProvider with ChangeNotifier {

  Future<http.Response> postVehicleRequest(
      String vehicleId, List<dynamic> requestedPermissionIds) async {

    final Uri url = Uri.parse(URLS.operatorVehicleRequest);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      "operator_id": PrefUtils.getUserId(),
      "vehicle_id": vehicleId,
      "requested_permission_ids": requestedPermissionIds,
    };

    final String body = jsonEncode(requestBody);

    print("========== REQUEST ==========");
    print("URL: $url");
    print("Method: POST");
    print("Request Body: $requestBody");
    print("=============================");

    try {

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint("🟢 Vehicle request RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;

    } catch (error) {

      debugPrint("🔴 Vehicle request ERROR: $error");
      throw Exception('Failed to vehicle request: $error');

    }
  }
}