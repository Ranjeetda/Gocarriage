import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../resource/pref_utils.dart';
import 'URLS.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class AddCarProvider with ChangeNotifier {
  bool _isUpdating = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;

  Future<Map<String, dynamic>?> validateAddNewCar({
    required bool isUpdate,
    required String? vehicle_number,
    required String? vehicle_type_id,
    required String? owner_id,
    required String? fleetId,
    required String? current_city,
    required String? service_type,
    required String? status,
    required String? registered_date,
    required String? rto,
    required String? permit_type,
    required String? permit_states,
    required String? chassis_number,
    required String? engine_number,
    required String? engine_no,
    required String? fuel_type,
    required String? color,
    required String? payload,
    required bool? is_negotiable,
    required bool? road_tax_paid,
    required String? road_tax_paid_period,
    required String? tax_paid_date,
    required String? insurance_from_date,
    required String? insurance_upto,
    required String? rc_validity_from_date,
    required String? rc_validity_date,
    required String? fitness_validity_from_date,
    required String? fitness_validity_date,
    required String? permit_from_date,
    required String? permit_to_date,
    required String? pollution_validity_date,
    required String? brand,
    required String? model,
    required String? vehicle_model_id,
    required String? pollution_certificates,
    required String? rcDocument,
    required String? fitnessCertificate,
    required String? permitDocument,
    required String? insurance,
  }) async {

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Area IN REQUEST");
    debugPrint("Headers: $headers");

    try {
      final Map<String, dynamic> requestBody = {
        "vehicle_number": vehicle_number,
        "vehicle_type_id": vehicle_type_id,
        "owner_id": owner_id,
        "current_city": current_city,
        "service_type": service_type,
        "status": status,
        "registered_date": registered_date,
        "rto": rto,
        "permit_type": permit_type,
        "permit_states": permit_states,
        "chassis_number": chassis_number,
        "engine_number": engine_number,
        "engine_no": engine_no,
        "fuel_type": fuel_type,
        "color": color,
        "payload": payload,
        "is_negotiable": is_negotiable,
        "road_tax_paid": road_tax_paid,
        "road_tax_paid_period": road_tax_paid_period,
        "tax_paid_date": tax_paid_date,
        "insurance_from_date": insurance_from_date,
        "insurance_upto": insurance_upto,
        "rc_validity_from_date": rc_validity_from_date,
        "rc_validity_date": rc_validity_date,
        "fitness_validity_from_date": fitness_validity_from_date,
        "fitness_validity_date": fitness_validity_date,
        "permit_from_date": permit_from_date,
        "permit_to_date": permit_to_date,
        "pollution_validity_date": pollution_validity_date,
        "brand": brand,
        "model": model,
        "vehicle_model_id": vehicle_model_id,
        "pollution_certificates": pollution_certificates,
        "rc_document": rcDocument,
        "fitness_certificate": fitnessCertificate,
        "permit_document": permitDocument,
        "insurance": insurance,
        'fleet_image': "",
      };

      final String body = jsonEncode(requestBody);

      Utils.printFullText("Request Body: $body");
      http.Response response;

      /// ✅ FIX: declare response OUTSIDE
      if (isUpdate != true) {
        final Uri url = Uri.parse(URLS.addVehicle);
        debugPrint("URL: $url");

        response = await http.post(url, body: body, headers: headers);
      } else {
        print("URL: ${"${URLS.addVehicle}/$fleetId"}");
        response = await http.put(
          Uri.parse("${URLS.addVehicle}/$fleetId"),
          body: body,
          headers: headers,
        );
      }

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 VERIFY OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");

      final responseData = json.decode(response.body);
      Utils.printFullText("Response Body: ${responseData.toString()}");

      if (response.statusCode == 200 && responseData['success'] == true) {
        _message = responseData['message'] ?? 'Add New Vehicle successfully';
      } else {
        _message = responseData['message'] ?? 'Failed to Add New Vehicle';
      }
      return responseData;
    } catch (error) {
      debugPrint("🔴 Add New Vehicle In ERROR: $error");
      throw Exception('Failed to Add New Vehicle in: $error');
    }
  }
}
