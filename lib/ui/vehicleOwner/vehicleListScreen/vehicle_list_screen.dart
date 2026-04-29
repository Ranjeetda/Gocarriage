import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../provider_service/delete_vehicle_provider.dart';
import '../../../provider_service/vechile_owner_fleets_list.dart';
import '../../../resource/Utils.dart';
import '../../../resource/image_paths.dart';
import '../../dialogBox/wallet_dialog.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';
import 'vehicle_details_screen.dart';

class VehicleListScreen extends StatefulWidget {
  bool isHeader;

  VehicleListScreen(this.isHeader);

  @override
  _VehicleListScreen createState() => _VehicleListScreen();
}

class _VehicleListScreen extends State<VehicleListScreen> {
  List<dynamic> filteredList = [];
  TextEditingController searchController = TextEditingController();
  String selectedTab = "all";

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
        filteredList = provider.listData ?? [];
      });
    });
  }

  /// SEARCH FUNCTION
  void filterVehicles(String query) {
    final provider = Provider.of<VechileOwnerFleetsList>(
      context,
      listen: false,
    );

    List list = provider.listData ?? [];

    /// FILTER BY TAB
    if (selectedTab != "all") {
      list =
          list
              .where(
                (v) => v['status']?.toString().toLowerCase() == selectedTab,
              )
              .toList();
    }

    /// SEARCH FILTER
    if (query.isNotEmpty) {
      list =
          list.where((vehicle) {
            final vehicleNumber =
                vehicle['vehicle_number']?.toString().toLowerCase() ?? '';

            final vehicleType =
                vehicle['VehicleType']?['name']?.toString().toLowerCase() ?? '';

            final serviceType =
                vehicle['service_type']?.toString().toLowerCase() ?? '';

            return vehicleNumber.contains(query.toLowerCase()) ||
                vehicleType.contains(query.toLowerCase()) ||
                serviceType.contains(query.toLowerCase());
          }).toList();
    }

    setState(() {
      filteredList = list;
    });
  }

  /// TAB FILTER
  void filterByStatus(String status) {
    final provider = Provider.of<VechileOwnerFleetsList>(
      context,
      listen: false,
    );

    setState(() {
      selectedTab = status;

      if (status == "all") {
        filteredList = provider.listData ?? [];
      } else {
        filteredList =
            provider.listData!
                .where(
                  (vehicle) =>
                      vehicle['status']?.toString().toLowerCase() == status,
                )
                .toList();
      }
    });
  }

  /// TAB UI
  Widget buildTab(String title, String value) {
    bool isSelected = selectedTab == value;

    return GestureDetector(
      onTap: () {
        filterByStatus(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar:
          widget.isHeader
              ? AppBar(
                backgroundColor: AppColors.primaryColor,
                elevation: 2,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'My Vehicle List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      nextScreen(context);
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
              : null,

      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // FIXED

        child: Column(
          children: [
            /// SEARCH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: searchController,
                onChanged: filterVehicles,
                decoration: const InputDecoration(
                  hintText: 'Search vehicle...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 6), // reduced space
            /// TABS
            widget.isHeader
                ? Row(
                  children: [
                    buildTab("All", "all"),
                    const SizedBox(width: 8),
                    buildTab("Active", "active"),
                    const SizedBox(width: 8),
                    buildTab("Inactive", "inactive"),
                  ],
                )
                : const SizedBox.shrink(),

            const SizedBox(height: 6), // reduced space
            /// LIST
            Consumer<VechileOwnerFleetsList>(
              builder: (context, provider, _) {
                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshVehicles,
                    child:
                        provider.isLoading
                            ? shimmerList()
                            /// EMPTY STATE (with pull refresh)
                            : filteredList.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 300),
                                Center(
                                  child: Text('No vehicle list available'),
                                ),
                              ],
                            )
                            /// YOUR ORIGINAL LIST (UNCHANGED)
                            : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final vehicle = filteredList[index];

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => VehicleDetailsScreen(
                                              vehicle['id'].toString(),
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F3F1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),

                                    /// ✅ EVERYTHING BELOW IS YOUR ORIGINAL UI (UNCHANGED)
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Icon(
                                                Icons.local_shipping,
                                                color: Colors.teal,
                                              ),
                                            ),
                                            const SizedBox(width: 10),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  vehicle['vehicle_number'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    vehicle['rto'] ?? '--',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Spacer(),

                                            chip(
                                              vehicle['status'] == "active"
                                                  ? "Active"
                                                  : "Inactive",
                                              vehicle['status'] == "active"
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),

                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == "edit") {
                                                  nextScreenEdit(
                                                    context,
                                                    vehicle,
                                                  );
                                                } else if (value ==
                                                    "Plan & Wallet") {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => WalletDialog(
                                                          vehicle['id']
                                                              .toString(),
                                                          vehicle['vehicle_number'],
                                                        ),
                                                  );
                                                } else if (value == "delete") {
                                                  deleteVehicle(
                                                    vehicle['id'].toString(),
                                                  );
                                                }
                                              },
                                              itemBuilder:
                                                  (context) => const [
                                                    PopupMenuItem(
                                                      value: "edit",
                                                      child: Text("Edit"),
                                                    ),
                                                    PopupMenuItem(
                                                      value: "Plan & Wallet",
                                                      child: Text(
                                                        "Plan & Wallet",
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: "delete",
                                                      child: Text("Delete"),
                                                    ),
                                                  ],
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            const Text('Service : '),
                                            chip(
                                              vehicle['service_type'],
                                              Colors.blue,
                                            ),
                                            Spacer(),
                                            Row(
                                              children: [
                                                const Text('Payload : '),
                                                Text(
                                                  vehicle['payload'] ?? '--',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            const Text('Fuel Type : '),
                                            chip(
                                              vehicle['fuel_type'] ?? '--',
                                              Colors.orange,
                                            ),
                                            Spacer(),
                                            Row(
                                              children: [
                                                const Text('Color : '),
                                                chip(
                                                  vehicle['color'] ?? '--',
                                                  Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "RC - ${vehicle['rc_validity_date'] != null ? Utils.getValidity(vehicle['rc_validity_date']) : ''}",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              Text(
                                                "Fitness - ${vehicle['fitness_validity_date'] != null ? Utils.getValidity(vehicle['fitness_validity_date']) : ''}",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              Text(
                                                "Insurance - ${vehicle['insurance_upto'] != null ? Utils.getValidity(vehicle['insurance_upto']) : ''}",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              Text(
                                                "Pollution - ${vehicle['pollution_validity_date'] != null ? Utils.getValidity(vehicle['pollution_validity_date']) : ''}",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget validityItem(String title, String? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title - ${Utils.getValidity(date)}", style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: getValidityProgress(date),
          minHeight: 6,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(getValidityColor(date)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  double getValidityProgress(String? expiryDateString) {
    if (expiryDateString == null) return 0;

    DateTime expiry = DateTime.parse(expiryDateString);
    DateTime start = expiry.subtract(const Duration(days: 365)); // assumed
    DateTime now = DateTime.now();

    if (now.isAfter(expiry)) return 0;
    if (now.isBefore(start)) return 1;

    double totalDays = expiry.difference(start).inDays.toDouble();
    double remainingDays = expiry.difference(now).inDays.toDouble();

    return (remainingDays / totalDays).clamp(0.0, 1.0);
  }
  Color getValidityColor(String? date) {
    if (date == null) return Colors.grey;

    int diff = DateTime.parse(date).difference(DateTime.now()).inDays;

    if (diff < 0) return Colors.red;
    if (diff < 10) return Colors.orange;
    return Colors.green;
  }

  Widget chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ADD VEHICLE SCREEN
  Future<void> nextScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddVehicleScreen()),
    );

    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<VechileOwnerFleetsList>(
          context,
          listen: false,
        );

        await provider.fetchList("in_city");

        setState(() {
          filteredList = provider.listData ?? [];
        });
      });
    }
  }

  Future<void> nextScreenEdit(BuildContext context, final vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditVehicleScreen(vehicle['id'].toString()),
      ),
    );

    if (result == true) refreshVehicles();
  }

  /// REFRESH
  Future<void> refreshVehicles() async {
    final provider = Provider.of<VechileOwnerFleetsList>(
      context,
      listen: false,
    );

    await provider.fetchList("in_city");

    setState(() {
      filteredList = provider.listData ?? [];
    });
  }

  /// DELETE
  void deleteVehicle(String id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Confirm Delete"),
            content: Text("Are you sure you want to delete this vehicle?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final provider = Provider.of<DeleteVehicleProvider>(
                    context,
                    listen: false,
                  );

                  await provider.deleteVehicle(id);

                  Utils.showCustomToast(
                    context,
                    provider.vehicleDelete['message'],
                  );

                  refreshVehicles();
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget shimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 6,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.white),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: 120, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 80, color: Colors.white),
                      ],
                    ),
                    const Spacer(),
                    Container(height: 20, width: 60, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 10, width: 150, color: Colors.white),
                const SizedBox(height: 10),
                Container(
                  height: 60,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
