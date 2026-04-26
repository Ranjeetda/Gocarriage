import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:gocarriage_universal/resource/shared_preferences.dart';

import '../ui/model/booking_trip_request.dart';

class PrefUtils {
  static const int maxItems = 5;

  static String? setLoggedIn(bool isTrue) {
    Prefs.prefs!.setBool('isLogin', isTrue);
    return null;
  }

  static bool isLoggedIn() {
    bool? isLogin = Prefs.prefs?.getBool('isLogin');
    return isLogin ?? false;
  }

  static void setDeviceType(String value) =>
      Prefs.prefs?.setString('deviceType', value);

  static String getDeviceType() => Prefs.prefs?.getString('deviceType') ?? '';

  static String? setDriverOnline(bool isTrue) {
    Prefs.prefs!.setBool('isDriverOnline', isTrue);
    return null;
  }

  static void setDeviceInfo(String value) =>
      Prefs.prefs?.setString('deviceInfo', value);

  static String getDeviceInfo() => Prefs.prefs?.getString('deviceInfo') ?? '';

  static void setFcmToken(String value) =>
      Prefs.prefs?.setString('fcm_token', value);

  static String getFcmToken() => Prefs.prefs?.getString('fcm_token') ?? '';

  static bool isDriverOnline() {
    bool? isLogin = Prefs.prefs?.getBool('isDriverOnline');
    return isLogin ?? false;
  }

  static String? setFirstTime(bool isTrue) {
    Prefs.prefs!.setBool('isFirst', isTrue);
    return null;
  }

  static bool isFirstTime() {
    bool? isLogin = Prefs.prefs?.getBool('isFirst');
    return isLogin ?? false;
  }


  static String? setToken(String token) {
    Prefs.prefs!.setString("token", token);
    return null;
  }

  static String getToken() {
    final String? value = Prefs.prefs!.getString("token");
    return value ?? '';
  }

  static String? setProfileImage(String profileImage) {
    Prefs.prefs!.setString("profileImage", profileImage);
    return null;
  }

  static String getProfileImage() {
    final String? value = Prefs.prefs!.getString("profileImage");
    return value ?? '';
  }

  static String? setUserId(String userId) {
    Prefs.prefs!.setString("id", userId);
    return null;
  }

  static String getUserId() {
    final String? value = Prefs.prefs!.getString("id");
    return value ?? '';
  }

  static String? setOperatorId(String operatorId) {
    Prefs.prefs!.setString("operator_id", operatorId);
    return null;
  }

  static String getOperatorId() {
    final String? value = Prefs.prefs!.getString("operator_id");
    return value ?? '';
  }

  static String? setName(String name) {
    Prefs.prefs!.setString("name", name);
    return null;
  }

  static String getName() {
    final String? value = Prefs.prefs!.getString("name");
    return value ?? '';
  }

  static String? setRole(String role) {
    Prefs.prefs!.setString("role", role);
    return null;
  }

  static String getRole() {
    final String? value = Prefs.prefs!.getString("role");
    return value ?? '';
  }

  static String? setEmail(String email) {
    Prefs.prefs!.setString("email", email);
    return null;
  }

  static String getEmail() {
    final String? value = Prefs.prefs!.getString("email");
    return value ?? '';
  }

  static String? setMobile(String mobile) {
    Prefs.prefs!.setString("mobile", mobile);
    return null;
  }

  static String getMobile() {
    final String? value = Prefs.prefs!.getString("email");
    return value ?? '';
  }

  static String? setAddress(String address) {
    Prefs.prefs!.setString("address", address);
    return null;
  }

  static String getAddress() {
    final String? value = Prefs.prefs!.getString("address");
    return value ?? '';
  }

  static String? setCity(String city) {
    Prefs.prefs!.setString("city", city);
    return null;
  }

  static String getCity() {
    final String? value = Prefs.prefs!.getString("city");
    return value ?? '';
  }

  static String? setState(String state) {
    Prefs.prefs!.setString("state", state);
    return null;
  }

  static String getState() {
    final String? value = Prefs.prefs!.getString("state");
    return value ?? '';
  }

  static String? setPinCode(String pinCode) {
    Prefs.prefs!.setString("postalCode", pinCode);
    return null;
  }

  static String getpinCode() {
    final String? value = Prefs.prefs!.getString("postalCode");
    return value ?? '';
  }

  static String? setPinCode1(String pinCode) {
    Prefs.prefs!.setString("pincode1", pinCode);
    return null;
  }

  static String getpinCode1() {
    final String? value = Prefs.prefs!.getString("pincode1");
    return value ?? '';
  }

  static String? setPinCode2(String pinCode) {
    Prefs.prefs!.setString("pincode2", pinCode);
    return null;
  }

  static String getpinCode2() {
    final String? value = Prefs.prefs!.getString("pincode2");
    return value ?? '';
  }

  static List<String>? getLocationHistory() {
    return Prefs.prefs!.getStringList("location_history");
  }

  static void saveLocationHistory(List<String> list) {
    Prefs.prefs!.setStringList("location_history", list);
  }

  static Future<void> saveBookingRequest(
    BookingTripRequest bookingRequest,
  ) async {
    final jsonString = jsonEncode(bookingRequest.toJson());

    await Prefs.prefs!.setString('booking_request', jsonString);

    debugPrint("BOOKING REQUEST SAVED: $jsonString");
  }

  static Future<BookingTripRequest?> getBookingRequest() async {
    final jsonString = Prefs.prefs!.getString('booking_request');

    if (jsonString == null) return null;

    debugPrint("BOOKING REQUEST FETCHED: $jsonString");

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    return BookingTripRequest.fromJson(jsonMap);
  }


  static Future<List<String>> getRecentLocations() async {

    final jsonString = Prefs.prefs!.getString("recent_locations");
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> list = json.decode(jsonString);
    return list.cast<String>();
  }

  static Future<void> addLocation(String location) async {
    if (location.trim().isEmpty) return;
    List<String> recent = await getRecentLocations();
    recent.remove(location);
    recent.insert(0, location);
    // Limit to maxItems
    if (recent.length > maxItems) {
      recent = recent.sublist(0, maxItems);
    }
    await Prefs.prefs!.setString("recent_locations", json.encode(recent));
  }

  static Future<void> clearBookingRequest() async {
    await Prefs.prefs!.remove('booking_request');

    debugPrint("BOOKING REQUEST CLEARED");
  }

  static bool? setTheme(bool theme) {
    Prefs.prefs!.setBool("theme", theme);
  }

  static bool? getTheme() {
    final bool? value = Prefs.prefs!.getBool("theme");
    return value;
  }

  static Future<void> clearPreferences() async {
    if (Prefs.prefs != null) {
      await Prefs.prefs!.clear(); // Clear preferences
      print("Preferences cleared successfully.");
    } else {
      print("Error: SharedPreferences instance is null.");
    }
  }
}
