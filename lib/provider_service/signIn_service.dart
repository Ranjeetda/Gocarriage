import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import '../resource/pref_utils.dart';
import 'URLS.dart';

class SignInProvider with ChangeNotifier {
  Future<http.Response> signIn(
    String emailOrPhone,
    String password,
    String deviceToken,
    String deviceType,
  ) async {
    final Uri url = Uri.parse(URLS.login);

    final Map<String, String> headers = {"Content-Type": "application/json"};

    final Map<String, dynamic> requestBody = {
      if (Utils.isEmail(emailOrPhone))
        "email":emailOrPhone
      else
        "phone": emailOrPhone,
      "password": password,
      "device_token": deviceToken,
      "device_type": "Android",
      "role": PrefUtils.getRole(),
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 SIGN IN REQUEST");
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
      debugPrint("🟢 SIGN IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 SIGN IN ERROR: $error");
      throw Exception('Failed to sign in: $error');
    }
  }
}
