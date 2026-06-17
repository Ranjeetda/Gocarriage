import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class AddDriverProvider with ChangeNotifier {
  bool _isUpdating = false;
  Map<String, dynamic>? _rawResponse;
  String _message = '';

  bool get isUpdating => _isUpdating;
  Map<String, dynamic>? get rawResponse => _rawResponse;
  Map<String, dynamic>? get driverData =>
      _rawResponse?['data'] as Map<String, dynamic>?;
  String get message => _message;

  Future<Map<String, dynamic>?> driverInformation({
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
    final Uri url = Uri.parse(URLS.fetchProfileDriver + driverId);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    debugPrint("🔵 ADD DRIVER REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");

    _isUpdating = true;
    notifyListeners();

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
      debugPrint("Request Body: $body");

      final http.Response response = await http.put(
        url,
        body: body,
        headers: headers,
      );

      debugPrint("🟢 ADD DRIVER RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final Map<String, dynamic> responseData =
      json.decode(response.body) as Map<String, dynamic>;

      _rawResponse = responseData;
      _message = responseData['message']?.toString() ?? '';

      _isUpdating = false;
      notifyListeners();

      return responseData;
    } catch (error) {
      debugPrint("🔴 ADD DRIVER ERROR: $error");
      _isUpdating = false;
      _message = 'Failed to update profile: $error';
      notifyListeners();
      throw Exception('Failed to update profile: $error');
    }
  }
}