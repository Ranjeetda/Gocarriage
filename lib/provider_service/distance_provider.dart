import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import 'URLS.dart';

class DistanceProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final String apiKey = "AIzaSyDpH5LUm09CEiJX4cSan8SDp0vxuVLwCCQ";

  Future<Map<String, String>> fetchDistance(
      String origin, String destination) async {

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/distancematrix/json"
          "?origins=$origin"
          "&destinations=$destination"
          "&mode=driving"
          "&key=$apiKey",
    );

    // 🔹 Print Request URL
    print("===== API REQUEST =====");
    print(url.toString());

    final response = await http.get(url);

    // 🔹 Print Status Code
    print("===== STATUS CODE =====");
    print(response.statusCode);

    // 🔹 Print Raw Response Body
    print("===== RAW RESPONSE =====");
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 🔹 Pretty JSON Print
      print("===== PARSED JSON =====");
      print(const JsonEncoder.withIndent('  ').convert(data));

      final element = data['rows'][0]['elements'][0];

      if (element['status'] == "OK") {
        print("===== SUCCESS DATA =====");
        print("Distance: ${element['distance']['text']}");
        print("Duration: ${element['duration']['text']}");

        return {
          "distance": element['distance']['text'],
          "duration": element['duration']['text'],
        };
      } else {
        print("===== ERROR IN ELEMENT =====");
        print(element['status']);
        throw Exception("No route found");
      }
    } else {
      print("===== API ERROR =====");
      throw Exception("API error");
    }
  }
}
