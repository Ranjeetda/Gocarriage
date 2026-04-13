import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';

import '../auth/login_screen.dart';
import '../auth/selection_screen.dart';
import '../auth/sign_up_screen.dart';

class LoginRegisterDialog extends StatelessWidget {
  final String mCategoryType;

  LoginRegisterDialog(this.mCategoryType);

  @override
  Widget build(BuildContext context) {
    print("============ $mCategoryType");

    // Set role properly

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dialogItem(
              icon: Icons.login,
              title: "Login",
              onTap: () {
                Navigator.pop(context, true); // ✅ return true
                if (mCategoryType == 'Customer') {
                  PrefUtils.setRole('customer');
                } else if (mCategoryType == 'Vehicle Owner') {
                  PrefUtils.setRole('owner');
                } else if (mCategoryType == 'Driver') {
                  PrefUtils.setRole('driver');
                } else if (mCategoryType == 'Operator') {
                  PrefUtils.setRole('operator');
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
            const Divider(height: 1),
            dialogItem(
              icon: Icons.app_registration,
              title: "Registration",
              onTap: () {
                Navigator.pop(context, true); // ✅ return true
                if (mCategoryType == 'Customer') {
                  PrefUtils.setRole('customer');
                } else if (mCategoryType == 'Vehicle Owner') {
                  PrefUtils.setRole('owner');
                } else if (mCategoryType == 'Driver') {
                  PrefUtils.setRole('driver');
                } else if (mCategoryType == 'Operator') {
                  PrefUtils.setRole('operator');
                }

                if (mCategoryType == "Driver") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SignUpScreen(mCategoryType, "Individual"),
                    ),
                  );
                } else if (mCategoryType == "Customer") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SignUpScreen(mCategoryType, "Individual"),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SelectionScreen(mCategoryType),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget dialogItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 26,
              color: const Color(0xFF374151),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}