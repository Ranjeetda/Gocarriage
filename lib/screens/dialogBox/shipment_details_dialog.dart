import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // optional for maps

class ShipmentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ShipmentDetailsDialog({super.key, required this.data});

  // Helper to open maps
  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String? iso, String? time) {
    try {
      final date = DateTime.parse(iso ?? '').toLocal();
      return '${DateFormat('dd MMM yyyy').format(date)}, ${time ?? ''}';
    } catch (_) {
      return time ?? '—';
    }
  }

  String _formatWeight(dynamic weight, String? unit) {
    final w = (weight is num) ? weight : 0;
    return '${NumberFormat('#,###').format(w)} ${unit ?? 'KG'}';
  }

  @override
  Widget build(BuildContext context) {
    final from = data['fromLocation'] ?? {};
    final to = data['toLocation'] ?? {};

    final fromAddress = from['address'] ?? '—';
    final toAddress = to['address'] ?? '—';
    final fare = (data['approx_fare'] as num?)?.toDouble() ?? 0.0;
    final distance = (data['approx_distance'] as num?)?.toDouble() ?? 0.0;
    final vehicleType = data['vehicleType'] ?? '—';
    final material = data['materialName'] ?? 'General';
    final bookingCode = data['bookingCode'] ?? '';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shipment Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D26),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bookingCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: [
                    // ── Pickup / Drop card ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          // Pickup
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C853),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 36,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PICKUP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      fromAddress,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1D26),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _openMaps(from['lat'], from['lng']),
                                icon: Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade500),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),

                          // Drop
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF9800),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DROP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      toAddress,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1D26),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _openMaps(to['lat'], to['lng']),
                                icon: Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade500),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Distance + time
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time, size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '~${(distance * 2.5).round()}m trip', // rough estimate
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Estimated Fare ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 2),
                              Text(
                                'ESTIMATED FARE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${NumberFormat('#,##0.00').format(fare)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D5C4A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── 2×2 Info Grid ──
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            icon: Icons.calendar_today_outlined,
                            label: 'PICKUP',
                            value: _formatDate(data['pickupDate'], data['pickupTime']),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoBox(
                            icon: Icons.local_shipping_outlined,
                            label: 'VEHICLE TYPE',
                            value: vehicleType,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            icon: Icons.inventory_2_outlined,
                            label: 'WEIGHT',
                            value: _formatWeight(data['weight'], data['weightUnit']),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoBox(
                            icon: Icons.category_outlined,
                            label: 'MATERIAL',
                            value: material,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Note
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fare shown is the customer-facing estimate for this route and vehicle type.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: navigate to Assign Vehicle screen
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: const Text(
                    'Assign a Vehicle',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7A5F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D26),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}