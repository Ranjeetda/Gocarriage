import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../eventModel/notification_event.dart';
import '../../provider_service/bottom_navigation_provider.dart';
import '../../provider_service/corprote_me_service.dart';
import '../../provider_service/version_control_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import 'bulk_booking_screen.dart';
import 'customer_dashboard.dart';
import 'book_vehicle_screen.dart';
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

    // Fetch corporate data as soon as the bottom bar loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CorproteMeService>(context, listen: false).fetchCorproteMe();
    });

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottomNavigationProvider, CorproteMeService>(
      builder: (context, navProvider, corporateService, child) {
        // 🔑 Decide whether to show Bulk Booking
        final bool showBulkBooking =
            corporateService.corporateMe != null &&
                corporateService.corporateMe!['verificationStatus'] == 'verified';

        // Build screens dynamically
        final List<Widget> screens = [
          const CustomerDashboard(),
          const BookVehicleScreen(),
          if (showBulkBooking) const BulkBookingScreen(),
          const HistoryScreen(),
        ];

        // Build bottom nav items dynamically
        final List<BottomNavigationBarItem> items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: "Book Vehicle",
          ),
          if (showBulkBooking)
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: "Bulk Booking",
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "Trips",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

        // Map the selected index correctly when Bulk Booking is hidden
        int currentIndex = navProvider.currentIndex;

        // Safety: if Bulk Booking is hidden and the stored index is out of range
        if (!showBulkBooking && currentIndex >= 2) {
          // Shift index down by 1 for Trips / Profile
          currentIndex = currentIndex - 1;
          if (currentIndex >= screens.length) {
            currentIndex = screens.length - 1;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xffF2F4F7),
          body: SafeArea(
            child: corporateService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : screens[currentIndex.clamp(0, screens.length - 1)],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: currentIndex.clamp(0, items.length - 1),
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              // Profile is always the last item
              if (index == items.length - 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MenuScreen(),
                  ),
                );
                return;
              }

              // Convert UI index → internal index
              int realIndex = index;
              if (!showBulkBooking && index >= 2) {
                realIndex = index + 1; // skip the missing Bulk Booking slot
              }

              navProvider.changeIndex(realIndex);
            },
            items: items,
          ),
        );
      },
    );
  }
}