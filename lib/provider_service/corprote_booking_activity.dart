import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class CorproteBookingActivity with ChangeNotifier {

  List<dynamic> _bookingActivityData = [];
  bool _isLoading = false;

  List<dynamic> get bookingActivityData => _bookingActivityData;
  bool get isLoading => _isLoading;

  Future<void> fetchBookingActivity() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse("${URLS.normalCustomerBookingActivity}5");

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    try {
      final response = await http.get(url, headers: headers);

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["success"] == true) {
          _bookingActivityData = responseData["data"]?["activities"] ?? [];
        } else {
          _bookingActivityData = [];
          print(responseData["message"]);
        }
      } else if (response.statusCode == 401) {
        _bookingActivityData = [];
        print("Unauthorized: Token expired or invalid.");
      } else {
        _bookingActivityData = [];
        print("API Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      _bookingActivityData = [];
      print("Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}
