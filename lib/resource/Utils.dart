import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';


class Utils {
  static BuildContext? _loaderContext;
  static late BuildContext _loadingDialoContext;
  static bool _isLoaderShowing = false;
  static bool _isLoadingDialogShowing = false;
  static late Timer toastTimer;

  static bool isEmail(String input) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);
  }


//  Checks
  static bool isNotEmpty(String s) {
    return s != null && s.trim().isNotEmpty;
  }

  static bool isEmpty(String s) {
    return !isNotEmpty(s);
  }

  static bool isListNotEmpty(List<dynamic> list) {
    return list != null && list.isNotEmpty;
  }

  //  Views
  static void showToast1(BuildContext context, String message) {
    showCustomToast(context, message);
  }

  static void showSuccessMessage(BuildContext context, String message) {
    showCustomToast(context, message, bgColor: AppColors.snackBarGreen);
  }

  static void showNeutralMessage(BuildContext context, String message) {
    showCustomToast(context, message, bgColor: AppColors.snackBarColor);
  }

  static void showErrorMessage(BuildContext context, String message) {
    showCustomToast(context, message, bgColor: AppColors.snackBarRed);
  }

  static void showValidationMessage(BuildContext context, String message) {
    showCustomToast(context, message);
  }

  static void showCustomToast(BuildContext context, String message,
      {Color bgColor = AppColors.primaryColor}) {
    showToast(message,
        context: context,
        fullWidth: true,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,color: Colors.white),
        animation: StyledToastAnimation.slideFromTopFade,
        reverseAnimation: StyledToastAnimation.slideToTopFade,
        position:
        const StyledToastPosition(align: Alignment.topCenter, offset: 0.0),
        startOffset: const Offset(0.0, -3.0),
        backgroundColor: bgColor,
        reverseEndOffset: const Offset(0.0, -3.0),
        duration: const Duration(seconds: 3),
        animDuration: const Duration(seconds: 1),
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.fastOutSlowIn);
  }

  static void showErrorToast(BuildContext context, String message,
      {Color bgColor = AppColors.snackBarRed}) {
    showToast(
        message,
        context: context,
        fullWidth: true,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,color: Colors.white),
        animation: StyledToastAnimation.slideFromTopFade,
        reverseAnimation: StyledToastAnimation.slideToTopFade,
        position: const StyledToastPosition(align: Alignment.topCenter, offset: 0.0),
        startOffset: const Offset(0.0, -3.0),
        backgroundColor: AppColors.snackBarRed,
        reverseEndOffset: const Offset(0.0, -3.0),
        duration: const Duration(seconds: 3),
        animDuration: const Duration(seconds: 1),
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.fastOutSlowIn);
  }

  static void showLoader(BuildContext context) {
    if (!_isLoaderShowing) {
      _isLoaderShowing = true;
      _loaderContext ??= context;
      showDialog(
          context: _loaderContext!,
          barrierDismissible: false,
          builder: (_loaderContext) {
            return const SpinKitSpinningLines(
              size: 30,
              color: AppColors.primaryColor,
            );
          });
    }
  }

  static Widget buildLoader() {
    return const SpinKitSpinningLines(
      size: 80,
      color: AppColors.primaryColor,
    );
  }


  static void hideLoader() {
    if (_isLoaderShowing) {
      Navigator.pop(_loaderContext!);
      _loaderContext ??= null;
    }
  }

  static void showLoadingDialog(BuildContext context) {
    if (!_isLoadingDialogShowing) {
      _isLoadingDialogShowing = true;
      _loadingDialoContext = context;
      showDialog(
          context: _loadingDialoContext,
          barrierDismissible: false,
          builder: (context) {
            return const SpinKitSpinningLines(
              color: AppColors.primaryColor,
            );
          })
          .then((value) => {
        _isLoadingDialogShowing = false,
        print('LoadingDialog hidden!')
      });
    }
  }


  static void hideLoadingDialog() {
    if (_isLoadingDialogShowing) {
      Navigator.pop(_loadingDialoContext);
      _loadingDialoContext == null;
    }
  }

  static void hideKeyBoard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static ThemeData getAppThemeData() {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      canvasColor: Colors.transparent,
      brightness: Brightness.light,
    );
  }

  static DateTime convertDateFromString(String strDate) {
    DateTime date = DateTime.parse(strDate);
    // var formatter = new DateFormat('yyyy-MM-dd');
    return date;
  }

  static String getDeviceType() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return 'MacOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else {
      return 'Unknown';
    }
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Regular expression for validating email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String getCurrentMonth() {
    DateTime currentDate = DateTime.now();
    String monthNumber = currentDate.month.toString().padLeft(2, '0');
    return monthNumber;
  }


  static DateTime convertDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
  }



  static void showToastMessage() {
    Fluttertoast.showToast(
        msg: "Expense submitted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }


  static String getMonthName(int monthNumber) {
    // List of month names
    const List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Validate the month number and return the corresponding month name
    if (monthNumber >= 1 && monthNumber <= 12) {
      return monthNames[monthNumber - 1];
    } else {
      throw ArgumentError('Invalid month number: $monthNumber. Must be between 1 and 12.');
    }
  }

  static Map<String, dynamic>? decodeJwtWithoutVerification(String token) {
    try {
      // Split the token into its parts
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT');
      }

      // Decode the payload
      final payloadBase64 = parts[1];
      final normalized = base64Url.normalize(payloadBase64);
      final payloadString = utf8.decode(base64Url.decode(normalized));

      // Convert the payload string into a Map
      final payload = json.decode(payloadString) as Map<String, dynamic>;

      return payload;
    } catch (e) {
      print('Error decoding JWT without verification: $e');
      return null;
    }
  }

  static String timeAgo(String createdAt) {
    final created = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(created);

    if (diff.inSeconds < 60) return "${diff.inSeconds} sec ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  static double applyProgress(String createdAt) {
    final created = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(created).inSeconds;

    const total = 10 * 60; // 10 minutes in seconds
    double value = diff / total;

    if (value < 0) value = 0;
    if (value > 1) value = 1;

    return value;
  }


  static Future<String?> getPincodeFromLatLng(
      double lat,
      double lng,
      ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final code = placemarks.first.postalCode;
      return (code != null && code.isNotEmpty) ? code : null;
    } catch (_) {
      return null;
    }
  }


  static double getDistanceInKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    return Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    ) / 1000; // meters → km
  }

  static int getEstimatedTime(double distanceKm) {
    const double averageSpeedKmPerHr = 25; // city traffic
    return ((distanceKm / averageSpeedKmPerHr) * 60).round();
  }

  static Future<LatLng> getLatLngFromPincode(String pincode) async {
    final List<Location> locations =
    await locationFromAddress(pincode);

    return LatLng(
      locations.first.latitude,
      locations.first.longitude,
    );
  }

  static Future<Map<String, dynamic>> calculateDistanceAndTime(
      String pickupPincode,
      String dropPincode,
      ) async {
    final pickupLatLng = await getLatLngFromPincode(pickupPincode);
    final dropLatLng = await getLatLngFromPincode(dropPincode);

    final distanceKm = getDistanceInKm(
      pickupLatLng.latitude,
      pickupLatLng.longitude,
      dropLatLng.latitude,
      dropLatLng.longitude,
    );

    final estimatedTimeMin = getEstimatedTime(distanceKm);

    return {
      'distanceKm': distanceKm,
      'estimatedTimeMin': estimatedTimeMin,
    };
  }

  static Map<String, String> convertMillisecondsToDateAndTime(int milliseconds) {
    // Convert to DateTime (UTC → Local)
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
        milliseconds, isUtc: true).toLocal();

    // Format separately
    final date = DateFormat('d-MM-yyyy').format(dateTime); // e.g. 2025-11-09
    final time = DateFormat('HH:mm').format(dateTime); // e.g. 15:58:51

    return {
      'date': date,
      'time': time,
    };
  }

  static String formatIsoDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd-MMM-yyyy hh:mm a').format(dateTime);
  }

  static String capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String formatToDDMMYYYY(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
  static String formatToValide(DateTime now) {
    DateTime onlyDate = DateTime(now.year, now.month, now.day);
    return DateFormat('dd/MM/yyyy').format(onlyDate);
  }

  /*********************************************/

  static const double _earthRadiusKm = 6371;

  /// Static method to calculate distance in KM
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {

    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Static method to calculate fare
  static double calculateFare(double distanceKm) {
    const double baseFare = 50;   // ₹
    const double perKmRate = 12;  // ₹ per KM

    return baseFare + (distanceKm * perKmRate);
  }

  static double _degToRad(double deg) {
    return deg * (pi / 180);
  }


  static void showSuccessDialog(BuildContext context,String mBookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Main White Card
              Container(
                margin: const EdgeInsets.only(top: 60),
                padding: const EdgeInsets.fromLTRB(25, 60, 25, 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Thank You!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                     Text(
                      "Your booking has been successfully completed.\n\nBooking ID: #$mBookingId",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF63BB6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "OK",
                          style: TextStyle(fontSize: 16,color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Top Green Circle
              Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF63BB6A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void printFullText(String text) {
    const int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      debugPrint(text.substring(
        i,
        i + chunkSize > text.length ? text.length : i + chunkSize,
      ));
    }
  }
}
