
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';

class RewardWalletProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _rewardWallet;
  Map<String, dynamic>? get rewardWallet => _rewardWallet;

  String? _error;
  String? get error => _error;

  Future<Map<String, dynamic>?> fetchRewardsWallet() async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse(URLS.rewardsWallet);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      print("📤 REQUEST URL: $url");
      final response = await http.get(
        url,
        headers: headers,
      );

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        debugPrint("📥 DECODED RESPONSE:");
        debugPrint(const JsonEncoder.withIndent('  ').convert(responseData));

        if (responseData['success'] == true) {
          _rewardWallet = responseData['data']['wallet'];

          print("✅ SUCCESS: Rewards fetched");
          print("💰 Rewards Data: ${responseData['data']}");
          return _rewardWallet;
        } else {
          _error = responseData['message'] ?? "Something went wrong";
          print("❌ API ERROR: $_error");
          return null;
        }
      } else {
        _error = "Server error: ${response.statusCode}";
        print("❌ SERVER ERROR: $_error");
        return null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ EXCEPTION: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}