import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../eventModel/notification_event.dart';
import '../../provider_service/bottom_navigation_provider.dart';
import '../../provider_service/version_control_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';

import 'customer_home_screen.dart';
import 'history_screen.dart';
import '../commanScreen/menu_screen.dart';

class CustomerBottomNavigationBar extends StatefulWidget {
  const CustomerBottomNavigationBar({Key? key}) : super(key: key);

  @override
  State<CustomerBottomNavigationBar> createState() =>
      _CustomerBottomNavigationBarState();
}

class _CustomerBottomNavigationBarState
    extends State<CustomerBottomNavigationBar> {

  @override
  void initState() {
    super.initState();

    eventBus.on<NotificationEvent>().listen((event) {
      if (event.message.data['type'] == 'TRIP_COMPLETED') {
        if (!mounted) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        Utils.showSuccessDialog(
          context,
          event.message.data['bookingId'],
        );
      }
    });

    initVersionCheck();
  }

  Future<void> initVersionCheck() async {
    final buildNo = await Utils.getBuildNumber();

    final provider =
    Provider.of<VersionControlProvider>(context, listen: false);

    await provider.fetchList(buildNo);

    handleVersionCheck(provider);
  }

  void handleVersionCheck(VersionControlProvider provider) {
    final data = provider.versionControl['data'];

    if (data == null) return;

    if (data['updateType'] == "force") {
      showUpdateDialog(
        context,
        title: data['title'],
        message: data['message'],
        isForce: true,
        storeUrl: data['storeUrl'],
      );
    }
  }

  void showUpdateDialog(
      BuildContext context, {
        required String title,
        required String message,
        required bool isForce,
        String? storeUrl,
      }) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.system_update_alt,
                  size: 60,
                  color: Colors.blue,
                ),

                const SizedBox(height: 15),

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    if (!isForce)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Later"),
                      ),

                    ElevatedButton(
                      onPressed: () => launchPlayStore(storeUrl),
                      child: const Text("Update Now"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> launchPlayStore(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  final List<Widget> _screens =  [
    CustomerHomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xffF2F4F7),

          body: SafeArea(
            child: _screens[navProvider.currentIndex],
          ),

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: navProvider.currentIndex,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              if (index == 2) {
                // Wallet
                return;
              }

              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(),
                  ),
                );
                return;
              }

              navProvider.changeIndex(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: "Trips",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: "Wallet",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}