import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import 'URLS.dart';

class StartTripeProvider with ChangeNotifier {

  Future<http.Response> startTrip() async {
    final url = Uri.parse(URLS.startTrip);
    final headers = {"Content-Type": "application/json", 'Authorization': 'Bearer ${PrefUtils.getToken()}'};
    final body = json.encode({
    });
    print('Url: ${url.toString()}');
    print('Request: ${body.toString()}');

    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Start Booking in statusCode: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('Start Booking in successful: ${response.body}');
        return response;
      } else {
        print('Start Booking in failed: ${response.body}');
        return response;
      }
    } catch (error) {
      throw Exception('Failed to Start Ride in: $error');
    }
  }
}
