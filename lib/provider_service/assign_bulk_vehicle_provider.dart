import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class AssignBulkVehicleProvider with ChangeNotifier {

  Future<http.Response> acceptBooking(
      String fleetId,
      String bulkOrderId,
      String status,
      ) async {
    final Uri url = Uri.parse("${URLS.tenderBooking}/$bulkOrderId/$status");

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };


    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Area IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");

    try {
      final Map<String, dynamic> requestBody = {
        "fleet_id": fleetId,
      };

      final String body = jsonEncode(requestBody);
      debugPrint("Request Body: ${body}");

      final http.Response response =
      await http.post(url, body:body,headers: headers);


      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Assign Bulk Vehicle IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      if (response.statusCode == 200) {
        return response;
      } else {
        print('Assign Bulk Vehicle in failed: ${response.body}');
        return response;
      }

      return response;
    } catch (error) {
      debugPrint("🔴 Assign Bulk Vehicle IN ERROR: $error");
      throw Exception('Failed to sign in: $error');
    }
  }
}

