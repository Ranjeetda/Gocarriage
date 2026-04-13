import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:gocarriage_universal/provider_service/accept_reject_price_provider.dart';
import 'package:gocarriage_universal/provider_service/add_car_provider.dart';
import 'package:gocarriage_universal/provider_service/assign_driver_provider.dart';
import 'package:gocarriage_universal/provider_service/assign_vehicle_driver_provider.dart';
import 'package:gocarriage_universal/provider_service/audio_provider.dart';
import 'package:gocarriage_universal/provider_service/delete_vehicle_provider.dart';
import 'package:gocarriage_universal/provider_service/draft_vehicle_provider.dart';
import 'package:gocarriage_universal/provider_service/fetch_image_url_provider.dart';
import 'package:gocarriage_universal/provider_service/file_upload_provider.dart';
import 'package:gocarriage_universal/provider_service/forgot_password_provider.dart';
import 'package:gocarriage_universal/provider_service/forgot_verify_otp_provider.dart';
import 'package:gocarriage_universal/provider_service/operator_permission_list_provider.dart';
import 'package:gocarriage_universal/provider_service/operator_vechile_booking.dart';
import 'package:gocarriage_universal/provider_service/operator_vechile_request.dart';
import 'package:gocarriage_universal/provider_service/operator_vehicle_post_request_provider.dart';
import 'package:gocarriage_universal/provider_service/oprator_search_registration_number.dart';
import 'package:gocarriage_universal/provider_service/owner_booking_request_list_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_price_quotations_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_profile_update_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_reqest_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_request_approve_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_unassign_driver_vehicle.dart';
import 'package:gocarriage_universal/provider_service/search_driver_provider.dart';
import 'package:gocarriage_universal/provider_service/state_provider.dart';
import 'package:gocarriage_universal/provider_service/subscriptions_owner_list_provider.dart';
import 'package:gocarriage_universal/provider_service/vehicle_details_provider.dart';
import 'package:gocarriage_universal/provider_service/vehicle_model_provider.dart';
import 'package:gocarriage_universal/provider_service/vehicle_type_provider.dart';
import 'package:provider/provider.dart';

import '../eventModel/notification_event.dart';
import '../resource/shared_preferences.dart';
import '../ui/splashScreen/splash_screen.dart';

// ALL PROVIDERS
import 'package:gocarriage_universal/provider_service/accept_reject_provider.dart';
import 'package:gocarriage_universal/provider_service/accept_reject_trip_provider.dart';
import 'package:gocarriage_universal/provider_service/assign_driver_list_provider.dart';
import 'package:gocarriage_universal/provider_service/booking_provider.dart';
import 'package:gocarriage_universal/provider_service/booking_trip.dart';
import 'package:gocarriage_universal/provider_service/check_area_provider.dart';
import 'package:gocarriage_universal/provider_service/cluster_check_provider.dart';
import 'package:gocarriage_universal/provider_service/delete_profile_provider.dart';
import 'package:gocarriage_universal/provider_service/driver_booing_request_provider.dart';
import 'package:gocarriage_universal/provider_service/driver_booking_history_provider.dart';
import 'package:gocarriage_universal/provider_service/driver_booking_ongoing_provider.dart';
import 'package:gocarriage_universal/provider_service/driver_trip_start_provider.dart';
import 'package:gocarriage_universal/provider_service/driver_update_profile_provider.dart';
import 'package:gocarriage_universal/provider_service/email_verify_otp_provider.dart';
import 'package:gocarriage_universal/provider_service/myrides_provider.dart';
import 'package:gocarriage_universal/provider_service/owner_vehicle_assign_provider.dart';
import 'package:gocarriage_universal/provider_service/place_details_provider.dart';
import 'package:gocarriage_universal/provider_service/place_provider.dart';
import 'package:gocarriage_universal/provider_service/profile_provider.dart';
import 'package:gocarriage_universal/provider_service/send_otp_email_provider.dart';
import 'package:gocarriage_universal/provider_service/signIn_service.dart';
import 'package:gocarriage_universal/provider_service/signup_provider.dart';
import 'package:gocarriage_universal/provider_service/status_provider.dart';
import 'package:gocarriage_universal/provider_service/update_profile_provider.dart';
import 'package:gocarriage_universal/provider_service/vechile_owner_driver_list.dart';
import 'package:gocarriage_universal/provider_service/vechile_owner_fleets_list.dart';
import 'package:gocarriage_universal/provider_service/verify_otp_provider.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Prefs.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignInProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => ForgotVerifyOtpProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AcceptRejectTripProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => CheckAreaProvider()),
        ChangeNotifierProvider(create: (_) => ClusterCheckProvider()),
        ChangeNotifierProvider(create: (_) => BookingTrip()),
        ChangeNotifierProvider(create: (_) => DeleteProfileProvider()),
        ChangeNotifierProvider(create: (_) => MyridesProvider()),
        ChangeNotifierProvider(create: (_) => AcceptRejectProvider()),
        ChangeNotifierProvider(create: (_) => DriverBookingHistoryProvider()),
        ChangeNotifierProvider(create: (_) => DriverBookingOngoingProvider()),
        ChangeNotifierProvider(create: (_) => StartTripeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProfileProvider()),
        ChangeNotifierProvider(create: (_) => DriverUpdateProfileProvider()),
        ChangeNotifierProvider(create: (_) => SendOtpEmailProvider()),
        ChangeNotifierProvider(create: (_) => EmailVerifyOtpProvider()),
        ChangeNotifierProvider(create: (_) => VechileOwnerFleetsList()),
        ChangeNotifierProvider(create: (_) => VechileOwnerDriverList()),
        ChangeNotifierProvider(create: (_) => AssignDriverListProvider()),
        ChangeNotifierProvider(create: (_) => OwnerVehicleAssignProvider()),
        ChangeNotifierProvider(create: (_) => OwnerReqestProvider()),
        ChangeNotifierProvider(create: (_) => OwnerRequestApproveProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProfileUpdateProvider()),
        ChangeNotifierProvider(create: (_) => FileUploadProvider()),
        ChangeNotifierProvider(create: (_) => FetchImageUrlProvider()),
        ChangeNotifierProvider(create: (_) => AddCarProvider()),
        ChangeNotifierProvider(create: (_) => VehicleDetailsProvider()),
        ChangeNotifierProvider(create: (_) => VehicleTypeProvider()),
        ChangeNotifierProvider(create: (_) => OwnerPriceQuotationsProvider()),
        ChangeNotifierProvider(create: (_) => AcceptRejectPriceProvider()),
        ChangeNotifierProvider(create: (_) => DraftVehicleProvider()),
        ChangeNotifierProvider(create: (_) => DeleteVehicleProvider()),
        ChangeNotifierProvider(
          create: (_) => OwnerBookingRequestListProvider(),
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionsOwnerListProvider()),
        ChangeNotifierProvider(create: (_) => VerifyOtpProvider()),
        ChangeNotifierProvider(create: (_) => PlaceDetailsProvider()),
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
        ChangeNotifierProvider(create: (_) => StateProvider()),
        ChangeNotifierProvider(create: (_) => VehicleModelProvider()),
        ChangeNotifierProvider(create: (_) => AssignVehicleDriverProvider()),
        ChangeNotifierProvider(create: (_) => SearchDriverProvider()),
        ChangeNotifierProvider(create: (_) => OwnerUnassignDriverVehicle()),
        ChangeNotifierProvider(create: (_) => AssignDriverProvider()),
        ChangeNotifierProvider(create: (_) => OperatorVechileRequest()),
        ChangeNotifierProvider(
          create: (_) => OpratorSearchRegistrationNumber(),
        ),
        ChangeNotifierProvider(create: (_) => OperatorVechileBooking()),
        ChangeNotifierProvider(create: (_) => OperatorPermissionListProvider()),
        ChangeNotifierProvider(
          create: (_) => OperatorVehiclePostRequestProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (context) => DriverBooingRequestProvider(
                Provider.of<BookingProvider>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() async {
    /// 🔹 FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("============ FOREGROUND MESSAGE ============");
      debugPrint("Message ID: ${message.messageId}");
      debugPrint("Title: ${message.notification?.title}");
      debugPrint("Body: ${message.notification?.body}");
      debugPrint("Data: ${message.data}");
      debugPrint("=============================================");

      /*
      final bookingId = message.data['bookingId'];
       Fluttertoast.showToast(
        msg: "$bookingId",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      */

      eventBus.fire(NotificationEvent(message));
    });

    /// 🔹 BACKGROUND (APP IN BACKGROUND → USER TAP)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("============ BACKGROUND TAP MESSAGE ==========");
      debugPrint("Message ID: ${message.messageId}");
      debugPrint("Title: ${message.notification?.title}");
      debugPrint("Body: ${message.notification?.body}");
      debugPrint("Data: ${message.data}");
      debugPrint("==============================================");
      /*
      final bookingId = message.data['bookingId'];
       Fluttertoast.showToast(
        msg: "$bookingId",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );*/
      Provider.of<AudioProvider>(context, listen: false).play();
      eventBus.fire(NotificationEvent(message));
    });

    /// 🔹 TERMINATED (APP KILLED → USER TAP)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint("============ TERMINATED TAP MESSAGE ==========");
      debugPrint("Message ID: ${initialMessage.messageId}");
      debugPrint("Title: ${initialMessage.notification?.title}");
      debugPrint("Body: ${initialMessage.notification?.body}");
      debugPrint("Data: ${initialMessage.data}");
      debugPrint("==============================================");
      /*
      final bookingId = initialMessage.data['bookingId'];
      Fluttertoast.showToast(
        msg: "$bookingId",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
     */
      Future.delayed(const Duration(milliseconds: 500), () {
        eventBus.fire(NotificationEvent(initialMessage));
      });
    } else {
      debugPrint("No initial message (App not opened via notification)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Go carriage',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
