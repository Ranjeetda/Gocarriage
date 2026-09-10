import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/instant_trip_request_list_provider.dart'; // adjust path
import '../../../resource/app_colors.dart';
import '../../dialogBox/accept_trip_bottom_sheet.dart';

class InstantTripRequestsScreen extends StatefulWidget {
  const InstantTripRequestsScreen({Key? key}) : super(key: key);

  @override
  State<InstantTripRequestsScreen> createState() => _InstantTripRequestsScreenState();
}

class _InstantTripRequestsScreenState extends State<InstantTripRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen opens
    Future.microtask(() {
      Provider.of<InstantTripRequestListProvider>(context, listen: false)
          .fetchInstantRequests();
    });
  }

  // Helper to shorten long addresses
  String _shortAddress(String? address) {
    if (address == null || address.isEmpty) return 'Unknown location';
    if (address.length <= 32) return address;
    return '${address.substring(0, 30)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Instant Trip Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<InstantTripRequestListProvider>(
            builder: (context, provider, _) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.openCount} Open',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<InstantTripRequestListProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return IconButton(
                onPressed: () => provider.fetchInstantRequests(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              );
            },
          ),
        ],
      ),
      body: Consumer<InstantTripRequestListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.openList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.openList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No open trip requests',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchInstantRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: provider.openList.length,
              itemBuilder: (context, index) {
                final item = provider.openList[index];
                return _buildTripCard(item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> item) {
    final vehicleType = item['vehicleType']?.toString() ?? '—';
    final bookingCode = item['bookingCode']?.toString() ?? '';
    final fromAddress = _shortAddress(item['fromLocation']?['address']);
    final toAddress = _shortAddress(item['toLocation']?['address']);
    final weight = item['weight']?.toString() ?? '0';
    final weightUnit = item['weightUnit']?.toString() ?? 'KG';
    final payout = item['approx_fare']?.toString() ?? '0';
    final isLive = item['status'] == 'SEARCHING';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, size: 16, color: Color(0xFF00C853)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bookingCode,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Route
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fromAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade400),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          toAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Payout + Weight
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹ YOUR PAYOUT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$payout',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A651),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'WEIGHT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$weight $weightUnit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    // TODO: Reject API
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 4),
                      Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final vehicles = [
                        {'number': 'DL12AB3519', 'capacity': '10000'},
                        {'number': 'DL21AB1200', 'capacity': '10000'},
                        {'number': 'DL02AB9231', 'capacity': '10000'},
                        {'number': 'DL87YU8787', 'capacity': '10000'},
                        {'number': 'DL89TY8979', 'capacity': '10000'},
                        {'number': 'DL78TY8978', 'capacity': '10000'},
                      ];
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (_, controller) {
                              return AcceptTripBottomSheet(
                                bookingCode: bookingCode ?? '',
                                payout: payout.toString(),
                                customerWantedDate: '25 Sept, 2:00 am', // parse from pickupDate
                                reachByTime: 'Reach by 1:45 am',
                                vehicles: vehicles,
                                onAccept: (selectedVehicle) {
                                  // Call your Accept API here
                                  print('Accepted with vehicle: $selectedVehicle');
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Accept Trip',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}