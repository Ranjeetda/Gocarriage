import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class MasterFreightPostProvider with ChangeNotifier {
  Map<String, dynamic>? _vehicleFreightCreated;
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;

  Map<String, dynamic>? get vehicleFreightCreated => _vehicleFreightCreated;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isSuccess => _isSuccess;

  /// Returns the response map on success, or null on failure
  Future<Map<String, dynamic>?> uploadFreightVehicleData({
    required Map<String, dynamic> body,
    required String freightId,
  }) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    _vehicleFreightCreated = null;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      'Authorization': "Bearer ${PrefUtils.getToken()}",
    };

    try {
      final url = Uri.parse("${URLS.freightVehicle}/$freightId"+"/components");

      debugPrint("➡️ REQUEST URL: $url");
      debugPrint("➡️ REQUEST BODY: ${jsonEncode(body)}");

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint("⬅️ STATUS CODE: ${response.statusCode}");
      debugPrint("⬅️ RESPONSE BODY: ${response.body}");

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        _vehicleFreightCreated = data;
        _isSuccess = true;
        _error = null;

        // Print success response
        debugPrint("✅ SUCCESS RESPONSE:");
        debugPrint(const JsonEncoder.withIndent('  ').convert(data));

        return data; // ← return the full map
      } else {
        _error = data['message']?.toString() ?? 'Unknown error';
        _isSuccess = false;
        _vehicleFreightCreated = data; // still keep the error response

        debugPrint("❌ API Error: $_error");

        return data; // ← return error map too
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _error = e.toString();
      _isSuccess = false;
      _vehicleFreightCreated = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> finalizeFreightVehicle(String freightId) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      'Authorization':
          "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Mjk5LCJyb2xlIjoic3VwZXJhZG1pbiIsImVtYWlsIjoic3VwZXJhZG1pbkBnb2NhcnJpYWdlLmNvbSIsImN1c3RvbWVySWQiOm51bGwsImRyaXZlcklkIjpudWxsLCJvd25lcklkIjpudWxsLCJvcGVyYXRvcklkIjpudWxsLCJmdWVsU3RhdGlvbklkIjpudWxsLCJzZXJ2aWNlQ2VudGVySWQiOm51bGwsImRoYWJhSWQiOm51bGwsImlhdCI6MTc4NTMwNTMyMiwiZXhwIjoxNzg1OTEwMTIyfQ.97tMI1yfif6ed2YGsQWifevYWTYB3l5Eki_Amrn7dGg",
    };

    try {
      // Prefer putting this in URLS.dart
      final url = Uri.parse("${URLS.freightVehicleModels}/$freightId/finalize");

      debugPrint("➡️ FINALIZE URL: $url");

      final response = await http.post(url, headers: headers);

      debugPrint("⬅️ STATUS: ${response.statusCode}");
      debugPrint("⬅️ BODY: ${response.body}");

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        _isSuccess = true;
        _vehicleFreightCreated = data;
        return data;
      } else {
        _error = data['message']?.toString() ?? 'Finalize failed';
        _isSuccess = false;
        return data;
      }
    } catch (e) {
      _error = e.toString();
      _isSuccess = false;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> deleteFreightVehicle(String freightId) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final headers = {
      "Content-Type": "application/json",
      'Authorization': PrefUtils.getAdminToken(),
    };

    try {
      final url = Uri.parse(
        "https://management.api.gocarriage.com/api/freight/vehicle/$freightId",
      );
      // Better: "${URLS.baseUrl}/freight/vehicle/$freightId"

      debugPrint("➡️ DELETE URL: $url");

      final response = await http.delete(url, headers: headers);

      debugPrint("⬅️ STATUS: ${response.statusCode}");
      debugPrint("⬅️ BODY: ${response.body}");

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        _isSuccess = true;
        _vehicleFreightCreated = null; // clear after delete
        return data;
      } else {
        _error = data['message']?.toString() ?? 'Delete failed';
        _isSuccess = false;
        return data;
      }
    } catch (e) {
      _error = e.toString();
      _isSuccess = false;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
