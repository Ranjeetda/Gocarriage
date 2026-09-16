import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class PastOrderListProvider with ChangeNotifier {
  List<dynamic> _allData = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get listData => _allData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBlukOrderList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final url = Uri.parse(URLS.bulkBooking);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    // ── Request log ────────────────────────────────────────────────────────
    print('════════ BULK ORDER LIST REQUEST ════════');
    print('URL     : $url');
    print('Method  : GET');
    print('Headers : $headers');
    print('═════════════════════════════════════════');

    try {
      final response = await http.get(url, headers: headers);

      // ── Response log ─────────────────────────────────────────────────────
      print('════════ BULK ORDER LIST RESPONSE ═══════');
      print('Status  : ${response.statusCode}');
      print('Body    : ${response.body}');
      print('═════════════════════════════════════════');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _allData = responseData['data'];
        _errorMessage = null;

        print('✅ Success');
      } else {
        _allData = [];
        _errorMessage =
            responseData['message']?.toString() ?? 'Failed to load bulk order';
        print('❌ Failed: $_errorMessage');
      }
    } catch (e, stack) {
      _allData = [];
      _errorMessage = e.toString();
      print('❌ Exception: $e');
      print(stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}