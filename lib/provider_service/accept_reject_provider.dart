import 'package:flutter/material.dart';

class AcceptRejectProvider extends ChangeNotifier {
  Map<String, dynamic>? ongoingRide;

  void setUpcomingRide(Map<String, dynamic> data) {
    ongoingRide = data;
    notifyListeners();
  }

  void clearRide() {
    ongoingRide = null;
    notifyListeners();
  }
}
