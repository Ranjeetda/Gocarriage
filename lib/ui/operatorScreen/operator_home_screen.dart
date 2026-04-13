import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';

import '../../provider_service/operator_vechile_request.dart';
import '../dialogBox/search_vehicle_dialog.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({Key? key}) : super(key: key);

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  int selectedIndex = 0;

  final List<String> tabs = [
    "Total",
    "Draft",
    "Confirmed",
    "Active",
    "Complete",
    "Cancel",
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<OperatorVechileRequest>(
      context,
      listen: false,
    ).fetchVehicleRequest());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// SEARCH BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => SearchVehicleDialog(),
          );
        },
      ),

      body: SafeArea(
        child: Consumer<OperatorVechileRequest>(
          builder: (context, providerData, child) {
            if (providerData.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allRequests = providerData.vehicleRequestList;

            /// COUNTS
            int totalCount = allRequests.length;

            int draftCount = allRequests
                .where((e) => e['status'].toString().toLowerCase() == "draft")
                .length;

            int confirmedCount = allRequests
                .where((e) =>
            e['status'].toString().toLowerCase() == "confirmed")
                .length;

            int activeCount = allRequests
                .where((e) => e['status'].toString().toLowerCase() == "active")
                .length;

            int completeCount = allRequests
                .where((e) => e['status'].toString().toLowerCase() == "complete")
                .length;

            int cancelCount = allRequests
                .where((e) => e['status'].toString().toLowerCase() == "cancel")
                .length;

            List counts = [
              totalCount,
              draftCount,
              confirmedCount,
              activeCount,
              completeCount,
              cancelCount
            ];

            /// FILTER LIST
            List filteredList = [];

            if (selectedIndex == 0) {
              filteredList = allRequests;
            } else if (selectedIndex == 1) {
              filteredList = allRequests
                  .where((e) =>
              e['status'].toString().toLowerCase() == "draft")
                  .toList();
            } else if (selectedIndex == 2) {
              filteredList = allRequests
                  .where((e) =>
              e['status'].toString().toLowerCase() == "confirmed")
                  .toList();
            } else if (selectedIndex == 3) {
              filteredList = allRequests
                  .where((e) =>
              e['status'].toString().toLowerCase() == "active")
                  .toList();
            } else if (selectedIndex == 4) {
              filteredList = allRequests
                  .where((e) =>
              e['status'].toString().toLowerCase() == "complete")
                  .toList();
            } else if (selectedIndex == 5) {
              filteredList = allRequests
                  .where((e) =>
              e['status'].toString().toLowerCase() == "cancel")
                  .toList();
            }

            return Column(
              children: [
                /// GRID
              //  bookingOverviewGrid(),

                //const SizedBox(height: 20),

                /// TAB BAR
                Container(
                  height: 55,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xffC8E6C9),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(tabs.length, (index) {
                        bool isSelected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.all(4),
                            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                              isSelected ? const Color(0xff4CAF50) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  tabs[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    counts[index].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xff4CAF50)
                                          : Colors.black87,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// LIST
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(
                      child: Text(
                          'No Vehicle permission requests available.'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return requestCard(filteredList[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// BOOKING OVERVIEW GRID
  //////////////////////////////////////////////////////

  Widget bookingOverviewGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      childAspectRatio: 2,
      children: [
        statsCard("Total", "2", Icons.description, Colors.grey),
        statsCard("Pending", "0", Icons.note, Colors.grey),
        statsCard("Approved", "2", Icons.check_circle, Colors.green),
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// STATS CARD
  //////////////////////////////////////////////////////

  Widget statsCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Icon(icon, color: color, size: 28)
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// REQUEST CARD
  //////////////////////////////////////////////////////

  Widget requestCard(final vehicleData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// VEHICLE + OWNER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleData['Fleet']['vehicle_number'],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Chassis: ${vehicleData['Fleet']['chassis_number']}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              statusChip(vehicleData['status']),
            ],
          ),

          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicleData['Owner']['ownerName'],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(vehicleData['Owner']['email'],
                  style: const TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 10),
          Text("City : "+vehicleData['Owner']['city'],
              style: const TextStyle(color: Colors.black)),
          const SizedBox(height: 10),

          const Text(
            "Requested Permissions",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: (vehicleData['requested_permissions'] as List)
                .map((p) => permissionChip(p['name']))
                .toList(),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                "Approved  :${vehicleData['status']}",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                Utils.formatToDDMMYYYY(vehicleData['createdAt']),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// STATUS CHIP
  //////////////////////////////////////////////////////

  Widget statusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case "approved":
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;

      case "rejected":
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;

      default:
        bgColor = const Color(0xffFDF6EC);
        textColor = const Color(0xffD97706);
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// PERMISSION CHIP
  //////////////////////////////////////////////////////

  Widget permissionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
        const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
    );
  }
}