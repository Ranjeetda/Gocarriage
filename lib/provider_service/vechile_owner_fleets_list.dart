import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

import 'dart:convert';
import 'package:flutter/material.dart';

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
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List fleets = responseData['data']?['fleets'] ?? [];

          /// ✅ STRICT SERVICE TYPE FILTER
          _listData =
              fleets.where((fleet) {
                final apiType =
                fleet['service_type']?.toString().trim().toLowerCase();
                final selectedType = serviceType.trim().toLowerCase();

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


/*
class VechileOwnerFleetsList with ChangeNotifier {
  List<dynamic> _listData = [];
  bool _isLoading = false;

  List<dynamic> get listData => _listData;

  bool get isLoading => _isLoading;

  Future<void> fetchList(String serviceType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Dummy API Response
      const String response = '''
      {
    "success": true,
    "message": "Fleet retrieved successfully",
    "data": {
        "id": 186,
        "vehicle_number": "DL1LAR9570",
        "registered_date": "2026-05-11T00:00:00.000Z",
        "permit_type": null,
        "chassis_number": null,
        "engine_number": null,
        "fuel_type": null,
        "color": null,
        "fleet_image": null,
        "insurance_policy_number": null,
        "insurance_upto": null,
        "payload": null,
        "service_type": "in_city",
        "rc_validity_date": null,
        "pollution_validity_date": null,
        "fitness_validity_date": null,
        "rto": "Delhi",
        "engine_no": null,
        "mileage": null,
        "base_price": null,
        "per_km_rate": null,
        "is_negotiable": false,
        "permit_states": null,
        "road_tax_paid": false,
        "road_tax_paid_period": null,
        "road_tax_valid_from": null,
        "road_tax_valid_upto": null,
        "tax_paid_date": null,
        "insurance_company": null,
        "insurance_from_date": null,
        "rc_validity_from_date": null,
        "fitness_validity_from_date": null,
        "permit_from_date": null,
        "permit_to_date": null,
        "vehicle_model_id": 448,
        "status": "draft",
        "verificationStatus": "pending",
        "rejectionReason": null,
        "verifiedBy": null,
        "verifiedAt": null,
        "doc_summary": null,
        "createdAt": "2026-07-01T12:35:59.000Z",
        "updatedAt": "2026-07-01T12:35:59.000Z",
        "vehicle_type_id": 3,
        "owner_id": 214,
        "Owner": {
            "id": 214,
            "type": "individual",
            "companyName": "",
            "ownerName": "Anil tiwari",
            "email": "arjunshukla4036@gmail.com",
            "address": "h no 210 ",
            "postalCode": "110044",
            "city": "delhi",
            "state": "Delhi",
            "panNumber": "GKIPS9750R",
            "contactPersonName": null,
            "contactPersonEmail": null,
            "contactPersonPhone": null,
            "ifscCode": "KKBK0005029",
            "bankName": "Kotak Mahindra Bank ",
            "accountNumber": "3746813750",
            "branchAddress": "noida",
            "panUpload": null,
            "aadhaarNumber": "686267481767",
            "aadhaarUpload": null,
            "gstNumber": "",
            "gstCertificateUpload": null,
            "drivingLicenceUpload": null,
            "drivingLicenceNumber": "DL0320050256802",
            "isProfileUpdated": true,
            "verificationStatus": "pending",
            "rejectionReason": null,
            "verifiedBy": null,
            "verifiedAt": null,
            "wa_number": "8744048856",
            "profile_pic": null,
            "cancel_cheque": null,
            "doc_summary": null,
            "userId": 576,
            "createdAt": "2026-07-01T12:31:21.000Z",
            "updatedAt": "2026-07-01T13:00:51.000Z"
        },
        "VehicleType": {
            "id": 3,
            "name": "1000",
            "v_cat": "Small Commercial Vehicles",
            "max_payload_kg": "1000.00"
        },
        "vehicleModel": {
            "id": 448,
            "category_id": 3,
            "v_cat": "Small Commercial Vehicles",
            "name": "Maruti Supper carry",
            "brand": "Maruti",
            "model": "Supper carry",
            "description": null,
            "length_ft": null,
            "width_ft": null,
            "height_ft": null,
            "payload_capacity_kg": null,
            "is_custom": true,
            "owner_id": 214,
            "createdAt": "2026-07-01T12:35:58.000Z",
            "updatedAt": "2026-07-01T12:35:58.000Z"
        },
        "location": {
            "current_city": "DELHI NCR",
            "current_address": null,
            "latitude": null,
            "longitude": null,
            "trip_status": "idle",
            "last_updated": "2026-07-01T12:35:59.000Z"
        },
        "grouped_documents": {
            "rc_document": [],
            "fitness_certificate": [],
            "permit_document": [],
            "insurance": [],
            "pollution_certificate": []
        },
        "active_subscription": null,
        "subscription_history": [],
        "wallet": null,
        "reward_summary": {
            "earned": 0,
            "max_possible": 3000,
            "category_event_code": "owner.vehicle_added.small",
            "category_points": 1000,
            "category_earned": false,
            "docs_complete_points": 2000,
            "docs_complete_earned": false,
            "reward_status": null,
            "transactions": []
        }
    }
}
      ''';

      final Map<String, dynamic> responseData = jsonDecode(response);

      if (responseData["success"] == true) {
        final fleet = responseData["data"];

        if (fleet != null &&
            fleet["service_type"].toString().toLowerCase().trim() ==
                serviceType.toLowerCase().trim()) {
          _listData = [fleet];
        } else {
          _listData = [];
        }
      } else {
        _listData = [];
      }
    } catch (e) {
      debugPrint("Error: $e");
      _listData = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
*/

