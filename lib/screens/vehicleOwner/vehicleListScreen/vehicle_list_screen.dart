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
                                                  vehicle['vehicle_number']??'--',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade50,
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
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        vehicle['verificationStatus'] ??
                                                            '--',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                                              Utils.formatServiceType(
                                                vehicle['service_type']??'No_Service',
                                              ),
                                              Colors.blue,
                                            ),
                                            Spacer(),
                                            Row(
                                              children: [
                                                const Text('Payload : '),
                                                Text(
                                                  int.parse(
                                                        double.parse(
                                                          vehicle['payload']??'0.00',
                                                        ).toStringAsFixed(0),
                                                      ).toString() ??
                                                      '--',
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

                                        SizedBox(height: 10),
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
                                        SizedBox(height: 10),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // REWARD TAG
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                color: Colors.teal.shade100,
                                                child: const Text(
                                                  "REWARD",
                                                  style: TextStyle(
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              // PRICE ROW
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star_border,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "₹${vehicle['reward_summary']['earned']}",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.teal,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "/₹${vehicle['reward_summary']['max_possible']}",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // GREEN BADGE
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors.green,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "+₹${vehicle['reward_summary']['category_points']}",
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
