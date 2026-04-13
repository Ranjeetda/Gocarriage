import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';

class MyridesProvider with ChangeNotifier {
  List<dynamic> _cureentRideListData = [];
  List<dynamic> get cureentRideListData => _cureentRideListData;

  List<dynamic> _completeRideListData = [];
  List<dynamic> get completeRideListData => _completeRideListData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic> _currentPagination = {};
  Map<String, dynamic> _completedPagination = {};

  Map<String, dynamic> get currentPagination => _currentPagination;
  Map<String, dynamic> get completedPagination => _completedPagination;

  bool _hasNextCurrentPage = false;
  bool _hasNextCompletedPage = false;
  bool get hasNextCurrentPage => _hasNextCurrentPage;
  bool get hasNextCompletedPage => _hasNextCompletedPage;

  Future<http.Response> validateList({
    required String endpoint,
    int page = 1,
    int limit = 10,
    bool append = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$endpoint?page=$page&limit=$limit');
    final headers = {
      "Content-Type": "application/json",
      "Authorization": 'Bearer ${PrefUtils.getToken() ?? ''}',
    };

    // 🔹 Print Request
    debugPrint("➡️ REQUEST URL: $url");
    debugPrint("➡️ REQUEST HEADERS: $headers");

    try {
      final response = await http.get(url, headers: headers);

      // 🔹 Print Response
      debugPrint("⬅️ RESPONSE STATUS: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {

        final List<dynamic> currentData =
        List.from(responseData['data']['upcomingBookings'] ?? []);
        final List<dynamic> completedData =
        List.from(responseData['data']['completedBookings'] ?? []);

        final currentPaginationData =
            responseData['data']['upcomingPagination'] ?? {};
        final completedPaginationData =
            responseData['data']['completedPagination'] ?? {};

        // Handle current rides
        if (append && page > 1) {
          _cureentRideListData.addAll(currentData);
        } else {
          _cureentRideListData = currentData;
        }

        // Handle completed rides
        if (append && page > 1) {
          _completeRideListData.addAll(completedData);
        } else {
          _completeRideListData = completedData;
        }

        _currentPagination = currentPaginationData;
        _completedPagination = completedPaginationData;

        _hasNextCurrentPage = currentPaginationData['next_page'] ?? false;
        _hasNextCompletedPage = completedPaginationData['next_page'] ?? false;
      } else {
        debugPrint("❌ API ERROR RESPONSE: ${response.body}");
      }

      _isLoading = false;
      notifyListeners();
      return response;

    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint("🔥 EXCEPTION: $error");
      throw Exception('Failed to send request: $error');
    }
  }

}
