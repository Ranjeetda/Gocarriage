
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

class OwnerProfileUpdateProvider with ChangeNotifier {
  bool _isUpdating = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;

  Future<void> updateProfile({
    required String ownerName,
    required String email,
    required String phone,
    required String type,
    required String companyName,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String wa_number,
    required String contactPersonName,
    required String contactPersonEmail,
    required String contactPersonPhone,
    required String panNumber,
    required String aadhaarNumber,
    required String gstNumber,
    required String drivingLicenceNumber,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String branchAddress,
    required String panUpload,
    required String aadhaarUpload,
    required String gstCertificateUpload,
    required String drivingLicenceUpload,
    required String profilePhotoUpload,
    required String cancelCheque,
  }) async {
    final Uri url = Uri.parse(
      URLS.profileOwners + PrefUtils.getUserId(),
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
        "ownerName": ownerName,
        "email": email,
        "phone": phone,
        "type": type,
        "companyName": companyName,
        "address": address,
        "city": city,
        "state": state,
        "postalCode": pinCode,
        "wa_number": wa_number,
        "contactPersonName": contactPersonName,
        "contactPersonEmail": contactPersonEmail,
        "contactPersonPhone": contactPersonPhone,
        "panNumber": panNumber,
        "aadhaarNumber": aadhaarNumber,
        "gstNumber": gstNumber,
        "drivingLicenceNumber": drivingLicenceNumber,
        "bankName": bankName,
        "accountNumber": accountNumber,
        "ifscCode": ifscCode,
        "branchAddress": branchAddress,
        "profile_pic": profilePhotoUpload,
        "aadhaarUpload": aadhaarUpload,
        "panUpload": panUpload,
        "gstCertificateUpload": gstCertificateUpload,
        "drivingLicenceUpload": drivingLicenceUpload,
        "cancel_cheque": cancelCheque,
      };

      final String body = jsonEncode(requestBody);

      debugPrint("Reqeust Body: ${body}");

      final http.Response response =
      await http.put(url, body:body,headers: headers);


      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 VERIFY OTP IN RESPONSE");
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
