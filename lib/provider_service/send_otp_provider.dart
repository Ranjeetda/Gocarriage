import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class SendOtpProvider with ChangeNotifier {
  Future<http.Response> sendOtp(String phone) async {
    final Uri url = Uri.parse(URLS.sendOtp);

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"phone": phone});

    debugPrint("🔵 SEND OTP IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint("🟢 SEND OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    }

    /// 🔴 No Internet / DNS issue
    on SocketException catch (e) {
      debugPrint("🔴 SOCKET ERROR: $e");

      return http.Response(
        jsonEncode({
          "status": false,
          "message": "No internet or server not reachable",
        }),
        503,
      );
    }

    /// 🔴 Timeout
    on TimeoutException catch (e) {
      debugPrint("🔴 TIMEOUT ERROR: $e");

      return http.Response(
        jsonEncode({
          "status": false,
          "message": "Request timeout, try again",
        }),
        504,
      );
    }

    /// 🔴 Other errors
    catch (error) {
      debugPrint("🔴 UNKNOWN ERROR: $error");

      return http.Response(
        jsonEncode({
          "status": false,
          "message": "Something went wrong",
        }),
        500,
      );
    }
  }
}