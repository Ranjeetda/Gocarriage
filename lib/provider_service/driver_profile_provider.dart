import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class DriverProfileProvider with ChangeNotifier {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = false;
  String? mainUrl;

  Map<String, dynamic> get profileData => _profileData;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

      mainUrl=URLS.fetchProfileDriver+userId;

    final url = Uri.parse(mainUrl!);
    final headers = {
      'Authorization': "Bearer ${PrefUtils.getToken()}",
    };

    try {
      print('url : ===============: $url');
      print('Header Request : ===============: $headers');

      final response = await http.get(url, headers: headers);


      final responseData = json.decode(response.body);

      Utils.printFullText('Profile Response : ===============: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        _profileData = responseData['data']; // ✅ Contains all profile key-values
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load profile.');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
