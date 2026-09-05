import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class AddFleetFreightCostProvider with ChangeNotifier {
  List<dynamic> _componentsList = [];
  bool _isLoading = false;
  bool _isSuccess = false;

  List<dynamic> get componentsList => _componentsList;

  bool get isLoading => _isLoading;

  bool get isSuccess => _isSuccess;

  Future<Map<String, dynamic>?> uploadFreightVehicleData({
    required Map<String, dynamic> body,
    required String fleetId,
  }) async {
    try {
      _isLoading = true;
      _isSuccess = false;
      notifyListeners();

      final url = Uri.parse('${URLS.freightFleetCostsUpload}$fleetId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${PrefUtils.getToken()}',
        },
        body: jsonEncode(body),
      );

      debugPrint('Status Code : ${response.statusCode}');
      debugPrint('Freight Coast Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          _isSuccess = true;
          return {'success': true, 'message': 'Saved successfully'};
        }

        final data = jsonDecode(response.body);
        _isSuccess = data['success'] == true;
        return data;
      } else {
        _isSuccess = false;
        try {
          final error = jsonDecode(response.body);
          return error;
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      _isSuccess = false;
      debugPrint('❌ Exception: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
