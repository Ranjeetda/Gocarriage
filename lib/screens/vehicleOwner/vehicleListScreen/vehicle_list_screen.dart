import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../provider_service/delete_vehicle_provider.dart';
import '../../../provider_service/vechile_owner_fleets_list.dart';
import '../../../resource/Utils.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';
import '../../dialogBox/wallet_dialog.dart';
import '../freightCalculatorScreen/trip_cost_preview_screen.dart';
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
                                final reward = vehicle['reward_summary'] ?? {};

                                String payload = (double.tryParse(
                                          vehicle['payload']?.toString() ?? "0",
                                        ) ??
                                        0)
                                    .toStringAsFixed(0);

                                bool docsPending =
                                    vehicle['rc_validity_date'] == null ||
                                    vehicle['fitness_validity_date'] == null ||
                                    vehicle['insurance_upto'] == null ||
                                    vehicle['pollution_validity_date'] == null;

                                Widget docChip(String title, String? date) {
                                  if (date == null) return const SizedBox();

                                  final validity = Utils.getValidity(date);
                                  final days =
                                      int.tryParse(
                                        validity.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        ),
                                      ) ??
                                      0;
                                  final warning = days < 30;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          warning
                                              ? const Color(0xFFFFF7ED)
                                              : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color:
                                              warning
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "$title $validity",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                warning
                                                    ? Colors.orange.shade800
                                                    : Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => VehicleDetailsScreen(
                                              vehicle['id'].toString(),
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        /// HEADER
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              /// Truck Icon
                                              Column(
                                                children: [
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFE0F2FE,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .local_shipping_rounded,
                                                      color: Color(0xFF0284C7),
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFDCFCE7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.verified,
                                                          color: Colors.green,
                                                          size: 12,
                                                        ),
                                                        SizedBox(width: 3),
                                                        Text(
                                                          "Verified",
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(width: 14),

                                              /// Vehicle Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      vehicle['vehicle_number'] ??
                                                          "--",
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 4),

                                                    Text(
                                                      "${vehicle['rto'] ?? "--"}, ${vehicle['fuel_type'] ?? "--"}",
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                        fontSize: 13,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 10),

                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                vehicle['service_type'] ==
                                                                        "outside_city"
                                                                    ? const Color(
                                                                      0xFFFFF7ED,
                                                                    )
                                                                    : const Color(
                                                                      0xFFEFF6FF,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            Utils.formatServiceType(
                                                              vehicle['service_type'] ??
                                                                  "",
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  vehicle['service_type'] ==
                                                                          "outside_city"
                                                                      ? Colors
                                                                          .deepOrange
                                                                      : Colors
                                                                          .blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          width: 8,
                                                        ),

                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                vehicle['status'] ==
                                                                        "active"
                                                                    ? const Color(
                                                                      0xFFF0FDF4,
                                                                    )
                                                                    : const Color(
                                                                      0xFFFFF1F2,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            vehicle['status'] ==
                                                                    "active"
                                                                ? "● Active"
                                                                : "● Inactive",
                                                            style: TextStyle(
                                                              color:
                                                                  vehicle['status'] ==
                                                                          "active"
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .red,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
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
                                                  } else if (value ==
                                                      "delete") {
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
                                        ),

                                        const Divider(height: 1),

                                        /// PAYLOAD & PLAN
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8FAFC,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      const Icon(
                                                        Icons.scale,
                                                        color: Colors.blue,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      const Text(
                                                        "Payload",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        "$payload kg",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8FAFC,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    children: const [
                                                      Icon(
                                                        Icons.workspace_premium,
                                                        color: Colors.amber,
                                                      ),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        "Plan",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      SizedBox(height: 3),
                                                      Text(
                                                        "Normal",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// DOCUMENTS
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Document Validity",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child:
                                              docsPending
                                                  ? Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFF7ED,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .description_outlined,
                                                          color:
                                                              Colors.deepOrange,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          "Documents Pending",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .deepOrange,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  : Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      docChip(
                                                        "RC",
                                                        vehicle['rc_validity_date'],
                                                      ),
                                                      docChip(
                                                        "Fitness",
                                                        vehicle['fitness_validity_date'],
                                                      ),
                                                      docChip(
                                                        "Insurance",
                                                        vehicle['insurance_upto'],
                                                      ),
                                                      docChip(
                                                        "PUC",
                                                        vehicle['pollution_validity_date'],
                                                      ),
                                                    ],
                                                  ),
                                        ),

                                        const SizedBox(height: 18),

                                        /// BOTTOM SECTION
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(18),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              /// Trip Cost
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      vehicle['base_price_per_day'] !=
                                                              null
                                                          ? "₹${vehicle['base_price_per_day']}/day"
                                                          : "--",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => TripCostPreviewScreen(
                                                                  vehicle['id']
                                                                      .toString(),
                                                                  'list',
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          "Trip Cost",
                                                          style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              /// Reward
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star_rounded,
                                                          color: Colors.orange,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          "₹${reward['earned'] ?? 0}",
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      "up to ₹${reward['max_possible'] ?? 0}",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF0F766E,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  String  url =
                                                      "https://vehicleowner.gocarriage.com/plans?"
                                                      "fleet_id=${PrefUtils.getUserId()}"
                                                      "&vnum=${vehicle['vehicle_number']}";
                                                  Utils.openRechargeUrl(url);
                                                },
                                                icon: const Icon(
                                                  Icons.upgrade_rounded,
                                                ),
                                                label: const Text("Upgrade"),
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
