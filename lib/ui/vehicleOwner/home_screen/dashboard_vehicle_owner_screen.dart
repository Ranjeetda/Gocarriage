import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/delete_vehicle_provider.dart';
import '../../../provider_service/vechile_owner_fleets_list.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../../commanScreen/menu_screen.dart';
import '../assignDriverScreen/assign_driver_list_screen.dart';
import '../bookingRequestScreen/booking_request_screen.dart';
import '../driver_list_screen/driver_list_screen.dart';
import '../quotationScreen/price_quotations_screen.dart';
import '../subscriptionsScreen/subscriptions_screen.dart';
import '../vehicleListScreen/add_vehicle_screen.dart';
import '../vehicleListScreen/vehicle_details_screen.dart';
import '../vehicleListScreen/vehicle_list_screen.dart';
import '../vehicleRequestScreen/vehicle_request_screen.dart';

class DashboardVehicleOwnerScreen extends StatefulWidget {
  @override
  _DashboardVehicleOwnerScreen createState() => _DashboardVehicleOwnerScreen();
}

class _DashboardVehicleOwnerScreen extends State<DashboardVehicleOwnerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> filteredList = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VechileOwnerFleetsList>(
        context,
        listen: false,
      );

      await provider.fetchList("in_city");

      setState(() {
        filteredList = provider.listData;
      });
    });
  }

  /// SEARCH FUNCTION
  void filterVehicles(String query) {
    final provider = Provider.of<VechileOwnerFleetsList>(
      context,
      listen: false,
    );

    if (query.isEmpty) {
      setState(() {
        filteredList = provider.listData;
      });
    } else {
      setState(() {
        filteredList =
            provider.listData.where((vehicle) {
              final vehicleNo = vehicle['vehicle_number']?.toLowerCase() ?? '';

              final type = vehicle['VehicleType']?['name']?.toLowerCase() ?? '';

              final fuel = vehicle['fuel_type']?.toLowerCase() ?? '';

              return vehicleNo.contains(query.toLowerCase()) ||
                  type.contains(query.toLowerCase()) ||
                  fuel.contains(query.toLowerCase());
            }).toList();
      });
    }
  }

  Future<void> nextScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddVehicleScreen(null)),
    );

    if (result == true) {
      final provider = Provider.of<VechileOwnerFleetsList>(
        context,
        listen: false,
      );

      await provider.fetchList("in_city");

      setState(() {
        filteredList.clear();
        filteredList = provider.listData ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FC),

      /// DRAWER MENU
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuScreen()),
                );
              },
              child: UserAccountsDrawerHeader(
                accountName: Text(
                  PrefUtils.getName(),
                  style: const TextStyle(color: Colors.white),
                ),
                accountEmail: const Text(
                  "Vehicle Owner",
                  style: TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.black),
                ),

                /// BACKGROUND COLOR
                decoration: BoxDecoration(
                  color: AppColors.primaryColor, // your custom color
                ),
              ),
            ),
            menuItem(Icons.directions_car, "Vehicles"),
            menuItem(Icons.request_page, "Vehicle Request"),
            menuItem(Icons.price_check, "Price Quotations"),
            menuItem(Icons.book_online, "Booking Requests"),
            menuItem(Icons.people, "Driver"),
            menuItem(Icons.assignment_ind, "Assign Driver"),
            menuItem(Icons.calculate, "Freight Calculator"),
            menuItem(Icons.account_balance_wallet, "Subscriptions"),
          ],
        ),
      ),

      /// ADD VEHICLE BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          nextScreen(context);
        },
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            color: AppColors.primaryColor, // Safe background for status bar
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    /// BURGER ICON
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        _scaffoldKey.currentState!.openDrawer();
                      },
                    ),

                    Image.asset(ImagePaths.appLogoVertical, height: 40, width: 40),

                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome!",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),

                        Text(
                          PrefUtils.getName(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),

              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: TextField(
                controller: searchController,
                onChanged: filterVehicles,
                decoration: const InputDecoration(
                  hintText: "Search vehicle...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          /// VEHICLE LIST
          Consumer<VechileOwnerFleetsList>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (filteredList.isEmpty) {
                return const Expanded(
                  child: Center(child: Text("No vehicle list available")),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  // 👈 control top space
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final vehicle = filteredList[index];

                    return InkWell(onTap: (){
                      if(vehicle['status']=='draft') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              AddVehicleScreen(vehicle['id'].toString())),
                        );
                      }else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              VehicleDetailsScreen(vehicle['id'].toString())),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),

                      child: _vehicleCard(
                        vehicleId: vehicle['id'].toString() ?? "--",
                        vehicleNo: vehicle['vehicle_number'] ?? "--",
                        status: vehicle['status'] ?? "--",
                        type: vehicle['VehicleType']?['name'] ?? "--",
                        fuel: vehicle['fuel_type'] ?? "--",
                        insurance:
                        vehicle['insurance_upto'] != null
                            ? Utils.formatToDDMMYYYY(
                          vehicle['insurance_upto'],
                        )
                            : "--",
                      ),
                    ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// MENU ITEM
  Widget menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (title == 'Vehicles') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleListScreen()),
          );
        } else if (title == 'Vehicle Request') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleRequestScreen()),
          );
        } else if (title == 'Price Quotations') {

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PriceQuotationsScreen()),
          );
        } else if (title == 'Booking Requests') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookingRequestScreen()),
          );
        } else if (title == 'Booking Requests') {
        } else if (title == 'Driver') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DriverListScreen()),
          );
        } else if (title == 'Assign Driver') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssignDriverListScreen()),
          );
        } else if (title == 'Freight Calculator') {

        }else if (title == 'Subscriptions') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscriptionsScreen()),
          );
        }
      },
    );
  }

  /// VEHICLE CARD
  Widget _vehicleCard({
    required String vehicleId,
    required String status,
    required String vehicleNo,
    required String type,
    required String fuel,
    required String insurance,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        leading: const Icon(
          Icons.local_shipping,
          size: 40,
          color: Colors.green,
        ),

        title: Row(
          children: [
            Text(
              vehicleNo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              Utils.capitalizeFirst(status),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type),
            Text("Fuel: $fuel"),
            Text("Insurance: $insurance"),
          ],
        ),

        // 👇 ADD THIS
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Delete"),
                  content: Text("Are you sure you want to delete this vehicle?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteVehicle(vehicleId); // your function
                      },
                      child: Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  void deleteVehicle(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this vehicle?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              validateDeleteVehicle(id);
              Navigator.pop(context);
              print("Deleted vehicle: $id");
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> validateDeleteVehicle(String vehicleId) async {
    final provider = Provider.of<DeleteVehicleProvider>(context, listen: false);
    await provider.deleteVehicle(vehicleId);
    final data = provider.vehicleDelete;

    setState(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<VechileOwnerFleetsList>(
          context,
          listen: false,
        );
        await provider.fetchList("in_city");
        setState(() {
          filteredList = provider.listData;
        });
      });
      Utils.showCustomToast(context, data['message']);
    });

    print("Vehicle Number: ${data['vehicle_number']}");
  }

}
