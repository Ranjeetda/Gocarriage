import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../provider_service/negotiations_list_provider.dart'; // ← change path if needed
import '../../../resource/app_colors.dart';
import '../../dialogBox/respond_to_booking_sheet.dart';

class NegotiationsScreen extends StatefulWidget {
  const NegotiationsScreen({Key? key}) : super(key: key);

  @override
  State<NegotiationsScreen> createState() => _NegotiationsScreenState();
}

class _NegotiationsScreenState extends State<NegotiationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NegotiationsListProvider>(context, listen: false)
          .fetchNegotiationsList();

      Provider.of<NegotiationsListProvider>(context, listen: false)
          .fetchNegotiationsOpenList();
    });
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getTimeLeft(String? expiresAt) {
    if (expiresAt == null) return '';
    try {
      final expiry = DateTime.parse(expiresAt).toLocal();
      final now = DateTime.now();
      final diff = expiry.difference(now);

      if (diff.isNegative) return 'Expired';

      final totalMinutes = diff.inMinutes;
      final seconds = diff.inSeconds.remainder(60);
      return '${totalMinutes}m ${seconds}s left';
    } catch (e) {
      return '';
    }
  }

  String _buildConfirmedMessage(Map<String, dynamic> item) {
    final vehicle = item['assignedVehicleNumber'] ?? '—';
    final time = item['pickupTime'] ?? '';
    return 'Please send the driver and vehicle ($vehicle) before $time.';
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
          'Negotiations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<NegotiationsListProvider>(
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
          Consumer<NegotiationsListProvider>(
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
                onPressed: () => provider.fetchNegotiationsList(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              );
            },
          ),
        ],
      ),
      body: Consumer<NegotiationsListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.listData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final confirmed = provider.confirmedList;
          final open = provider.openList;

          if (confirmed.isEmpty && open.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No negotiations found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNegotiationsList(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // ===================== CONFIRMED =====================
                if (confirmed.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'CONFIRMED',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...confirmed.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ConfirmedCard(
                        bookingId: item['bookingCode'] ?? '—',
                        message: _buildConfirmedMessage(item),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],

                // ===================== OPEN NEGOTIATIONS =====================
                ...open.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ActiveNegotiationCard(
                      myLatestOffer: item['myLatestOffer']==null?true:false,
                      bookingId: item['bookingCode'] ?? '—',
                      yourOffer: item['myLatestOffer']==null?"--":item['myLatestOffer']['price'].toString(),
                      timeLeft: _getTimeLeft(item['negotiationExpiresAt']),
                      amount: _formatCurrency(item['customerOfferPrice']),
                      onAcceptCounter: () {
                        showRespondToBooking(context,item['vehicleTypeId'].toString());
                      },
                      onReject: () {
                        // TODO: reject logic
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

void showRespondToBooking(BuildContext context,  String vehiclesId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, __) {
          return RespondToBookingSheet(
            bookingCode: 'BK_63000b22-42d3-43bb-a6f4-a4a0a8c6e245',
            customerOffer: '120795',
            customerWantedDate: '24 Sept, 6:00 am',
            reachByTime: 'Reach by 5:45 am',
            vehiclesId: vehiclesId,
            onAccept: (vehicle) {
              print('Accepted with $vehicle');
              // Call Accept API
            },
            onCounterOffer: (vehicle, price) {
              print('Counter offer $price with $vehicle');
              // Call Counter Offer API
            },
          );
        },
      );
    },
  );
}

// ============================================================
// CONFIRMED CARD
// ============================================================
class _ConfirmedCard extends StatelessWidget {
  final String bookingId;
  final String message;

  const _ConfirmedCard({
    required this.bookingId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8EBD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookingId,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVE NEGOTIATION CARD (amount section fixed)
// ============================================================
class _ActiveNegotiationCard extends StatelessWidget {
  final bool myLatestOffer;
  final String bookingId;
  final String yourOffer;
  final String timeLeft;
  final String amount;
  final VoidCallback? onAcceptCounter;
  final VoidCallback? onReject;

  const _ActiveNegotiationCard({
    required this.myLatestOffer,
    required this.bookingId,
    required this.yourOffer,
    required this.timeLeft,
    required this.amount,
    this.onAcceptCounter,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== TOP SECTION ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handshake icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    size: 20,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),

                // Booking ID + Timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingId,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            timeLeft,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Customer Offer badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB8E6D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Customer Offer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ========== AMOUNT SECTION ==========
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹ ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "CUSTOMER'S OFFER",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ========== BUTTONS ==========
          myLatestOffer?Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAcceptCounter,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Accept / Counter',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ):Center(child: Text('You offered ₹${yourOffer}. Waiting on the customer to accept.'),),
        ],
      ),
    );
  }
}