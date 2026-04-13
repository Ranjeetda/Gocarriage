import 'package:flutter/material.dart';
import 'package:gocarriage_universal/ui/operatorScreen/quick_booking_screen.dart';
import 'package:provider/provider.dart';

import '../../provider_service/operator_vechile_booking.dart';
import '../../resource/app_colors.dart';

class OperatorBooingScreen extends StatefulWidget {
  const OperatorBooingScreen({Key? key}) : super(key: key);

  @override
  State<OperatorBooingScreen> createState() => _OperatorBooingScreenState();
}

class _OperatorBooingScreenState extends State<OperatorBooingScreen> {

  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  List tabs = [
    "All",
    "Draft",
    "Pending",
    "Confirmed",
    "Active",
    "Completed",
    "Cancelled"
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final provider =
      Provider.of<OperatorVechileBooking>(context, listen: false);

      provider.fetchVehicleRequest();

      _scrollController.addListener(() {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {

          provider.fetchVehicleRequest(loadMore: true);

        }
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F8),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuickBookingScreen()),
          );
        },
      ),
      body: SafeArea(
        child: Consumer<OperatorVechileBooking>(
          builder: (context, providerData, child) {
            if (providerData.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allRequests = providerData.vehicleRequestList;

            /// COUNTS
            int totalCount = allRequests.length;

            int draftCount =
                allRequests
                    .where(
                      (e) => e['status'].toString().toLowerCase() == "draft",
                )
                    .length;



            int pendingCount =
                allRequests
                    .where(
                      (e) => e['status'].toString().toLowerCase() == "pending",
                )
                    .length;

            int confirmedCount =
                allRequests
                    .where(
                      (e) =>
                  e['status'].toString().toLowerCase() == "confirmed",
                )
                    .length;

            int activeCount =
                allRequests
                    .where(
                      (e) => e['status'].toString().toLowerCase() == "active",
                )
                    .length;

            int completeCount =
                allRequests
                    .where(
                      (e) => e['status'].toString().toLowerCase() == "complete",
                )
                    .length;

            int cancelCount =
                allRequests
                    .where(
                      (e) => e['status'].toString().toLowerCase() == "cancel",
                )
                    .length;

            List counts = [
              totalCount,
              draftCount,
              pendingCount,
              confirmedCount,
              activeCount,
              completeCount,
              cancelCount,
            ];

            /// FILTER LIST
            List filteredList = [];

            if (selectedIndex == 0) {
              filteredList = allRequests;
            } else if (selectedIndex == 1) {
              filteredList =
                  allRequests
                      .where(
                        (e) => e['status'].toString().toLowerCase() == "draft",
                  )
                      .toList();
            } else if (selectedIndex == 2) {
              filteredList =
                  allRequests
                      .where(
                        (e) =>
                    e['status'].toString().toLowerCase() == "pending",
                  )
                      .toList();
            } else if (selectedIndex == 3) {
              filteredList =
                  allRequests
                      .where(
                        (e) =>
                    e['status'].toString().toLowerCase() == "confirmed",
                  )
                      .toList();
            } else if (selectedIndex == 4) {
              filteredList =
                  allRequests
                      .where(
                        (e) => e['status'].toString().toLowerCase() == "active",
                  )
                      .toList();
            } else if (selectedIndex == 5) {
              filteredList =
                  allRequests
                      .where(
                        (e) =>
                    e['status'].toString().toLowerCase() == "complete",
                  )
                      .toList();
            } else if (selectedIndex == 6) {
              filteredList =
                  allRequests
                      .where(
                        (e) => e['status'].toString().toLowerCase() == "cancel",
                  )
                      .toList();
            }

            return Column(
              children: [
                /// TAB BAR
                Container(
                  height: 55,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xffC8E6C9)),
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
                              isSelected
                                  ? const Color(0xff4CAF50)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  tabs[index],
                                  style: TextStyle(
                                    color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    counts[index].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                      isSelected
                                          ? const Color(0xff4CAF50)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
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
                  child:
                  filteredList.isEmpty
                      ? const Center(
                    child: Text(
                      'No Vehicle permission requests available.',
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return bookingCard(filteredList[index]);
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

  Widget bookingCard(final vehicleData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// STATUS + REF
          statusChip(vehicleData['status'],vehicleData['booking_ref']),

          const SizedBox(height: 10),

          /// ROUTE
          Text(
            "${vehicleData['from_location']?.split(',').first} → ${vehicleData['to_location']?.split(',').first}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          /// TAGS
          Row(
            children: [
              tag(vehicleData['VehicleType']['name']),
              const SizedBox(width: 8),
              tag(vehicleData['material_type']??'--'),
              //const SizedBox(width: 8),
              //tag("21 Mar 2026"),
            ],
          ),

          const SizedBox(height: 14),

          /// BOTTOM ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  [
                  Text(vehicleData['customer_name']??''),
                  Text(vehicleData['customer_phone'],
                      style: TextStyle(color: Colors.grey)),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:  [
                  Text("₹${vehicleData['total_freight']}",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text("Advance: ₹${vehicleData['total_advance']}",
                      style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget statusChip(String status,String bookingRef) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {

      case "draft":
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.edit;
        break;

      case "pending":
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        icon = Icons.hourglass_empty;
        break;

      case "confirmed":
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;

      case "active":
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.local_shipping;
        break;

      case "completed":
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        icon = Icons.task_alt;
        break;

      case "cancelled":
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;

      default:
        bgColor = const Color(0xffFDF6EC);
        textColor = const Color(0xffD97706);
        icon = Icons.access_time;
    }

    return Row(
      children: [

        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children:  [
              Icon(icon, size: 14, color: Colors.green),
              SizedBox(width: 5),
              Text(
                (status ?? '').toString().isNotEmpty
                    ? (status ?? '').toString()[0].toUpperCase() +
                    (status ?? '').toString().substring(1)
                    : '',
                style:  TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Text(
          (bookingRef ?? '').toString().isNotEmpty
              ? (bookingRef ?? '').toString()[0].toUpperCase() +
              (bookingRef ?? '').toString().substring(1)
              : '',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

}