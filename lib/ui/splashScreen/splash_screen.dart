import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:page_transition/page_transition.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../driver/home_screen/driver_bottom_navigationBar.dart';
import '../operatorScreen/operator_bottom_navigationbar.dart';
import '../sliderScreen/slider_screen.dart';
import '../vehicleOwner/home_screen/dashboard_vehicle_owner_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  var splashDuration = 2000;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    // 👇 Animation controller for zoom in/out
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // one zoom cycle
    )..repeat(reverse: true); // repeat zoom in/out

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    startCountdownTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(ImagePaths.appLogoVertical, height: 120, width: 120),
        ),
      ),
    );
  }

  Future<Timer> startCountdownTimer() async {
    final duration = Duration(milliseconds: splashDuration);
    return Timer(duration, navigateToPage);
  }

  Future<void> navigateToPage() async {
    if (PrefUtils.isFirstTime()==false) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: SliderScreen(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    } else if (PrefUtils.getRole()=="driver"&&PrefUtils.isLoggedIn()) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: DriverBottomNavigationbar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }else if (PrefUtils.getRole()=="customer"&&PrefUtils.isLoggedIn()) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: CustomerBottomNavigationBar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }else if (PrefUtils.getRole()=="operator"&&PrefUtils.isLoggedIn()) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: OperatorBottomNavigationbar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    } else if (PrefUtils.getRole() == "owner"&&PrefUtils.isLoggedIn()) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: DashboardVehicleOwnerScreen(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
            (Route<dynamic> route) => false,
      );
    }else {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: CustomerBottomNavigationBar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }
}
