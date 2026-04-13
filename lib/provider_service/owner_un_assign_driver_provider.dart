import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import 'URLS.dart';

class OwnerUnAssignDriverProvider with ChangeNotifier {

  Future<http.Response> unAssignDriver(
      String driverId,
      ) async {
    final Uri url = Uri.parse(URLS.unAssignDriver);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      "driverId": driverId,
      "ownerId": PrefUtils.getUserId()
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Un Assign Vehicle Driver IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Un Assign Vehicle Driver IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Un Assign Vehicle Driver IN ERROR: $error");
      throw Exception('Failed to Un Assign Vehicle Driver in: $error');
    }
  }
}
