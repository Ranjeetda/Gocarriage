import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class FleetSubscriptionsProvider with ChangeNotifier {
  List<dynamic> _subscriptions = [];
  List<dynamic> get subscriptions => _subscriptions;

  Map<String,dynamic> _subscriptionsmap = {};
  Map<String,dynamic>  get subscriptionsmap => _subscriptionsmap;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 🔹 API CALL
  Future<void> fetchSubscriptions(String id, String comeFrome) async {
    _isLoading = true;
    notifyListeners();
    Uri url;
    if (comeFrome == 'dialog') {
      url = Uri.parse("${URLS.subscriptions}$id/active");
    } else {
      url = Uri.parse("${URLS.subscriptions}$id/history");
    }

    try {
      print("========== REQUEST ==========");
      print("URL: $url");
      print("=============================");

      final response = await http.get(url);

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");
      print("==============================");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if(comeFrome=='dialog'){
          _subscriptionsmap = data['data'];

        }else{
          _subscriptions = data['data']['subscriptions'] ?? [];

        }
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
