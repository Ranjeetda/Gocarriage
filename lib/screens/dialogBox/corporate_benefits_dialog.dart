import 'package:flutter/material.dart';

class CorporateBenefitsDialog extends StatelessWidget {
  const CorporateBenefitsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CorporateBenefitsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.percent,
        'title': 'Maximum Discount',
        'subtitle': 'Exclusive rates & negotiated pricing on every shipment',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'title': 'Bulk Booking',
        'subtitle': 'Book multiple shipments at once with a single workflow',
      },
      {
        'icon': Icons.search,
        'title': 'Search Multiple Vehicles',
        'subtitle': 'Compare availability across an entire fleet simultaneously',
      },
      {
        'icon': Icons.person_outline,
        'title': 'Dedicated Relationship Manager',
        'subtitle': 'A named account manager available 24/7 for your business',
      },
      {
        'icon': Icons.smart_toy_outlined,
        'title': 'AI-Enabled Search & Booking',
        'subtitle': 'Smart recommendations and automated booking via AI',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Real-Time Tracking & Updates',
        'subtitle': 'Live GPS tracking with instant status notifications',
      },
      {
        'icon': Icons.trending_down,
        'title': 'Low Freight Costs',
        'subtitle': 'Reduced freight rates through volume-based agreements',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CORPORATE PLAN',
                        style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All Benefits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                ),
              ],
            ),
          ),

          // ── Benefits List ──
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              itemCount: benefits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = benefits[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Close Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}