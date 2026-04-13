import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class HelpSupportProvider with ChangeNotifier {


  Future<Map<String, dynamic>> sendHelpSupportRequestService(String name,String email,String mobile,String message) async {
    final url = Uri.parse(URLS.HelpSupport);

    try {
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'id': PrefUtils.getUserId(),
        'customerKey': PrefUtils.getToken(),
      });

      request.fields.addAll({
        "name": name,
        "email": email,
        "mobile": mobile,
        "message": message,
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);
      print("Response Help & Support: $responseData");

      if (response.statusCode == 200 && responseData['code'] == '200') {
        return responseData; // ✅ returning Map
      } else {
        notifyListeners();
        throw Exception(
            responseData['message'] ?? 'Failed to  Help & Support.');
      }
    } catch (e) {
      print('Error fetching Request Help & Support: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

}
