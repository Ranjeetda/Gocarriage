import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class VersionControlProvider with ChangeNotifier {
  Map<String, dynamic> _versionControl = {};

  bool _isLoading = false;

  Map<String, dynamic> get versionControl => _versionControl;

  bool get isLoading => _isLoading;

  Future<void> fetchList(String buildNo) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(URLS.versionControl + buildNo);

    /// PRINT REQUEST
    debugPrint("========= API REQUEST =========");
    debugPrint("URL : $url");
    debugPrint("===============================");
    try {
      final response = await http.get(url);

      debugPrint('📥 STATUS: ${response.statusCode}');
      debugPrint('📥 BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _versionControl = responseData;
        } else {
          _versionControl = {};
        }
      } else {
        _versionControl = {};
      }
    } catch (e) {
      debugPrint('❌ Error fetching fleets: $e');
      _versionControl = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
