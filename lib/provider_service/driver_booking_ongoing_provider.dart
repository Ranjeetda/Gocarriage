import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class DriverBookingOngoingProvider with ChangeNotifier {

  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;

  // Getters
  Map<String, dynamic>? get bookingData => _bookingData;
  bool get isLoading => _isLoading;

  /// 🔹 Fetch Ongoing Booking
  Future<void> fetchBooking() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.driverOngoingHistory);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      debugPrint('📤 REQUEST');
      debugPrint('URL: $url');
      debugPrint('HEADERS: $headers');

      final response = await http.get(url, headers: headers);

      debugPrint('📥 RESPONSE');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode == 200) {

        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _bookingData = responseData['data'];
        } else {
          debugPrint('⚠️ API MESSAGE: ${responseData['message']}');
          _bookingData = null;
        }

      } else {
        debugPrint('❌ Server Error: ${response.statusCode}');
        _bookingData = null;
      }

    } catch (e) {
      debugPrint('❌ Exception Error: $e');
      _bookingData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Clear Booking Data (Instead of provider.bookingData = null)
  void clearBooking() {
    _bookingData = null;
    notifyListeners();
  }
}