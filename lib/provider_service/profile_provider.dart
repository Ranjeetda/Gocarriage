import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

class ProfileProvider with ChangeNotifier {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = false;
  String? mainUrl;

  Map<String, dynamic> get profileData => _profileData;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile(String comeFrome,String role,String userId) async {
    _isLoading = true;
    notifyListeners();
    print("Ranjeet Driver profile =========>${role+"    "+userId + "     "+PrefUtils.getRole()}");

    if(PrefUtils.getRole()==role){
      mainUrl=URLS.fetchProfileCustomer+userId;
    }else if(PrefUtils.getRole()== role){
      mainUrl=URLS.fetchProfileDriver+userId;
    }else if(PrefUtils.getRole()== role){
      mainUrl=URLS.profileOwners+userId;
    }else if(comeFrome== 'ownerDriverList'){
      mainUrl=URLS.fetchProfileDriver+userId;
    }


    final url = Uri.parse(mainUrl!);

    final headers = {
      'Authorization': "Bearer ${PrefUtils.getToken()}",
    };

    try {
      print('url : ===============: $url');
      print('Header Request : ===============: $headers');

      final response = await http.get(url, headers: headers);

      print('Profile Response : ===============: ${response.body}');

      final responseData = json.decode(response.body);

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
