import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class FleetVehicleListProvider with ChangeNotifier {

  List<dynamic> _listData=[];
  bool _isLoading = false;

  List<dynamic> get listData => _listData;
  bool get isLoading => _isLoading;

  Future<void> fetchList(String vehicleId) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.fleetVehicleList+vehicleId);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      // 🔹 PRINT REQUEST
      debugPrint('================ REQUEST ================');
      debugPrint('URL: $url');
      debugPrint('METHOD: GET');
      debugPrint('HEADERS: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      // 🔹 PRINT RESPONSE
      debugPrint('================ RESPONSE ================');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _listData = responseData['data'];
      } else {
        debugPrint('⚠️ API ERROR MESSAGE: ${responseData['message']}');
        _listData = [];
      }

    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
      _listData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

