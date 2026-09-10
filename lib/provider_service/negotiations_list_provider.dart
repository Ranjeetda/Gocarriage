import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class NegotiationsListProvider with ChangeNotifier {
  List<dynamic> _allData = [];
  bool _isLoading = false;

  List<dynamic> get listData => _allData;
  bool get isLoading => _isLoading;

  List<dynamic> get confirmedList {
    return _allData.where((item) {
      return item['won'] == true ||
          item['status'] == 'COMPLETED' ||
          item['status'] == 'AWAITING_DRIVER_ASSIGNMENT';
    }).toList();
  }

  List<dynamic> get openList {
    return _allData.where((item) {
      return item['won'] != true &&
          item['status'] != 'AWAITING_DRIVER_ASSIGNMENT';
    }).toList();
  }

  int get openCount => openList.length;

  Future<void> fetchNegotiationsList() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.negotiationsBookingList);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _allData = responseData['data'] ?? [];
      } else {
        _allData = [];
      }
    } catch (e) {
      _allData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}