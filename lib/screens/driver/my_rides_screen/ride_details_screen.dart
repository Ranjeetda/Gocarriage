import 'package:flutter/material.dart';
import '../../../resource/Utils.dart'; // for formatIsoDate if needed

class RideDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> rideData;

  const RideDetailsScreen({
    super.key,
    required this.rideData,
  });

  @override
  Widget build(BuildContext context) {
    // Extract common fields (works for both normal & past-order data)
    final bookingCode = rideData['bookingCode'] ??
        rideData['bookingRef'] ??
        rideData['_id'] ??
        'N/A';

    final status = (rideData['status'] ?? 'N/A').toString();
    final bookingMode = (rideData['bookingMode'] ?? 'N/A').toString();
    final vehicleType = (rideData['vehicleType'] ?? 'N/A').toString();
    final customerName = rideData['customerName'] ?? 'N/A';
    final customerPhone = rideData['customerPhone'] ?? 'N/A';

    final fromAddress =
        rideData['fromLocation']?['address']?.toString() ?? 'N/A';
    final toAddress =
        rideData['toLocation']?['address']?.toString() ?? 'N/A';

    final pickupDateRaw =
        rideData['pickupDate'] ?? rideData['bookingDate'] ?? rideData['createdAt'] ?? '';
    final pickupTime = rideData['pickupTime']?.toString() ?? '';
    final formattedPickup =
        '${Utils.formatIsoDate(pickupDateRaw.toString())}${pickupTime.isNotEmpty ? ' $pickupTime' : ''}';

    final weight = rideData['weight'] ?? rideData['weightKg'] ?? '';
    final weightUnit = rideData['weightUnit'] ?? '';
    final materialName = rideData['materialName'] ?? 'General';
    final price = rideData['price']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFD9E9FF),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        bookingCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: status.toUpperCase() == 'COMPLETED'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= EARNING / FARE DETAILS =================
              _sectionCard(
                title: 'YOUR EARNING DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Total Fare:', price == 'N/A' ? 'N/A' : '₹$price'),
                    _infoRow('Weight:', '$weight $weightUnit'),
                    _infoRow('Material:', materialName.toString()),
                    _infoRow('Booking Mode:', bookingMode),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle('PICKUP and DESTINATION'),

              // ================= PICKUP / DROP =================
              _pickupCard(
                pickupTime: formattedPickup,
                pickupAddress: fromAddress,
                dropTime: '—', // not available in current API
                dropAddress: toAddress,
                status: status,
              ),

              const SizedBox(height: 16),

              // ================= BASIC DETAILS =================
              _sectionCard(
                title: 'BASIC DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Booking Code:', bookingCode),
                    _infoRow('Status:', status),
                    _infoRow('Booking Mode:', bookingMode),
                    _infoRow('Vehicle Type:', vehicleType),
                    _infoRow('Customer:', customerName),
                    _infoRow('Phone:', customerPhone),
                    _infoRow('Material:', materialName.toString()),
                    _infoRow('Weight:', '$weight $weightUnit'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Optional swipe / action button (only if not completed)
              if (status.toUpperCase() != 'COMPLETED') _swipeButton(),

              const SizedBox(height: 16),

              // ================= CUSTOMER DETAILS =================
              _sectionCard(
                title: 'CUSTOMER DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Name:', customerName),
                    _infoRow('Phone:', customerPhone),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: open final invoice if available
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'View Final Invoice',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS (same as your original) =================

  Widget _pickupCard({
    required String pickupTime,
    required String pickupAddress,
    required String dropTime,
    required String dropAddress,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal, width: 2),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pickupRow('Pickup : $pickupTime', status),
                const SizedBox(height: 4),
                Text(pickupAddress,
                    style:
                    const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 14),
                Text('Drop : $dropTime',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(dropAddress,
                    style:
                    const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.location_on, size: 34, color: Colors.red),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15),
      ),
    );
  }

  Widget _swipeButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.double_arrow, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Swipe right to start ride',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _pickupRow(String text, String status) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
                fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _infoRow extends StatelessWidget {
  final String label;
  final String value;
  const _infoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}