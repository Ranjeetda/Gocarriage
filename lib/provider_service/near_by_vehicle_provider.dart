import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class NearByVehicleProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>?> fetchNearByVehicle(
      String bookingMode, String lat, String lng) async {

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.nearByVehicle);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final requestBody = {
      "bookingMode": bookingMode,
      "fromLocation": {
        "lat": lat,
        "lng": lng
      }
    };

    /// 🔵 PRINT REQUEST
    debugPrint("========= API REQUEST =========");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: ${jsonEncode(requestBody)}");
    debugPrint("================================");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      /// 🟢 PRINT RESPONSE
      debugPrint("========= API RESPONSE =========");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");
      debugPrint("================================");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          debugPrint("✅ SUCCESS DATA: ${responseData['data']}");
          return responseData;
        } else {
          debugPrint("⚠️ API SUCCESS FALSE: ${responseData['message']}");
          return null;
        }
      } else {
        debugPrint("❌ SERVER ERROR: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint('❌ EXCEPTION: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
