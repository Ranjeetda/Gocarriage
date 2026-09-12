import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class NegotiationsListProvider with ChangeNotifier {
  List<dynamic> _allData = [];
  List<dynamic> _allOpenData = [];
  bool _isLoading = false;

  List<dynamic> get listData => _allData;
  List<dynamic> get listOpenData => _allOpenData;
  bool get isLoading => _isLoading;

  List<dynamic> get confirmedList {
    return _allData.where((item) {
      return item['won'] == true ||
          item['status'] == 'COMPLETED' ||
          item['status'] == 'AWAITING_DRIVER_ASSIGNMENT';
    }).toList();
  }

  List<dynamic> get openList {
    return _allOpenData.where((item) {
      return item['status'] != 'AWAITING_DRIVER_ASSIGNMENT';
    }).toList();
  }

  int get openCount => openList.length;

  /// Fetch Confirmed / All Negotiations
  Future<void> fetchNegotiationsList() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.negotiationsBookingList);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    // REQUEST LOG
    debugPrint("========================================");
    debugPrint("API REQUEST");
    debugPrint("URL: $url");
    debugPrint("METHOD: GET");
    debugPrint("HEADERS:");
    headers.forEach((key, value) {
      debugPrint("$key : $value");
    });
    debugPrint("========================================");

    try {
      final response = await http.get(url, headers: headers);

      // RESPONSE LOG
      debugPrint("========== API RESPONSE ==========");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY:");
      debugPrint(response.body);
      debugPrint("==================================");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _allData = responseData['data'] ?? [];
        debugPrint("Total Records: ${_allData.length}");
      } else {
        _allData = [];
        debugPrint("API FAILED");
        debugPrint("Message: ${responseData['message']}");
      }
    } catch (e, stackTrace) {
      _allData = [];
      debugPrint("========== API ERROR ==========");
      debugPrint("Error: $e");
      debugPrint("StackTrace:");
      debugPrint(stackTrace.toString());
      debugPrint("===============================");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Open Negotiations
  Future<void> fetchNegotiationsOpenList() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.negotiationsOpenBookingList);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    // REQUEST LOG
    debugPrint("========================================");
    debugPrint("OPEN API REQUEST");
    debugPrint("URL: $url");
    debugPrint("METHOD: GET");
    debugPrint("HEADERS:");
    headers.forEach((key, value) {
      debugPrint("$key : $value");
    });
    debugPrint("========================================");

    try {
      final response = await http.get(url, headers: headers);

      // RESPONSE LOG
      debugPrint("======= OPEN API RESPONSE =======");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY:");
      debugPrint(response.body);
      debugPrint("=================================");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _allOpenData = responseData['data'] ?? [];
        debugPrint("Total Open Records: ${_allOpenData.length}");
      } else {
        _allOpenData = [];
        debugPrint("OPEN API FAILED");
        debugPrint("Message: ${responseData['message']}");
      }
    } catch (e, stackTrace) {
      _allOpenData = [];
      debugPrint("======= OPEN API ERROR =======");
      debugPrint("Error: $e");
      debugPrint("StackTrace:");
      debugPrint(stackTrace.toString());
      debugPrint("==============================");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}