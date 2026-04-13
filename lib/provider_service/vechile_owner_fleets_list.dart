import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VechileOwnerFleetsList with ChangeNotifier {
  List<dynamic> _listData = [];
  bool _isLoading = false;

  List<dynamic> get listData => _listData;
  bool get isLoading => _isLoading;

  Future<void> fetchList(String serviceType) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.listFleetsByOwner);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final requestBody = {
      "owner_id": PrefUtils.getUserId(),
      // backend may return mixed data
    };
    /// PRINT REQUEST
    debugPrint("========= API REQUEST =========");
    debugPrint("URL : $url");
    debugPrint("Headers : $headers");
    debugPrint("Body : ${jsonEncode(requestBody)}");
    debugPrint("===============================");
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 STATUS: ${response.statusCode}');
      debugPrint('📥 BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(response.body);

        if (responseData['success'] == true) {
          final List fleets =
              responseData['data']?['fleets'] ?? [];

          /// ✅ STRICT SERVICE TYPE FILTER
          _listData = fleets.where((fleet) {
            final apiType =
            fleet['service_type']?.toString().trim().toLowerCase();
            final selectedType =
            serviceType.trim().toLowerCase();

            return apiType == selectedType;
          }).toList();
        } else {
          _listData = [];
        }
      } else {
        _listData = [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching fleets: $e');
      _listData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
