import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class VerifyOtpProvider with ChangeNotifier {

  Future<http.Response> verifyOtp(String phone,String otp) async {
    final Uri url = Uri.parse(URLS.verifyOtp);

    final Map<String, String> headers = {"Content-Type": "application/json"};

    final Map<String, dynamic> requestBody = {"phone": phone,"otp": otp};

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 SEND OTP IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Verify OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Verify OTP IN ERROR: $error");
      throw Exception('Failed to Verify otp in: $error');
    }
  }
}
