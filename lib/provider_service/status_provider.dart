import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import 'URLS.dart';

class StatusProvider with ChangeNotifier {

  Future<http.Response> statusUpdate(bool isOnline, String latitude, String longitude) async {

    final url = Uri.parse(isOnline==true?URLS.onlineDriver:URLS.offlineDriver);

    final headers = {
      "Content-Type": "application/json",
      'Authorization': "Bearer ${PrefUtils.getToken()}",
    };

    final body = {
    };

    // "isOnline": isOnline, "latitude": latitude, "longitude": longitude
    // ----------- PRINT REQUEST -----------
    print("=========== STATUS UPDATE -IN REQUEST ===========");
    print("URL: $url");
    print("Headers: ${jsonEncode(headers)}");
    print("Request Body: ${jsonEncode(body)}");
    print("=======================================");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      // ----------- PRINT RESPONSE -----------
      print("=========== ONLINE OFFLINE -IN RESPONSE ===========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("========================================");

      return response;

    } catch (error) {
      print("=========== STATUS UPDATE ERROR ===========");
      print("Error: $error");
      print("=====================================");
      throw Exception('Failed to sign in: $error');
    }
  }
}
