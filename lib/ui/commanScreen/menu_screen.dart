import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:gocarriage_universal/ui/auth/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../provider_service/delete_profile_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/pref_utils.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../vehicleOwner/profile_screen/owner_profile_screen.dart';
import 'basic_details_form.dart';
import 'common_screen.dart';
import '../driver/driverProfile/driver_profile.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen();

  @override
  _MenuScreen createState() => _MenuScreen();
}

class _MenuScreen extends State<MenuScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          PrefUtils.getRole().toLowerCase() == 'owner'
              ? AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  // Back arrow icon
                  onPressed: () {
                    Navigator.pop(context); // Go back to the previous screen
                  },
                ),
                title: Text(
                  "Menu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primaryColor,
              )
              : null,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              text: 'Edit Profile',
              onTap:
                  () => _navigateTo(
                    PrefUtils.getRole() == "owner"
                        ? OwnerProfileScreen()
                        : PrefUtils.getRole() == "driver"
                        ? DriverProfile('Menu',PrefUtils.getUserId())
                        : BasicDetailsForm(),
                  ),
            ),
            _buildMenuItem(
              icon: Icons.support_agent,
              text: 'Refound Policy',
              onTap:
                  () => _navigateTo(
                    CommonScreen(
                      'https://gocarriage.com/refund-policy',
                      'Refound Policy',
                    ),
                  ),
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              text: 'Privacy Policy',
              onTap:
                  () => _navigateTo(
                    CommonScreen(
                      'https://gocarriage.com/privacy-policy',
                      'Privacy Policy',
                    ),
                  ),
            ),
            _buildMenuItem(
              icon: Icons.article_outlined,
              text: 'Terms & Conditions',
              onTap:
                  () => _navigateTo(
                    CommonScreen(
                      'https://gocarriage.com/terms-condition',
                      'Terms & Conditions',
                    ),
                  ),
            ),
            isLoading
                ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
                : _buildMenuItem(
                  icon: Icons.delete_forever_outlined,
                  text: 'Delete Profile',
                  onTap: () async {
                    bool? confirmed = await _showConfirmationDialog(
                      "Delete Profile",
                      "Are you sure you want to delete your profile?",
                    );
                    if (confirmed == true) {
                      _navigateTo(
                        CommonScreen(
                          'https://gocarriage.com/delete-account',
                          'Delete Profile',
                        ),
                      );
                      // _deleteProfile();
                    }
                  },
                ),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              text: PrefUtils.isLoggedIn() ? 'Logout' : "Login",
              onTap: () async {
                print("==========>${PrefUtils.isLoggedIn()}");
                if (PrefUtils.isLoggedIn() == false) {
                  PrefUtils.setRole('customer');
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageTransition(
                      child: LoginPage(),
                      type: PageTransitionType.fade,
                      duration: const Duration(milliseconds: 900),
                      reverseDuration: const Duration(milliseconds: 900),
                    ),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  bool? confirmed = await _showConfirmationDialog(
                    "Logout",
                    "Are you sure you want to logout?",
                  );
                  if (confirmed == true) {
                    PrefUtils.clearPreferences();
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Yes"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isVisible = true,
  }) {
    if (!isVisible) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.black),
        onTap: onTap,
      ),
    );
  }
}
