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

class AddDriverProvider with ChangeNotifier {
  bool _isUpdating = false;
  bool _success = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;
  bool get success => _success;

  Future<void> driverInformation({
    required String fullName,
    required String email,
    required String mobileNo,
    required String licenseNumber,
    required String license_expiry_date,
    required String license_from_date,
    required String experience_in_yrs,
    required String vehicle_type_preference,
    required String service_type,
    required String driversLicenseUpload,
    required String profile_picture,
    required String driverId,
  }) async {
    final Uri url = Uri.parse(URLS.fetchProfileDriver+driverId);

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
        "fullName": fullName,
        "email": email,
        "mobileNo": mobileNo,
        "licenseNumber": licenseNumber,
        "license_expiry_date": license_expiry_date,
        "license_from_date": license_from_date,
        "experience_in_yrs": experience_in_yrs,
        "vehicle_type_preference": vehicle_type_preference,
        "service_type": service_type,
        "driversLicenseUpload": driversLicenseUpload,
        "profile_picture": profile_picture,
      };

      final String body = jsonEncode(requestBody);

      debugPrint("Reqeust Body: ${body}");

      final http.Response response = await http.put(
        url,
        body: body,
        headers: headers,
      );

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 VERIFY OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      final responseData = json.decode(response.body);
      _success= responseData['success'];
      if (response.statusCode == 200 && _success == true) {
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
