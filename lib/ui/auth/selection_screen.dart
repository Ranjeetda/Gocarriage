import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/ui/auth/sign_up_screen.dart';
import '../../resource/app_colors.dart';

class SelectionScreen extends StatefulWidget {
  String role;

  SelectionScreen(this.role);

  @override
  _SelectionScreen createState() => _SelectionScreen();
}

class _SelectionScreen extends State<SelectionScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Select Your Account Mode',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'CustomFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            accountTypeCard(
              title: "Individual",
              subtitle:
              "For individual vehicle owners looking to manage and track their vehicles efficiently",
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen(widget.role,"Individual")),
                );

              },
              icon: getAccountIcon("Individual"),
            ),

            const SizedBox(height: 12),

            accountTypeCard(
              title: "Company",
              subtitle:
              "For transport companies managing multiple vehicles and operations seamlessly",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen(widget.role,"Company")),
                );

              },
              icon: getAccountIcon("Company"),
            ),

            const SizedBox(height: 12),

            PrefUtils.getRole()!='Vehicle Owner'?accountTypeCard(
              title: "Transporter",
              subtitle:
              "For transport operators optimizing routes and improving delivery efficiency",
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen(widget.role,"Transporter")),
                );
              },
              icon: getAccountIcon("Transporter"),
            ):SizedBox(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // ICON PICKER BASED ON NAME
  // ---------------------------------------------------------
  IconData getAccountIcon(String name) {
    switch (name.toLowerCase()) {
      case "individual":
        return Icons.person;

      case "company":
        return Icons.business;

      case "transporter":
        return Icons.local_shipping;

      default:
        return Icons.help_outline; // fallback
    }
  }

  // ---------------------------------------------------------
  // REUSABLE ACCOUNT TYPE CARD
  // ---------------------------------------------------------
  Widget accountTypeCard({
    required String title,
    required String subtitle,
    required Function() onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              circleCardIcon(
                icon: icon,
                size: 40,
                background: AppColors.button_color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              const Icon(Icons.arrow_forward, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // CIRCLE ICON WIDGET
  // ---------------------------------------------------------
  Widget circleCardIcon({
    required IconData icon,
    double size = 50,
    Color background = Colors.pink,
    Color iconColor = Colors.white,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.55,
        ),
      ),
    );
  }
}
