import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NegotiationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const NegotiationDetailScreen({Key? key, required this.item})
      : super(key: key);

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    return NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final customerOffer = item['customerOfferPrice'];
    final myOffer = item['myLatestOffer']?['price'];
    final bookingId = item['bookingCode'] ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Negotiation',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                SizedBox(width: 5),
                Text(
                  'Customer Offer',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookingId,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${item['pickupCity'] ?? 'Delhi'} → ${item['dropCity'] ?? 'Uttar Pradesh'}',
                  style:
                  TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Offer Summary
            _SectionCard(
              title: 'Offer Summary',
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CUSTOMER'S OFFER",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(customerOffer),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Vehicle',
                      item['vehicleType']?.toString() ?? '10000'),
                  _infoRow(
                      'Reach by', item['reachBy'] ?? '24 Sept, 5:45 am'),
                  _infoRow(
                      'Pickup', item['pickupTime'] ?? '24 Sept, 6:00 am'),
                  _infoRow('Trip type', item['tripType'] ?? 'Scheduled'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Request Details
            _SectionCard(
              title: 'Request Details',
              child: Column(
                children: [
                  _infoRow('Booking ID', bookingId),
                  _infoRow(
                      'Route',
                      '${item['pickupCity'] ?? 'Delhi'} → ${item['dropCity'] ?? 'Uttar Pradesh'}'),
                  _infoRow('Vehicle Type',
                      item['vehicleType']?.toString() ?? '10000'),
                  _infoRow('Pickup Time',
                      item['pickupTime'] ?? '24 Sept, 6:00 am'),
                  _infoRow(
                    'Negotiation Range',
                    '${_formatCurrency(customerOffer)} – ${_formatCurrency(item['maxPrice'] ?? 147638)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Your Next Step
            _SectionCard(
              title: 'Your Next Step',
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 48, color: Color(0xFF059669)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    myOffer != null
                        ? 'You offered ${_formatCurrency(myOffer)}. Waiting on the customer.'
                        : 'Review the offer and respond to proceed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Assignment
            _SectionCard(
              title: 'Assignment',
              titleColor: const Color(0xFFDC2626),
              subtitle:
              'Assign both a vehicle and a driver to move this request to Accepted.',
              child: Column(
                children: [
                  _dropdownField('ASSIGN VEHICLE *', 'Select vehicle'),
                  const SizedBox(height: 12),
                  _dropdownField('ASSIGN DRIVER *', 'Select driver'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Available once the price is confirmed — settle it above first.',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timeline
            _SectionCard(
              title: 'Negotiation Timeline',
              child: Column(
                children: [
                  _timelineItem(
                    icon: Icons.shield_outlined,
                    title: "Customer's offer received",
                    subtitle: _formatCurrency(customerOffer),
                    isDone: true,
                  ),
                  _timelineItem(
                    icon: Icons.currency_rupee,
                    title: 'Your counter offer',
                    subtitle: myOffer != null
                        ? '${_formatCurrency(myOffer)}\n2:07 pm'
                        : '—',
                    isDone: myOffer != null,
                  ),
                  _timelineItem(
                    icon: Icons.bolt,
                    title: 'Active negotiation',
                    subtitle: 'Waiting for your action\nexpires 12:00 am',
                    isDone: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: myOffer == null
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Accept / Counter',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(hint,
                  style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 16,
                  color: isDone ? const Color(0xFF059669) : Colors.grey),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: titleColor ?? const Color(0xFF111827),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.3)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}