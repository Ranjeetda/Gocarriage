import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import 'URLS.dart';

class EmailVerifyOtpProvider with ChangeNotifier {

  Future<http.Response> verifyOtpEmail(
      String email,
      String otp,
      ) async {
    final Uri url = Uri.parse(URLS.driverEmailVerifyOtp);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      "email": email,
      "otp": otp
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Email OTP IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Email OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Email OTP IN ERROR: $error");
      throw Exception('Failed to email otp in: $error');
    }
  }
}
