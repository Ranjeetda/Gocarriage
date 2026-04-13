import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class VehicleDetailsProvider with ChangeNotifier {
  Map<String, dynamic>? _vehicleDetailsData;
  bool _isLoading = false;

  // Getters
  Map<String, dynamic>? get vehicleDetailsData => _vehicleDetailsData;

  bool get isLoading => _isLoading;

  /// 🔹 Fetch Ongoing Booking
  Future<void> fetchBooking(String vehicleId) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.vehicleDetails+vehicleId);

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
          _vehicleDetailsData = responseData['data'];
        } else {
          debugPrint('⚠️ API MESSAGE: ${responseData['message']}');
          _vehicleDetailsData = null;
        }
      } else {
        debugPrint('❌ Server Error: ${response.statusCode}');
        _vehicleDetailsData = null;
      }
    } catch (e) {
      debugPrint('❌ Exception Error: $e');
      _vehicleDetailsData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Clear Booking Data (Instead of provider.bookingData = null)
  void clearBooking() {
    _vehicleDetailsData = null;
    notifyListeners();
  }
}
