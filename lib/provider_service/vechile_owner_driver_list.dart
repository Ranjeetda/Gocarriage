import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VechileOwnerDriverList with ChangeNotifier {

  List<dynamic> _listData=[];
  bool _isLoading = false;

  List<dynamic> get listData => _listData;
  bool get isLoading => _isLoading;

  Future<void> fetchList(String serviceType) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.listDriverByOwner);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final Map<String, dynamic> requestBody = {
      "ownerId": PrefUtils.getUserId(),
      "service_type": serviceType.isEmpty ? "in_city" : serviceType
    };

    final String body = jsonEncode(requestBody);

    try {
      // 🔹 PRINT REQUEST
      debugPrint('================ REQUEST ================');
      debugPrint('URL: $url');
      debugPrint('METHOD: POST');
      debugPrint('HEADERS: $headers');
      debugPrint('BODY: $body');

      final response = await http.post(
        url,
        body: body,
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

