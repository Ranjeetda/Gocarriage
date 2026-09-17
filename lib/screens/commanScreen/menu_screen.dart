import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../provider_service/profile_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/pref_utils.dart';
import '../auth/login_screen.dart';
import '../dashboardScreen/corporateScreen/widget/corporate_account_active_card.dart';
import '../dashboardScreen/corporateScreen/widget/corporate_services_card.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../operatorScreen/operator_profile_screen.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).fetchProfile('customer', "customer", PrefUtils.getUserId());
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),

      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              text: 'Edit Profile',
              onTap:
                  () =>  PrefUtils.isLoggedIn()?_navigateTo(
                    PrefUtils.getRole() == "owner"
                        ? OwnerProfileScreen()
                        : PrefUtils.getRole() == "operator"
                        ? OperatorProfileScreen()
                        : PrefUtils.getRole() == "driver"
                        ? DriverProfile('Menu', PrefUtils.getUserId())
                        : BasicDetailsForm(),
                  ):Utils.showMessage(context,'Please login first'),
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
                  _navigateTo(LoginPage());
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
            SizedBox(height: 20,),
            PrefUtils.getRole() == "customer"?Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                final data = profileProvider.profileData;

                return data['customerType']=='corporate'?
                CorporateAccountActiveCard(data):CorporateServicesCard();
              },
            ):SizedBox(),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Yes",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
