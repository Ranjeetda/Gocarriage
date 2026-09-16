import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider_service/past_order_list_provider.dart';
import '../dialogBox/bulk_waiting_bottom_sheet.dart';


class BulkOrdersScreen extends StatefulWidget {
  const BulkOrdersScreen({super.key});

  @override
  State<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends State<BulkOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PastOrderListProvider>(
        context,
        listen: false,
      ).fetchBlukOrderList();
    });
  }

  int _completedCount(Map<String, dynamic> order) {
    final counts = order['statusCounts'] as Map<String, dynamic>? ?? {};
    // Treat COMPLETED + ACCEPTED as done (adjust if needed)
    final completed = (counts['COMPLETED'] as num?)?.toInt() ?? 0;
    final accepted = (counts['ACCEPTED'] as num?)?.toInt() ?? 0;
    return completed + accepted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Bulk Orders',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'All your batch shipment orders.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PastOrderListProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE85D04),
                      ),
                    );
                  }

                  if (provider.errorMessage != null &&
                      provider.errorMessage!.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              provider.fetchBlukOrderList();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = provider.listData;

                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No bulk orders yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFE85D04),
                    onRefresh: () => provider.fetchBlukOrderList(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final bulkCode =
                            order['bulkOrderCode']?.toString() ?? '—';
                        final rowCount =
                            (order['rowCount'] as num?)?.toInt() ?? 0;
                        final completed = _completedCount(order);
                        final createdAt =
                            order['createdAt']?.toString() ?? '';

                        return _BulkOrderCard(
                          bulkCode: bulkCode,
                          rowCount: rowCount,
                          completedCount: completed,
                          createdAt: createdAt,
                          onTap: () {
                            final bulkId = order['id'];
                            showBulkWaitingSheet(bulkOrderId: bulkId,);

                          },
                        );
                      },
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
  void showBulkWaitingSheet({
    required String bulkOrderId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return BulkWaitingBottomSheet(
            bulkId: bulkOrderId, // e.g. "BULK_12fb2908-..."
            headar: 'Bulk Order',
            onClose: () => Navigator.pop(context),
            onViewDetails: () {
              Navigator.pop(context);
              // Navigate to bulk order detail screen
            },
          );
        },
      ),
    );
  }
}

class _BulkOrderCard extends StatelessWidget {
  final String bulkCode;
  final int rowCount;
  final int completedCount;
  final String createdAt;
  final VoidCallback? onTap;

  const _BulkOrderCard({
    required this.bulkCode,
    required this.rowCount,
    required this.completedCount,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(createdAt);
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy').format(date.toLocal())
        : '—';

    final isComplete = completedCount >= rowCount && rowCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bulkCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$rowCount shipment(s) · $dateStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completedCount of $rowCount completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isComplete
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}