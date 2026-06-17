import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import 'URLS.dart';

class SignupProvider with ChangeNotifier {

  Future<http.Response> signup({
    required String type,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String referralCode,
    required String phoneVerificationToken,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String selectedLicense,
    required String mode,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String companyName,

    required String? registered_time_lat,
    required String? registered_time_long,
    required String? location_accuracy,
    required String? device_id,
    required String? device_type,
    required String? app_version,
    required String? registration_source,
  }) async {

    /// ---------------- URL ----------------
    final Uri url = Uri.parse(
      type == "driver"
          ? URLS.registerDriver
          : type == "customer"
          ? URLS.registerCustomer
          : type == "operator"
          ? URLS.registerOperator
          : URLS.registerOwners,
    );

    debugPrint("Signup Type ======== $type");

    /// ---------------- HEADERS ----------------
    final token = PrefUtils.getToken();

    final headers = {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };

    /// ---------------- BODY ----------------
    Map<String, dynamic> bodyMap = {};

    if (type == "driver") {
      bodyMap = {
        "fullName": name,
        "email": email,
        "mobileNo": phone,
        "password": password,
        "license_type": selectedLicense,
        "referralCode": referralCode,
        "phoneVerificationToken": phoneVerificationToken,
      };
    }
    else if (type == "owner") {
      bodyMap = {
        "type": mode,
        "ownerName": name,
        "email": email,
        "phone": phone,
        "password": password,
        "companyName": companyName,
        "referralCode": referralCode,
        "phoneVerificationToken": phoneVerificationToken,
      };
    }
    else if (type == "customer") {
      bodyMap = {
        "customerName": name,
        "email": email,
        "phone": phone,
        "password": password,
        "address": address,
        "city": city,
        "state": state,
        "postalCode": pincode,
        "referralCode": referralCode,
        "phoneVerificationToken": phoneVerificationToken,
      };
    }
    else if (type == "operator") {
      bodyMap = {
        "companyName": companyName,
        "ownerName": name,
        "phone": phone,
        "password": password,
        "role": "operator",
        "type": mode,
        "referralCode": referralCode,
        "phoneVerificationToken": phoneVerificationToken,
      };
    }
    else {
      throw Exception("Invalid signup type: $type");
    }

    /// ---------------- COMMON FIELDS ----------------
    bodyMap.addAll({
      "registered_time_lat": registered_time_lat,
      "registered_time_long": registered_time_long,
      "location_accuracy": location_accuracy,
      "device_id": device_id,
      "device_type": device_type,
      "app_version": app_version,
      "registration_source": registration_source,
    });

    final body = jsonEncode(bodyMap);

    /// ---------------- DEBUG LOGS ----------------
    debugPrint("Signup URL: $url");
    debugPrint("Signup Headers: $headers");
    debugPrint("Signup Body: $body");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint("Signup Status: ${response.statusCode}");
      debugPrint("Signup Response: ${response.body}");

      return response;
    } catch (e) {
      debugPrint("Signup Error: $e");
      throw Exception("Signup failed: $e");
    }
  }
}