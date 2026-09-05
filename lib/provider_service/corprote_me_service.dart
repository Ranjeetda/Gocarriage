
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class CorproteMeService with ChangeNotifier {

  Map<String, dynamic>? _corporateMe;
  bool _isLoading = false;

  // Getters
  Map<String, dynamic>? get corporateMe => _corporateMe;
  bool get isLoading => _isLoading;

  /// 🔹 Fetch Ongoing Booking
  Future<void> fetchCorproteMe() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.normalCustomerCorporateMe);

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
          _corporateMe = responseData['data'];
        } else {
          debugPrint('⚠️ API MESSAGE: ${responseData['message']}');
          _corporateMe = null;
        }

      } else {
        debugPrint('❌ Server Error: ${response.statusCode}');
        _corporateMe = null;
      }

    } catch (e) {
      debugPrint('❌ Exception Error: $e');
      _corporateMe = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}