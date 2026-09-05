import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class FreightEmiDefaultProvider with ChangeNotifier {
  Map<String, dynamic>? _emiDefaultData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get emiDefaultData => _emiDefaultData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Convenience getters (adjust keys according to actual API response) ──
  double get onRoadPrice =>
      (_emiDefaultData?['data']?['on_road_price'] as num?)?.toDouble() ?? 0;

  double get downPaymentPercent =>
      (_emiDefaultData?['data']?['down_payment_percent'] as num?)?.toDouble() ?? 0;

  double get interestRatePercent =>
      (_emiDefaultData?['data']?['interest_rate_percent'] as num?)?.toDouble() ?? 0;

  int get tenureMonths =>
      (_emiDefaultData?['data']?['tenure_months'] as num?)?.toInt() ?? 0;

  double get financedAmount =>
      (_emiDefaultData?['data']?['financed_amount'] as num?)?.toDouble() ?? 0;

  double get emiPerMonth =>
      (_emiDefaultData?['data']?['emi_per_month'] as num?)?.toDouble() ?? 0;

  double get emiPerDay =>
      (_emiDefaultData?['data']?['emi_per_day'] as num?)?.toDouble() ?? 0;

  Future<void> fetchEmiDefault() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse(URLS.freightEmiDefault);
    final headers = {
      "Content-Type": "application/json",
      // ⚠️ Move token to secure storage later
      'Authorization': PrefUtils.getAdminToken(),
    };

    try {
      final response = await http.get(url, headers: headers);

      debugPrint("EMI Default → ${response.statusCode}");
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
      debugPrint("Error fetching EMI default: $e");
      _emiDefaultData = null;
      _error = "Something went wrong";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}