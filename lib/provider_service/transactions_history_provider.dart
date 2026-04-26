import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class TransactionsHistoryProvider with ChangeNotifier {
  List<dynamic> _transactionsHistory = [];
  bool _isLoading = false;

  List<dynamic> get transactionsHistory => _transactionsHistory;
  bool get isLoading => _isLoading;

  /// 🔹 API CALL
  Future<void> fetchSubscriptions(String id) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse("${URLS.transactionHistory}$id/transactions");

    try {
      print("========== REQUEST ==========");
      print("URL: $url");
      print("=============================");
      final headers = {
        "Content-Type": "application/json",
        "Authorization": 'Bearer ${PrefUtils.getToken() ?? ''}',
      };

      final response = await http.get(url,headers: headers);

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");
      print("==============================");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _transactionsHistory = data['data']['transactions'] ?? [];
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}