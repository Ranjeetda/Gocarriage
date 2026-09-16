import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider_service/bluk_order_list_provider.dart';

class BulkWaitingBottomSheet extends StatefulWidget {
  final String bulkId;
  final String headar;
  final VoidCallback? onViewDetails;
  final VoidCallback? onClose;

  const BulkWaitingBottomSheet({
    super.key,
    required this.bulkId,
    required this.headar,
    this.onViewDetails,
    this.onClose,
  });

  @override
  State<BulkWaitingBottomSheet> createState() => _BulkWaitingBottomSheetState();
}

class _BulkWaitingBottomSheetState extends State<BulkWaitingBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlukOrderListProvider>(
        context,
        listen: false,
      ).fetchBlukOrderList(widget.bulkId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlukOrderListProvider>(
      builder: (context, provider, _) {
        final raw = provider.listData;
        final bulkOrder = raw['bulkOrder'] as Map<String, dynamic>?;
        final bookings = (raw['bookings'] as List?)
            ?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

        final bulkCode =
            bulkOrder?['bulkOrderCode']?.toString() ?? widget.bulkId;

        final createdAt = bulkOrder?['createdAt'] != null
            ? DateTime.tryParse(bulkOrder!['createdAt'].toString())
            : null;
        final dateStr = createdAt != null
            ? DateFormat('dd MMM yyyy').format(createdAt.toLocal())
            : DateFormat('dd MMM yyyy').format(DateTime.now());

        final total = bookings.fold<double>(
          0,
              (sum, b) => sum + ((b['approx_fare'] as num?)?.toDouble() ?? 0),
        );

        final isLoading = provider.isLoading;
        final hasError = provider.errorMessage != null &&
            provider.errorMessage!.isNotEmpty;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFE85D04),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            widget.headar,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoading
                                ? 'Loading...'
                                : '${bookings.length} shipment(s) · $dateStr',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bulkCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Body
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE85D04),
                    ),
                  ),
                )
              else if (hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Provider.of<BlukOrderListProvider>(
                            context,
                            listen: false,
                          ).fetchBlukOrderList(widget.bulkId);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE85D04),
                        ),
                      ),
                    ],
                  ),
                )
              else if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No shipments found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ShipmentCard(
                          data: bookings[index],
                          index: index + 1,
                        );
                      },
                    ),
                  ),

              // Bottom summary + actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isLoading
                              ? 'Loading...'
                              : '${bookings.length} trips searching',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0.00').format(total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose ??
                                    () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B5563),
                              side:
                              const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                       /* const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: widget.onViewDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE85D04),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'View Bulk Order',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),*/
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _ShipmentCard({required this.data, required this.index});

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'SEARCHING':
        return 'Searching';
      case 'ASSIGNED':
        return 'Assigned';
      case 'IN_TRANSIT':
      case 'STARTED':
        return 'In Transit';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status ?? '—';
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'SEARCHING':
        return const Color(0xFFE85D04);
      case 'ASSIGNED':
        return const Color(0xFF2563EB);
      case 'IN_TRANSIT':
      case 'STARTED':
        return const Color(0xFF7C3AED);
      case 'COMPLETED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = data['fromLocation']?['address']?.toString() ?? '—';
    final to = data['toLocation']?['address']?.toString() ?? '—';
    final weight = data['weight']?.toString() ?? '0';
    final unit = data['weightUnit']?.toString() ?? 'KG';
    final price = (data['approx_fare'] as num?)?.toDouble() ?? 0.0;
    final bookingId = data['bookingCode']?.toString() ?? 'Shipment $index';
    final vehicleType = data['vehicleType']?.toString() ?? 'Vehicle';
    final status = data['status']?.toString();
    final statusColor = _statusColor(status);
    final isSearching = (status ?? '').toUpperCase() == 'SEARCHING';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking ID + status chip
          Row(
            children: [
              Expanded(
                child: Text(
                  bookingId,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSearching)
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: statusColor,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route (pickup → drop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE85D04),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 22,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weight · Vehicle · Price
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                '$weight $unit',
                style:
                const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.local_shipping_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vehicleType,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${NumberFormat('#,##0.00').format(price)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}