import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
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
import '../../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../BulkShipmentScreen/bulk_shipment_tenders_screen.dart';
import '../assignDriverScreen/assign_driver_list_screen.dart';
import '../bookingRequestScreen/booking_request_screen.dart';
import '../driver_list_screen/driver_list_screen.dart';
import '../freightCalculatorScreen/freight_calculator_screen.dart';
import '../my_rewards/my_rewards.dart';
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
    with TickerProviderStateMixin {          // ← changed to TickerProviderStateMixin
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  late AnimationController _drawerAnimController;   // ← new

  bool isProfileUpdated = true;
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    PrefUtils.setAdminToken('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Mjk5LCJyb2xlIjoic3VwZXJhZG1pbiIsImVtYWlsIjoic3VwZXJhZG1pbkBnb2NhcnJpYWdlLmNvbSIsImN1c3RvbWVySWQiOm51bGwsImRyaXZlcklkIjpudWxsLCJvd25lcklkIjpudWxsLCJvcGVyYXRvcklkIjpudWxsLCJmdWVsU3RhdGlvbklkIjpudWxsLCJzZXJ2aWNlQ2VudGVySWQiOm51bGwsImRoYWJhSWQiOm51bGwsImlhdCI6MTc4NTkxMDg4MywiZXhwIjoxNzg2NTE1NjgzfQ.L4Cz6lEy5p760aR3qFAFgGzSHGS-y8tHAcXrYjT-zoU');
    // Drawer animation controller
    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile('owner', "owner", PrefUtils.getUserId());
      if (provider.profileData.isNotEmpty) {
        setState(() {
          isProfileUpdated = provider.profileData['isProfileUpdated'];
          _showImage(provider.profileData['profile_pic'] ?? '');
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drawerAnimController.dispose();   // ← dispose it
    super.dispose();
  }

  Future<void> _showImage(String fileName) async {
    if (fileName.isEmpty) {
      return;
    }
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

      // Restart animation every time drawer opens
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerAnimController.forward(from: 0);
        } else {
          _drawerAnimController.reset();
        }
      },

      /// DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
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
                margin: EdgeInsets.zero,
                accountName: Text(PrefUtils.getName()),
                accountEmail: const Text("Vehicle Owner"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.black)
                      : null,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                ),
              ),
            ),

            // Animated menu items
            _buildAnimatedMenuItem(0, Icons.directions_car, "Vehicles"),
            _buildAnimatedMenuItem(1, Icons.people, "Driver"),
            _buildAnimatedMenuItem(2, Icons.assignment_ind, "Assign Driver"),
            _buildAnimatedMenuItem(3, Icons.request_page, "Vehicle Request"),
            _buildAnimatedMenuItem(4, Icons.price_check, "Price Quotations"),
            _buildAnimatedMenuItem(4, Icons.flash_on, "Instant Request"),
            _buildAnimatedMenuItem(5, Icons.request_quote, "Bulk Tenders"),
            _buildAnimatedMenuItem(5, Icons.calculate, "Vehicle Freight"),
            _buildAnimatedMenuItem(6, Icons.book_online, "Booking Requests"),
            _buildAnimatedMenuItem(7, Icons.account_balance_wallet, "Subscriptions"),
            _buildAnimatedMenuItem(8, Icons.emoji_events, "My Rewards"),
          ],
        ),
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        _scaffoldKey.currentState!.openDrawer();
                      },
                    ),
                    Image.asset(ImagePaths.appLogoVertical, height: 40),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome!",
                            style: TextStyle(color: Colors.white)),
                        Text(
                          PrefUtils.getName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.house, color: Colors.white),
                          onPressed: () {
                            PrefUtils.clearPreferences();
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                child: CustomerBottomNavigationBar(),
                                type: PageTransitionType.fade,
                                duration: const Duration(milliseconds: 900),
                                reverseDuration:
                                const Duration(milliseconds: 900),
                              ),
                                  (Route<dynamic> route) => false,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.notifications, color: Colors.white),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          isProfileUpdated
              ? const SizedBox()
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
                VehicleListScreen(false),
                DriverListScreen(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Animated menu item
  Widget _buildAnimatedMenuItem(int index, IconData icon, String title) {
    final Animation<double> animation = CurvedAnimation(
      parent: _drawerAnimController,
      curve: Interval(
        (index * 0.07).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(40 * (1 - animation.value), 0), // slide from right
            child: child,
          ),
        );
      },
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
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
          } else if (title == 'Bulk Tenders') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BulkShipmentTendersScreen()),
            );
          } else if (title == 'Vehicle Freight') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FreightCalculatorScreen()),
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
          } else if (title == 'My Rewards') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RewardsScreen()),
            );
          }
        },
      ),
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