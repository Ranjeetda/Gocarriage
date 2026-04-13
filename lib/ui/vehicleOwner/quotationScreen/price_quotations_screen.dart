import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/accept_reject_price_provider.dart';
import '../../../provider_service/owner_price_quotations_provider.dart';
import '../../../provider_service/vechile_owner_fleets_list.dart';
import 'package:http/http.dart' as http;

import '../../../resource/Utils.dart';

class PriceQuotationsScreen extends StatefulWidget {
  @override
  _PriceQuotationsScreen createState() => _PriceQuotationsScreen();
}

class _PriceQuotationsScreen extends State<PriceQuotationsScreen> {
  List<dynamic> filteredList = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  String selectedTab = "all";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<OwnerPriceQuotationsProvider>(
        context,
        listen: false,
      );

      await provider.fetchPriceQuotation();

      setState(() {
        filteredList = provider.priceQutation;
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

  Future<void> _action(String id, String action) async {
    setState(() {
      isLoading = true;
    });

    http.Response response = await Provider.of<AcceptRejectPriceProvider>(
      context,
      listen: false,
    ).validateAcceptReject(id, action);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<OwnerPriceQuotationsProvider>(
          context,
          listen: false,
        );
        await provider.fetchPriceQuotation();

        setState(() {
          filteredList.clear();
          filteredList = provider.priceQutation;
        });
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      String errorMessage =
          responseData['message'] ?? 'accept reject. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
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
          'Price Quotations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [
            /// SEARCH BAR
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
                      onChanged: filterVehicles,
                      decoration: const InputDecoration(
                        hintText: 'Search by vehicle number, type, service...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// TABS
            Row(
              children: [
                buildTab("All", "all"),
                const SizedBox(width: 8),

                buildTab("Active", "active"),
                const SizedBox(width: 8),

                buildTab("Inactive", "inactive"),
              ],
            ),

            const SizedBox(height: 12),

            /// LIST
            Consumer<VechileOwnerFleetsList>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (filteredList.isEmpty) {
                  return const Expanded(
                    child: Center(child: Text('No price quotations list available')),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredList[index];

                      return InkWell(
                        onTap: () {},
                        child: quotationCard(vehicle),
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

  Widget quotationCard(dynamic item) {
    final vehicle = item['vehicle'];
    final quotation = item['quotation'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(Icons.local_shipping, color: Colors.blue),
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quotation['vehicle_type']?['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${quotation['number_of_vehicles']} vehicle needed",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                const Spacer(),

                /// STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['status'].toString().toUpperCase(),
                    style:  TextStyle(
                      color: item['status']=='pending'?Colors.orange:Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          /// ROUTE
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.blue),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    quotation['from_location'] ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    quotation['to_location'] ?? '',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          /// PRICE + VEHICLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                /// PRICE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "₹ Offered Price",
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          "₹${quotation['offered_price']}",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Good Offer",
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                /// VEHICLE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🚚 Your Vehicle"),
                        const SizedBox(height: 6),

                        Text(
                          vehicle['vehicle_number'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text("Base: ₹${vehicle['base_price']}"),
                        Text(vehicle['service_type'] ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// EXPIRY
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.orange),
                const SizedBox(width: 8),

                item['status']=='pending'?Text(
                  "Expires: ${quotation['expires_at']}",
                  style: const TextStyle(color: Colors.orange),
                ):Text(
                  "You accepted this quotation}",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// BUTTONS
           item['status']=='pending'?Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _action(item['response_id'].toString(),'reject');
                    },
                    child:  isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _action(item['response_id'].toString(),'accept');
                    },
                    child:  isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Accept"),
                  ),
                ),
              ],
            ),
          ):SizedBox(),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
