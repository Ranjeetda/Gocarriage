import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class VerifyOtpProvider with ChangeNotifier {

  Future<http.Response> verifyOtp(
      String pinCode,
      String bookingId,
      ) async {
    final Uri url = Uri.parse(URLS.driverOtpVerify);

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
        "otp": pinCode,
        "bookingId": bookingId,
      };

      final String body = jsonEncode(requestBody);
      debugPrint("Reqeust Body: ${body}");

      final http.Response response =
      await http.post(url, body:body,headers: headers);


      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 VERIFY OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      if (response.statusCode == 200) {
        return response;
      } else {
        print('VERIFY OTP in failed: ${response.body}');
        return response;
      }

      return response;
    } catch (error) {
      debugPrint("🔴 VERIFY OTP IN ERROR: $error");
      throw Exception('Failed to sign in: $error');
    }
  }
}

