import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import 'URLS.dart';

class OwnerVehicleAssignProvider with ChangeNotifier {
  Future<http.Response> postAssignVehicle(
      String driverId,
      String vehicleId,
      ) async {
    final Uri url = Uri.parse(URLS.login);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      "driverId": driverId,
      "vehicleId": vehicleId,
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Assign Vehicle IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Assign Vehicle IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Assign Vehicle IN ERROR: $error");
      throw Exception('Failed to sign in: $error');
    }
  }
}
