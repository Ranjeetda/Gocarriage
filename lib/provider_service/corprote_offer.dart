import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class CorproteOffer with ChangeNotifier {

  List<dynamic> _offerListData = [];
  bool _isLoading = false;

  List<dynamic> get offerListData => _offerListData;
  bool get isLoading => _isLoading;

  Future<void> fetchBookingActivity() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.normalCustomerOfferMe);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      final response = await http.get(url, headers: headers);

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _offerListData = responseData['data']?['offers'] ?? [];
      } else {
        _offerListData = [];
        print("API Error: ${responseData['message']}");
      }
    } catch (e) {
      print("Error: $e");
      _offerListData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}
