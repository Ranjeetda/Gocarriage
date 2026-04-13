import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import 'URLS.dart';

class SignupProvider with ChangeNotifier {
  Future<http.Response> signup(
      String type,
      String name,
      String email,
      String phone,
      String password,
      String address,
      String city,
      String state,
      String pincode,
      String mode,
      String bankName,
      String accountNumber,
      String ifscCode,
      String companyName,
      ) async {

    /// ---------------- URL ----------------
    final Uri url = Uri.parse(
      type == "driver"
          ? URLS.registerDriver
          : type == "customer"
          ? URLS.registerCustomer
          : URLS.registerOwners,
    );

    /// ---------------- HEADERS ----------------
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    /// ---------------- BODY ----------------
    Map<String, dynamic> bodyMap;

    if (type == "driver") {
      bodyMap = {
        "fullName": name,
        "email": email,
        "mobileNo": phone,
        "password": password,
      };
    } else if (type == "owner") {
      bodyMap = {
        "type": mode,
        "ownerName": name,
        "email": email,
        "phone": phone,
        "password": password,
        "companyName": companyName,
      };
    } else if (type == "customer") {
      bodyMap = {
        "customerName": name,
        "email": email,
        "phone": phone,
        "password": password,
        "address": address,
        "city": city,
        "state": state,
        "postalCode": pincode,
      };
    } else {
      throw Exception("Invalid signup type: $type");
    }

    final body = jsonEncode(bodyMap);

    debugPrint("Signup URL: $url");
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
      throw Exception("Signup failed: $e");
    }
  }
}
