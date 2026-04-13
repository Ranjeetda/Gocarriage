import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


import '../resource/pref_utils.dart';
import 'URLS.dart';

class DeleteProfileProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<http.Response> deleteProfile() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.deleteProfile);

    final headers = {
      'id': PrefUtils.getUserId(),
      'customerKey': PrefUtils.getToken(),
    };

    try {
      final response = await http.post(url, headers: headers);
      final responseData = json.decode(response.body);
      return response; // ✅ Now returns the response
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
