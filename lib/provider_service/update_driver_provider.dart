import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class UpdateDriverProvider with ChangeNotifier {
  bool _isLoading = false;
  String _message = '';
  bool _success = false;

  bool get isLoading => _isLoading;
  String get message => _message;
  bool get success => _success;

  Future<void> updateDriverProfile({
    required String driverId,
    required String fullName,
    required String email,
    required String licenseNumber,
    required String licenseFromDate,
    required String licenseExpiryDate,
    required String licenseType,
    required String experienceInYrs,
    required String serviceType,
    required String driversLicenseUpload,
    required String profilePicture,
  }) async {
    _isLoading = true;
    _success = false;
    notifyListeners();

    final Uri url = Uri.parse(URLS.fetchProfileDriver + driverId);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final Map<String, dynamic> requestBody = {
      "fullName": fullName,
      "email": email,
      "licenseNumber": licenseNumber,
      "license_from_date": licenseFromDate,
      "license_expiry_date": licenseExpiryDate,
      "license_type": licenseType,
      "experience_in_yrs": experienceInYrs,
      "service_type": serviceType,
      "driversLicenseUpload": driversLicenseUpload,
      "profile_picture": profilePicture,
    };

    try {
      debugPrint("🔵 UPDATE DRIVER PROFILE REQUEST");
      debugPrint("URL: $url");
      debugPrint("Body: ${jsonEncode(requestBody)}");

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      debugPrint("🟢 UPDATE DRIVER PROFILE RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _success = true;
        _message = responseData['message'] ?? 'Profile updated successfully';
      } else {
        _success = false;
        _message = responseData['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      debugPrint("🔴 UPDATE DRIVER PROFILE ERROR: $e");
      _success = false;
      _message = 'An error occurred while updating profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
