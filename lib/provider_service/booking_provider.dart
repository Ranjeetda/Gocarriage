import 'package:flutter/cupertino.dart';

enum RideStatus {
  idle,
  searching,
  accepted,
  rejected,
  timeout,
}

class BookingProvider extends ChangeNotifier {
  RideStatus rideStatus = RideStatus.idle;
  Map<String, dynamic>? upcomingRide;

  void startSearching() {
    rideStatus = RideStatus.searching;
    notifyListeners();
  }

  void setUpcomingRide(Map<String, dynamic> ride) {
    upcomingRide = ride;
    rideStatus = RideStatus.accepted;
    notifyListeners();
  }

  void onTimeout() {
    rideStatus = RideStatus.timeout;
    notifyListeners();
  }

  void cancelRide() {
    rideStatus = RideStatus.idle;
    upcomingRide = null;
    notifyListeners();
  }
  void clearRide() {
    upcomingRide = null;
    rideStatus = RideStatus.idle;
    notifyListeners();
  }
}
