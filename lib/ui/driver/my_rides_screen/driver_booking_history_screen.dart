import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/driver_booking_history_full_provider.dart';
import '../../../provider_service/driver_booking_history_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/ClickableDiagonalPill.dart';
import 'ride_details_screen.dart';

class DriverBookingHistoryScreen extends StatefulWidget {
  const DriverBookingHistoryScreen({super.key});

  @override
  State<DriverBookingHistoryScreen> createState() =>
      _DriverBookingHistoryScreenState();
}

class _DriverBookingHistoryScreenState
    extends State<DriverBookingHistoryScreen> {

  int selectedIndex = 0; // 0 = Customer, 1 = Operator

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<DriverBookingHistoryProvider>(context, listen: false)
          .fetchBooking();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<DriverBookingHistoryFullProvider>(context, listen: false)
          .fetchBooking();
    });
  }

  // ================= SEGMENTED TAB =================
  Widget buildSegmentedTab(int customerCount, int operatorCount) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          buildTabItem("Customer ($customerCount)", 0),
          buildTabItem("Operator ($operatorCount)", 1),
        ],
      ),
    );
  }

  Widget buildTabItem(String title, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget buildRideCard(Map<String, dynamic> ride) {
    return InkWell(
      onTap: () {
       /* Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideDetailsScreen(rideData: ride),
          ),
        );*/
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Utils.formatIsoDate(ride["bookingDate"] ?? ""),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride["bookingRef"] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 140,
                  height: 34,
                  child: ClickableDiagonalPill(
                    options: [
                      ride['bookingMode'] ?? "",
                      ride['status'] ?? "",
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// PICKUP DROP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    SizedBox(height: 4),
                    SizedBox(
                      height: 30,
                      child: VerticalDivider(thickness: 1),
                    ),
                    SizedBox(height: 4),
                    Icon(Icons.location_on, color: Colors.red, size: 18),
                  ],
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride["fromLocation"]?["address"] ?? ""),
                      const SizedBox(height: 8),
                      Text(ride["toLocation"]?["address"] ?? ""),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// DETAILS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, size: 18),
                    const SizedBox(width: 6),
                    Text(ride["vehicleType"] ?? ""),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.scale, size: 18),
                    const SizedBox(width: 6),
                    Text("${ride["weightKg"] ?? ""} ${ride["weightUnit"] ?? ""}"),
                  ],
                ),
                Text(
                  ride["price"]?.toString() ?? "N/A",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// CUSTOMER
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(ride["customerName"] ?? "")),
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 4),
                Text(ride["customerPhone"] ?? ""),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIST =================
  Widget buildList(List rides) {
    if (rides.isEmpty) {
      return const Center(child: Text("No bookings found"));
    }

    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) =>
          buildRideCard(rides[index]),
    );
  }

  // ================= MAIN =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DriverBookingHistoryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final rides = provider.bookingData;

            final customerRides =
            rides.where((e) => e["source"] == "customer").toList();

            final operatorRides =
            rides.where((e) => e["source"] == "operator").toList();

            return Column(
              children: [
                buildSegmentedTab(
                  customerRides.length,
                  operatorRides.length,
                ),

                Expanded(
                  child: selectedIndex == 0
                      ? buildList(customerRides)
                      : buildList(operatorRides),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}