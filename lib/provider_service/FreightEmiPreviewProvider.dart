import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class FreightEmiPreviewProvider with ChangeNotifier {
  Map<String, dynamic>? _emiDefaultData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get emiDefaultData => _emiDefaultData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters
  double get financedAmount =>
      (_emiDefaultData?['data']?['financed_amount'] as num?)?.toDouble() ?? 0;
  double get emiPerMonth =>
      (_emiDefaultData?['data']?['emi_per_month'] as num?)?.toDouble() ?? 0;
  double get emiPerDay =>
      (_emiDefaultData?['data']?['emi_per_day'] as num?)?.toDouble() ?? 0;

  Future<void> fetchEmiPreview({
    required String onRoadPrice,
    required String downPaymentPercent,
    required String interestRatePercent,
    required String tenureMonths,
  }) async {
    // Skip empty / invalid calls
    if (onRoadPrice.isEmpty ||
        double.tryParse(onRoadPrice) == null ||
        double.parse(onRoadPrice) <= 0) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse(URLS.freightEmiPreview);
    final headers = {
      "Content-Type": "application/json",
      'Authorization': PrefUtils.getAdminToken(),
    };

    final body = jsonEncode({
      "on_road_price": onRoadPrice,
      "down_payment_percent": downPaymentPercent,
      "interest_rate_percent": interestRatePercent,
      "tenure_months": tenureMonths,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      debugPrint("EMI Preview → ${response.statusCode}");
      debugPrint(response.body);

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        _emiDefaultData = responseData;
        _error = null;
      } else {
        _emiDefaultData = null;
        _error = responseData['message']?.toString() ??
            "Server error (${response.statusCode})";
      }
    } catch (e) {
      debugPrint("EMI Preview error: $e");
      _emiDefaultData = null;
      _error = "Something went wrong";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _emiDefaultData = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}