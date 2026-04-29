import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/delete_vehicle_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../provider_service/vechile_owner_fleets_list.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';

import '../../commanScreen/menu_screen.dart';
import '../assignDriverScreen/assign_driver_list_screen.dart';
import '../bookingRequestScreen/booking_request_screen.dart';
import '../driver_list_screen/driver_list_screen.dart';
import '../profile_screen/owner_profile_screen.dart';
import '../quotationScreen/price_quotations_screen.dart';
import '../subscriptionsScreen/subscriptions_screen.dart';
import '../vehicleListScreen/add_vehicle_screen.dart';
import '../vehicleListScreen/select_driver_dialog.dart';
import '../vehicleListScreen/vehicle_details_screen.dart';
import '../vehicleListScreen/vehicle_list_screen.dart';
import '../vehicleRequestScreen/vehicle_request_screen.dart';

class DashboardVehicleOwnerScreen extends StatefulWidget {
  @override
  _DashboardVehicleOwnerScreen createState() => _DashboardVehicleOwnerScreen();
}

class _DashboardVehicleOwnerScreen extends State<DashboardVehicleOwnerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  bool isProfileUpdated = true;
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile('owner', "owner", PrefUtils.getUserId());
      if (provider.profileData.isNotEmpty) {
        setState(() {
          isProfileUpdated = provider.profileData['isProfileUpdated'];
          _showImage(provider.profileData['profile_pic']);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showImage(String fileName) async {
    final response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);
    var responseData = json.decode(response.body);
    if (responseData['success'] == true &&
        responseData['data']?['url'] != null) {
      setState(() {
        profileImage = responseData['data']['url'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData?['message'] ?? 'Failed to load image'),
        ),
      );
    }
  }

  /// ADD VEHICLE
  Future<void> nextScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddVehicleScreen()),
    );
    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<VechileOwnerFleetsList>(
          context,
          listen: false,
        );
        await provider.fetchList("in_city");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FC),

      /// DRAWER
      drawer: Drawer(
        child: ListView(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MenuScreen()),
                );
              },
              child: UserAccountsDrawerHeader(
                accountName: Text(PrefUtils.getName()),
                accountEmail: Text("Vehicle Owner"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      (profileImage.isNotEmpty)
                          ? NetworkImage(profileImage)
                          : null,
                  child:
                      (profileImage.isEmpty)
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                ),
                decoration: BoxDecoration(color: AppColors.primaryColor),
              ),
            ),
            menuItem(Icons.directions_car, "Vehicles"),
            menuItem(Icons.people, "Driver"),
            menuItem(Icons.assignment_ind, "Assign Driver"),
            menuItem(Icons.request_page, "Vehicle Request"),
            menuItem(Icons.price_check, "Price Quotations"),
            menuItem(Icons.book_online, "Booking Requests"),
            menuItem(Icons.account_balance_wallet, "Subscriptions"),
          ],
        ),
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_tabController.index == 0) {
            nextScreen(context);
          } else {
            showDialog(
              context: context,
              builder: (_) => const SelectDriverDialog(),
            );
          }
        },
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            color: AppColors.primaryColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        _scaffoldKey.currentState!.openDrawer();
                      },
                    ),
                    Image.asset(ImagePaths.appLogoVertical, height: 40),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome!", style: TextStyle(color: Colors.white)),
                        Text(
                          PrefUtils.getName(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.notifications, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          isProfileUpdated
              ? SizedBox()
              : profileStatusStrip(isComplete: isProfileUpdated),

          /// TAB BAR
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,

              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.directions_car, size: 18),
                      SizedBox(width: 6),
                      Text("Vehicles"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 6),
                      Text("Drivers"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// TAB VIEW
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                /// VEHICLES TAB
                VehicleListScreen(false),

                /// DRIVERS TAB
                DriverListScreen(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// MENU
  Widget menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);

        if (title == 'Vehicles') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleListScreen(true)),
          );
        } else if (title == 'Driver') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DriverListScreen(true)),
          );
        } else if (title == 'Assign Driver') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssignDriverListScreen()),
          );
        } else if (title == 'Vehicle Request') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleRequestScreen()),
          );
        } else if (title == 'Price Quotations') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PriceQuotationsScreen()),
          );
        } else if (title == 'Booking Requests') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookingRequestScreen()),
          );
        } else if (title == 'Subscriptions') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscriptionsScreen()),
          );
        }
      },
    );
  }

  Widget profileStatusStrip({required bool isComplete}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isComplete ? Colors.green : Colors.orange),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.verified : Icons.warning_amber_rounded,
            color: isComplete ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              isComplete
                  ? "Your profile is complete"
                  : "Your profile is incomplete. Complete it now.",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isComplete ? Colors.green : Colors.orange,
              ),
            ),
          ),

          if (!isComplete)
            TextButton(
              onPressed: () {
                // 👉 Navigate to profile / edit screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OwnerProfileScreen()),
                );
              },
              child: const Text("Complete"),
            ),
        ],
      ),
    );
  }
}
