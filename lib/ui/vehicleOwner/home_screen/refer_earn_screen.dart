import 'package:flutter/material.dart';

import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text(
          "Refer & Earn",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Gradient Card
            Container(
              width: double.infinity,
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF6BA9F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Refer your Friend",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Earn 150 Points",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    ImagePaths.coins,
                    height: 70,
                  )
                ],
              ),
            ),

            /// Points Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(ImagePaths.star, height: 32),
                      const SizedBox(width: 8),
                      const Text(
                        "300 Pts",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Total Points Earn"),
                  const Divider(),
                  const Text(
                    "Referral code",
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "4154595FGV",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.normal),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.buttonGreen,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Copy",
                          style:
                          TextStyle(color: Colors.green, fontSize: 16),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            /// Steps Card with Timeline + Man Image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Left Side Timeline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _timelineStep(
                          ImagePaths.invite,
                          "Invite your friend to install the app with the link",
                          isFirst: true,
                        ),
                        _timelineStep(
                          ImagePaths.rides,
                          "Your friend must complete at least 2 rides",
                        ),
                        _timelineStep(
                          ImagePaths.wallets,
                          "You get 150 Points once the 2nd ride is completed",
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Right Side Man Image
                  Image.asset(
                    ImagePaths.man,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            /// Bottom banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Popular in Reward"),
                  Text(
                    "You have 300Pts",
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Timeline Step Widget
  Widget _timelineStep(String asset, String text,
      {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Timeline + Icon
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 12, color: Colors.blue),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                color: Colors.white,
              ),
              child: Image.asset(asset, height: 20, width: 20),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: Colors.blue),
          ],
        ),
        const SizedBox(width: 8),

        /// Step Text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
