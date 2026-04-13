import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import 'URLS.dart';

class OwnerUnassignDriverVehicle with ChangeNotifier {

  Future<http.Response> unAssignDriver(
      String driverId,
      String vehicleId,
      ) async {
    final Uri url = Uri.parse(URLS.unAssignVehicle);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      "driverId": driverId,
      "vehicleId":vehicleId,
      "ownerId": PrefUtils.getUserId()
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 AssignDriver IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 AssignDriver IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 AssignDriver IN ERROR: $error");
      throw Exception('Failed to AssignDriver in: $error');
    }
  }
}
