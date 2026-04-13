import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/assign_driver_list_provider.dart';
import '../../../provider_service/owner_unassign_driver_vehicle.dart';
import '../../../resource/Utils.dart';
import '../../../resource/image_paths.dart';
import '../../dialogBox/assign_driver_dialoge.dart';
import 'package:http/http.dart' as http;

class AssignDriverListScreen extends StatefulWidget {
  @override
  _AssignDriverListScreen createState() => _AssignDriverListScreen();
}

class _AssignDriverListScreen extends State<AssignDriverListScreen> {
  bool isLoading = false;
  List<dynamic> filteredList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AssignDriverListProvider>(
        context,
        listen: false,
      );

      await provider.fetchList();

      setState(() {
        filteredList = provider.listData;
      });
    });
  }

  // 🔍 Search Function
  void filterAssignDrivers(String query) {
    final provider = Provider.of<AssignDriverListProvider>(
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
            provider.listData.where((data) {
              final fullName =
                  data['Driver']?['fullName']?.toString().toLowerCase() ?? '';

              final mobile =
                  data['Driver']?['mobileNo']?.toString().toLowerCase() ?? '';

              final serviceType =
                  data['Driver']?['service_type']?.toString().toLowerCase() ??
                  '';

              final assignedDate =
                  Utils.formatIsoDate(data['assigned_at'] ?? '').toLowerCase();

              return fullName.contains(query.toLowerCase()) ||
                  mobile.contains(query.toLowerCase()) ||
                  serviceType.contains(query.toLowerCase()) ||
                  assignedDate.contains(query.toLowerCase());
            }).toList();
      });
    }
  }

  void openAssignDriverDialog(BuildContext context) async {
    await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AssignDriverDialoge(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assign Driver List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => openAssignDriverDialog(context),
            child: const Text(
              'Assign Driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: filterAssignDrivers,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, mobile, service, date...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Consumer<AssignDriverListProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (filteredList.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text('No assign driver list available'),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final data = filteredList[index];
                      final driver = data['Driver'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👤 Avatar
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: AssetImage(
                                    ImagePaths.carIcon,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor:
                                        data['is_active']
                                            ? Colors.green
                                            : Colors.red,
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Name : ${driver['fullName']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  Text(
                                    "Mobile : ${driver['mobileNo']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  Text(
                                    "Service Type : ${driver['service_type'] ?? "--"}",
                                    style: const TextStyle(fontSize: 15),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    "Assigned : ${Utils.formatIsoDate(data['assigned_at'] ?? "--")}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder:
                                  (context) => const [
                                    PopupMenuItem(
                                      value: 'Unassign',
                                      child: Text(
                                        'Unassign',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                              onSelected: (value) {
                                if (value == 'Unassign') {
                                  showDeleteDriverDialog(context,data);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showDeleteDriverDialog(BuildContext context, final data) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Unassign"),
            content: const Text(
              "Are you sure you want to delete this unassigned driver?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  _unAssignDriver(data['driver_id'].toString(), data['vehicle_id'].toString());
                },
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Yes",
                          style: TextStyle(color: Colors.red),
                        ),
              ),
            ],
          ),
    );
  }

  Future<void> _unAssignDriver(String? driverId, String? vehicleId) async {
    if (vehicleId == null) {
      Utils.showErrorMessage(context, "Please select vehicle");
      return;
    }
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return;
    }
    setState(() {
      isLoading = true;
    });
    http.Response response = await Provider.of<OwnerUnassignDriverVehicle>(
      context,
      listen: false,
    ).unAssignDriver(driverId, vehicleId);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<AssignDriverListProvider>(
          context,
          listen: false,
        );

        await provider.fetchList();

        setState(() {
          filteredList = provider.listData;
        });
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() {
        isLoading = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Assign Driver failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }
}
