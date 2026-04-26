import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class DriverBookingHistoryFullProvider with ChangeNotifier {
  List<dynamic> _bookingData = [];
  bool _isLoading = false;

  List<dynamic> get bookingData => _bookingData;
  bool get isLoading => _isLoading;

  Future<void> fetchBooking() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.driverBookingHistoryFull);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    // 🔹 PRINT REQUEST
    print('----- API REQUEST -----');
    print('URL: $url');
    print('Headers: $headers');
    print('Method: GET');
    print('-----------------------');

    try {
      final response = await http.get(url, headers: headers);

      // 🔹 PRINT RESPONSE
      print('----- API RESPONSE -----');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('------------------------');

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        _bookingData = responseData['data']['bookings'];
      } else {
        _bookingData = responseData['data']['bookings'];
      }
    } catch (e) {
      print('❌ Error fetching booking: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}
