import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/owner_un_assign_driver_provider.dart';
import '../../../provider_service/vechile_owner_driver_list.dart';
import '../../../resource/Utils.dart';
import '../../../resource/image_paths.dart';
import '../../driver/driverProfile/driver_profile.dart';
import '../vehicleListScreen/select_driver_dialog.dart';
import 'package:http/http.dart' as http;

class DriverListScreen extends StatefulWidget {
  bool isHeader;

  DriverListScreen(this.isHeader);

  @override
  _DriverListScreen createState() => _DriverListScreen();
}

class _DriverListScreen extends State<DriverListScreen> {
  bool isLoading = false;
  List<dynamic> filteredList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VechileOwnerDriverList>(
        context,
        listen: false,
      );

      await provider.fetchList('in_city');

      setState(() {
        filteredList = provider.listData ?? [];
      });
    });
  }

  // 🔍 Search Function
  void filterDrivers(String query) {
    final provider = Provider.of<VechileOwnerDriverList>(
      context,
      listen: false,
    );

    if (query.isEmpty) {
      setState(() {
        filteredList = provider.listData ?? [];
      });
    } else {
      setState(() {
        filteredList =
            provider.listData!.where((driverData) {
              final fullName =
                  driverData['Driver']?['fullName']?.toString().toLowerCase() ??
                  '';

              final mobile =
                  driverData['Driver']?['mobileNo']?.toString().toLowerCase() ??
                  '';

              final email =
                  driverData['Driver']?['email']?.toString().toLowerCase() ??
                  '';

              final serviceType =
                  driverData['Driver']?['service_type']
                      ?.toString()
                      .toLowerCase() ??
                  '';

              return fullName.contains(query.toLowerCase()) ||
                  mobile.contains(query.toLowerCase()) ||
                  email.contains(query.toLowerCase()) ||
                  serviceType.contains(query.toLowerCase());
            }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                  'Driver List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SelectDriverDialog(),
                      );
                    },
                    child: const Text(
                      'Add Driver',
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
                      onChanged: filterDrivers,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, mobile, email, service...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Consumer<VechileOwnerDriverList>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (filteredList.isEmpty) {
                  return const Expanded(
                    child: Center(child: Text('No driver list available')),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final driverData = filteredList[index];
                      final driver = driverData['Driver'];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DriverProfile(
                                    'ownerDriverList',
                                    driver['id'].toString(),
                                  ),
                            ),
                          );
                        },
                        child: Container(
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
                                          driverData['is_active']
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

                              // 📋 Driver Details
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
                                      "Email : ${driver['email']}",
                                      style: const TextStyle(fontSize: 15),
                                    ),

                                    Text(
                                      "Service Type : ${driver['service_type'] ?? "--"}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),

                              // ⋮ Menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'Unassign') {
                                    showDeleteDriverDialog(context, driverData);
                                  }
                                },
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
                              ),
                            ],
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
      ),
    );
  }

  Future<void> showDeleteDriverDialog(BuildContext context, final data) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Unassign Driver"),
            content: const Text(
              "Are you sure you want to Unassign this driver?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  _unAssignDriver(data['driver_id']);
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

  Future<void> _unAssignDriver(String? driverId) async {
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return;
    }
    setState(() {
      isLoading = true;
    });
    http.Response response = await Provider.of<OwnerUnAssignDriverProvider>(
      context,
      listen: false,
    ).unAssignDriver(driverId);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<VechileOwnerDriverList>(
          context,
          listen: false,
        );

        await provider.fetchList('in_city');

        setState(() {
          filteredList = provider.listData ?? [];
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
          responseData['message'] ??
          'Unassign Driver failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }
}
