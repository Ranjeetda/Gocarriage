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

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final element = data['rows'][0]['elements'][0];
      print("RanjeetTest =========${data.toString()}");
      if (element['status'] == "OK") {
        return {
          "distance": element['distance']['text'],
          "duration": element['duration']['text'],
        };
      } else {
        throw Exception("No route found");
      }
    } else {
      throw Exception("API error");
    }
  }
}
