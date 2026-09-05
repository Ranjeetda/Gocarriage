import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class CreateCorporateProvider with ChangeNotifier {
  bool _isUpdating = false;
  bool _success = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;

  bool get success => _success;

  Future<void> createCorporate({
    required String companyName,
    required String companyType,
    required String registeredAddress,
    required String city,
    required String state,
    required String postalCode,
    required String mobileNumber,
    required String gstNumber,
    required String companyEmail,
    required String gstUpload,
  }) async {
    final Uri url = Uri.parse(
      URLS.fetchProfileCustomer + PrefUtils.getUserId(),
    );

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
        "companyName": companyName,
        "companyType": companyType,
        "registeredAddress": registeredAddress,
        "city": city,
        "state": state,
        "postalCode": postalCode,
        "mobileNumber": mobileNumber,
        "gstNumber": gstNumber,
        "companyEmail": companyEmail,
        "gstCertificateUpload": gstUpload,
      };

      final String body = jsonEncode(requestBody);

      debugPrint("Reqeust Body: ${body}");

      final http.Response response = await http.put(
        url,
        body: body,
        headers: headers,
      );

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Update profile  RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _message = responseData['message'] ?? 'Profile updated successfully';
      } else {
        _message = responseData['message'] ?? 'Failed to update profile';
      }
    } catch (error) {
      debugPrint("🔴 Update profile In ERROR: $error");
      throw Exception('Failed to Update profile in: $error');
    }
  }
}
