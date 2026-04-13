import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/ui/auth/login_screen.dart';
import 'package:page_transition/page_transition.dart';

import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import '../auth/selection_app_screen.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../dashboardScreen/customer_home_screen.dart';

class SliderScreen extends StatefulWidget {
  const SliderScreen({Key? key}) : super(key: key);

  @override
  _SliderScreenState createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> sliderContent = [
    {
      "title": "Making your drive\nbest is our\nresponsibility",
      "subtitle": "Reliable rides with safety and comfort at every step",
    },
    {
      "title": "Drive with comfort\nand confidence\nanywhere",
      "subtitle": "Professional drivers and smooth rides",
    },
    {
      "title": "Your journey\nstarts here\nwith us",
      "subtitle": "Join us for safer and faster transport",
    },
  ];

  @override
  void initState() {
    super.initState();
    PrefUtils.setFirstTime(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                ImagePaths.onboarding,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.45,
              ),
            ),
            // Car Image
            _currentIndex==0?Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              left: -155,
              right: 0,
              child: Image.asset(
                ImagePaths.half,
                fit: BoxFit.contain,
                height: 200,
              ),
            ):_currentIndex==1?SizedBox():Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              left: -155,
              right: 0,
              child: Image.asset(
                ImagePaths.half,
                fit: BoxFit.contain,
                height: 200,
              ),
            ),
            // Bottom content
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: sliderContent.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              sliderContent[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF112539),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              sliderContent[index]["subtitle"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    sliderContent.length,
                        (index) => Indicator(isActive: index == _currentIndex),
                  ),
                ),

                const SizedBox(height: 32),

                // Get Started Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          PageTransition(
                              child: CustomerBottomNavigationBar(),
                              type: PageTransitionType.fade,
                              duration: const Duration(milliseconds: 900),
                              reverseDuration: (const Duration(milliseconds: 900))),
                              (Route<dynamic> route) => false);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Terms & Privacy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text.rich(
                    TextSpan(
                      text:
                      "By continuing, you agree that you have read and accept our ",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                      children: [
                        TextSpan(
                          text: "T&Cs",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final bool isActive;

  const Indicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 20 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : AppColors.cyancolor,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
