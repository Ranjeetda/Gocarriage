import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import '../resource/pref_utils.dart';
import 'URLS.dart';

class ForgotPasswordProvider with ChangeNotifier {
  Future<http.Response> forgotPassword(
      String emailOrPhone,
      ) async {
    final Uri url = Uri.parse(URLS.forgotPassword);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
        "email": emailOrPhone,
        "role": PrefUtils.getRole(),
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Forgot Password IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Forgot Password IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Forgot Password IN ERROR: $error");
      throw Exception('Failed to Forgot Password in: $error');
    }
  }
}
