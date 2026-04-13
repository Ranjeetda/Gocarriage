import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/provider_service/URLS.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

class OperatorVechileBooking with ChangeNotifier {

  List vehicleRequestList = [];

  bool isLoading = false;
  bool isPaginationLoading = false;

  int page = 1;
  int totalPages = 1;

  //////////////////////////////////////////////////////
  /// FETCH BOOKINGS
  //////////////////////////////////////////////////////

  Future fetchVehicleRequest({bool loadMore = false}) async {

    if (loadMore) {
      if (page > totalPages) return;
      isPaginationLoading = true;
    } else {
      isLoading = true;
      page = 1;
      vehicleRequestList.clear();
    }

    notifyListeners();

    try {

      final response = await http.get(
        Uri.parse("${URLS.operatorBookingList}?page=$page&limit=10"),
        headers: {
          "Authorization": "Bearer ${PrefUtils.getToken()}",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {

        final jsonData = jsonDecode(response.body);

        List bookings = jsonData["data"]["bookings"];

        totalPages = jsonData["data"]["pagination"]["totalPages"];

        vehicleRequestList.addAll(bookings);

        page++;

      } else {
        print("API Error: ${response.statusCode}");
      }

    } catch (e) {
      print("Error: $e");
    }

    isLoading = false;
    isPaginationLoading = false;

    notifyListeners();
  }
}