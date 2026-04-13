import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/owner_booking_request_list_provider.dart';
import '../../../resource/app_colors.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {

  int selectedTab = 0;

  List<String> tabs = [
    "All",
    "Confirmed",
    "Active",
    "Completed",
    "Draft",
    "Cancelled"
  ];

  /// Track expanded vehicles
  Map<int, bool> expandedMap = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider =
      Provider.of<OwnerBookingRequestListProvider>(context, listen: false);

      await provider.fetchList();
    });
  }

  /// FILTER VEHICLES BASED ON BOOKING STATUS
  List<dynamic> getFilteredVehicles(List<dynamic> apiData) {

    if (selectedTab == 0) {
      return apiData;
    }

    String status = tabs[selectedTab].toLowerCase();

    return apiData.where((vehicle) {

      List bookings = vehicle["bookings"] ?? [];

      return bookings.any(
              (b) => (b["booking_status"] ?? "").toLowerCase() == status);

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Booking Request',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          /// STATUS TABS
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tabs.length,
              itemBuilder: (context, index) {

                bool selected = selectedTab == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTab = index;
                    });
                  },

                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8),

                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.teal
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// VEHICLE LIST
          Consumer<OwnerBookingRequestListProvider>(
            builder: (context, provider, _) {

              if (provider.isLoading) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (provider.listData.isEmpty) {
                return const Expanded(
                  child: Center(child: Text("No vehicles found")),
                );
              }

              final vehicles =
              getFilteredVehicles(provider.listData);

              if (vehicles.isEmpty) {
                return const Expanded(
                  child: Center(child: Text("No bookings found")),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {

                    final vehicle = vehicles[index];

                    return vehicleCard(vehicle, index);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// VEHICLE CARD
  Widget vehicleCard(dynamic vehicle, int index) {

    final driver = vehicle["assigned_driver"];
    final bookings = vehicle["bookings"] ?? [];

    bool isExpanded = expandedMap[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),

      child: Column(
        children: [

          /// HEADER
          InkWell(
            onTap: () {
              setState(() {
                expandedMap[index] = !isExpanded;
              });
            },

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Row(
                children: [

                  /// VEHICLE ICON
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// VEHICLE INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          vehicle["vehicle_number"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          vehicle["vehicle_type"]?["name"] ??
                              "Unknown Vehicle",
                          style: const TextStyle(
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  /// DRIVER
                  if (driver != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Text(
                          driver["name"],
                          style: const TextStyle(fontSize: 12),
                        ),

                        Text(
                          driver["phone"],
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),

                  const SizedBox(width: 10),

                  /// ARROW
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 28,
                  )
                ],
              ),
            ),
          ),

          /// BOOKINGS LIST
          if (isExpanded)
            Column(
              children: [

                if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No bookings for this vehicle"),
                  ),

                ...bookings.map<Widget>((booking) {
                  return bookingCard(booking);
                }).toList()
              ],
            )
        ],
      ),
    );
  }

  /// BOOKING CARD
  Widget bookingCard(dynamic booking) {

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10),

      child: Column(
        children: [

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              Text(
                booking["booking_ref"] ?? "",
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),

              Text(
                booking["booking_date"]
                    ?.toString()
                    .substring(0, 10) ??
                    "",
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [

              const Icon(Icons.circle,
                  size: 8, color: Colors.blue),

              const SizedBox(width: 6),

              Expanded(
                  child: Text(
                      booking["from_location"] ?? "")),

              const Icon(Icons.arrow_forward, size: 16),

              Expanded(
                  child: Text(
                      booking["to_location"] ?? "")),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  booking["booking_status"] ?? "",
                  style: const TextStyle(
                      color: Colors.orange),
                ),
              ),

              Text(
                "₹${booking["final_freight"] ?? "0"}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              )
            ],
          ),

          const Divider()
        ],
      ),
    );
  }
}