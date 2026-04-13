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

class UpdateProfileProvider with ChangeNotifier {
  bool _isUpdating = false;
  bool _success = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;
  bool get success => _success;

  Future<void> updateProfile({
    required String customerName,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String panNumber,
    required String gstNumber,
    required String profileImage,
    required String panUpload,
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
        "customerName": customerName,
        "email": email,
        "phone": phone,
        "address": address,
        "city": city,
        "state": state,
        "postalCode": pinCode,
        "panNumber": panNumber,
        "gstNumber": gstNumber,
        "profileImage": profileImage,
        "panUpload": panUpload,
        "gstUpload": gstUpload,
      };

      final String body = jsonEncode(requestBody);

      debugPrint("Reqeust Body: ${body}");

      final http.Response response =
      await http.put(url, body:body,headers: headers);


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
