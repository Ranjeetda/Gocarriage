import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import '../resource/Utils.dart';
import 'URLS.dart';

class OperatorProfileUpdateProvider with ChangeNotifier {
  bool _isUpdating = false;
  String _message = '';
  bool _success = false;

  bool get isUpdating => _isUpdating;

  String get message => _message;

  bool get success => _success;

  Future<Map<String, dynamic>> updateProfile({
    required String ownerName,
    required String email,
    required String companyName,
    required String contactPersonName,
    required String contactPersonEmail,
    required String contactPersonPhone,
    required String whatsappNumber,
    required String address,
    required String addressLine2,
    required String state,
    required String postalCode,
    required String city,
    required String panNumber,
    required String aadhaarNumber,
    required String gstNumber,
    required String drivingLicenceNumber,
    required String ifscCode,
    required String bankName,
    required String accountNumber,
    required String branchAddress,
    required String panUpload,
    required String aadhaarUpload,
    required String gstCertificateUpload,
    required String drivingLicenceUpload,
  }) async {
    _isUpdating = true;
    notifyListeners();

    final Uri url = Uri.parse("${URLS.registerOperator}/${PrefUtils.getUserId()}");

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    debugPrint("🔵 UPDATE PROFILE REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");

    try {
      final Map<String, dynamic> requestBody = {
        "ownerName": ownerName,
        "email": email,
        "companyName": companyName,
        "contactPersonName": contactPersonName,
        "contactPersonEmail": contactPersonEmail,
        "contactPersonPhone": contactPersonPhone,
        "whatsappNumber": whatsappNumber,
        "address": address,
        "addressLine2": addressLine2,
        "state": state,
        "postalCode": postalCode,
        "city": city,
        "panNumber": panNumber,
        "aadhaarNumber": aadhaarNumber,
        "gstNumber": gstNumber,
        "drivingLicenceNumber": drivingLicenceNumber,
        "ifscCode": ifscCode,
        "bankName": bankName,
        "accountNumber": accountNumber,
        "branchAddress": branchAddress,

        /// ✅ Only include if not empty
        if (aadhaarUpload.isNotEmpty) "aadhaarUpload": aadhaarUpload,

        if (panUpload.isNotEmpty) "panUpload": panUpload,

        if (gstCertificateUpload.isNotEmpty)
          "gstCertificateUpload": gstCertificateUpload,

        if (drivingLicenceUpload.isNotEmpty)
          "drivingLicenceUpload": drivingLicenceUpload,
      };

      final String body = jsonEncode(requestBody);

      debugPrint("Request Body: $body");

      final http.Response response = await http.put(
        url,
        body: body,
        headers: headers,
      );

      debugPrint("🟢 RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      Utils.printFullText("Response Body: ${response.body}");

      final responseData = json.decode(response.body);

      _success = responseData['success'] ?? false;

      if (response.statusCode == 200 && _success) {
        _message = responseData['message'] ?? 'Profile updated successfully';
      } else {
        _message = responseData['message'] ?? 'Failed to update profile';
      }

      _isUpdating = false;
      notifyListeners();

      return responseData;
    } catch (error) {
      debugPrint("🔴 ERROR: $error");

      _isUpdating = false;
      _success = false;
      _message = "Something went wrong";
      notifyListeners();

      return {"success": false, "message": error.toString()};
    }
  }
}
