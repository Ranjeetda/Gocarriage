import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class FetchImageUrlProvider with ChangeNotifier {

  Future<http.Response> fetchImagePath(String imagePath) async {
    notifyListeners();
    final url = Uri.parse(URLS.imageUrlGet + imagePath);

    final headers = {'Authorization': "Bearer ${PrefUtils.getToken()}"};

    try {
      print('url : ===============: $url');
      print('Header Request : ===============: $headers');

      final response = await http.get(url, headers: headers);

      print('Profile Response : ===============: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return response;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load profile.');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
