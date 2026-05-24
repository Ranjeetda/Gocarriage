import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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

  Future<void> refreshDrivers() async {
    final provider = Provider.of<VechileOwnerDriverList>(
      context,
      listen: false,
    );

    await provider.fetchList('in_city');

    setState(() {
      filteredList = provider.listData ?? [];
    });
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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

            Expanded(
              child: Consumer<VechileOwnerDriverList>(
                builder: (context, provider, _) {
                  return RefreshIndicator(
                    onRefresh: refreshDrivers,
                    child:
                        (provider.isLoading && filteredList.isEmpty)
                            ? shimmerList()
                            : filteredList.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 300),
                                Center(child: Text('No driver list available')),
                              ],
                            )
                            : MediaQuery.removePadding(
                              context: context,
                              removeTop: true,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final driverData = filteredList[index];
                                  final driver = driverData['Driver'];

                                  /// 👇 your card widget here
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
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// TOP ROW (Avatar + Name + Status)
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundImage: AssetImage(
                                                  ImagePaths.carIcon,
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      driver['fullName'] ?? "",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 6),

                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            driverData['is_active']
                                                                ? Colors.green
                                                                    .withOpacity(
                                                                      0.1,
                                                                    )
                                                                : Colors.orange
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        driver['driver_assigned_status']
                                                            ? "On Vehicle"
                                                            : "Available",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              driver['driver_assigned_status']
                                                                  ? Colors
                                                                      .orange
                                                                  : Colors
                                                                      .green,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'Unassign') {
                                                    showUnassignDialog(
                                                      context,
                                                      driverData,
                                                    );
                                                  }
                                                },
                                                itemBuilder:
                                                    (context) => const [
                                                      PopupMenuItem(
                                                        value: 'Unassign',
                                                        child: Text(
                                                          "Unassign",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),
                                          const Divider(),

                                          const SizedBox(height: 8),

                                          /// PHONE
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(driver['mobileNo'] ?? ""),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          /// LOCATION
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  "Within City",
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          /// LICENSE ROW
                                          /* Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: const [
                                                  Icon(
                                                    Icons.description,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text("License"),
                                                ],
                                              ),

                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  "${Utils.getValidity(driverData['assigned_at'])}",
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),*/
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
            ),
          ],
        ),
      ),
    );
  }

  void showUnassignDialog(BuildContext context, final data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        bool isLoading = false; // 👈 local state

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_off,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Unassign Driver",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Remove from your fleet",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Unassign "${data['Driver']['fullName']}"? They will become available for other fleet owners.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        /// ✅ CONFIRM BUTTON WITH LOADER
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      setStateDialog(() => isLoading = true);

                                      bool success = await _unAssignDriver(
                                        data['driver_id'].toString(),
                                      );

                                      setStateDialog(() => isLoading = false);

                                      if (success) {
                                        Navigator.pop(
                                          context,
                                        ); // ✅ close ONLY on success
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      "Yes, Unassign",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide.none,
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _unAssignDriver(String? driverId) async {
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return false;
    }

    setState(() => isLoading = true);

    http.Response response = await Provider.of<OwnerUnAssignDriverProvider>(
      context,
      listen: false,
    ).unAssignDriver(driverId);

    var responseData = json.decode(response.body);

    setState(() => isLoading = false);

    if (responseData['success'] == true) {
      final provider = Provider.of<VechileOwnerDriverList>(
        context,
        listen: false,
      );

      await provider.fetchList('in_city');

      setState(() {
        filteredList = provider.listData ?? [];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));

      return true; // ✅ success
    } else {
      String errorMessage =
          responseData['message'] ??
          'Unassign Driver failed. Please try again.';

      Utils.showErrorMessage(context, errorMessage);

      return false; // ❌ failure
    }
  }

  Widget shimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 26, backgroundColor: Colors.white),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 120, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 100, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 150, color: Colors.white),
                    ],
                  ),
                ),

                Container(height: 20, width: 20, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
