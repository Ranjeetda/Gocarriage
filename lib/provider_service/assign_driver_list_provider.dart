import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class AssignDriverListProvider with ChangeNotifier {

  List<dynamic> _listData=[];
  bool _isLoading = false;

  List<dynamic> get listData => _listData;
  bool get isLoading => _isLoading;

  Future<void> fetchList() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.assignDriverByOwner);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    try {
      // 🔹 PRINT REQUEST
      debugPrint('📤 REQUEST');
      debugPrint('URL: $url');
      debugPrint('HEADERS: $headers');
      final Map<String, dynamic> requestBody = {
        "ownerId": PrefUtils.getUserId(),
      };

      final String body = jsonEncode(requestBody);


      final response = await http.post(url,body: body, headers: headers);

      // 🔹 PRINT RESPONSE STATUS
      debugPrint('📥 RESPONSE');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('Accepted BODY: ${response.body}');

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        _listData = responseData['data'];
      } else {
        debugPrint('⚠️ API MESSAGE: ${responseData['message']}');
        _listData = [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching booking: $e');
      _listData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

