import 'package:flutter/material.dart';

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFD9E9FF),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '#145625983478',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Assigned',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ride 2 Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
              const SizedBox(height: 10),

              // EARNING DETAILS CARD
              _sectionCard(
                title: 'YOUR EARNING DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _infoRow('Total Fare:', '₹1500/-'),
                    _infoRow('Total Distance:', '55 Km'),
                    _infoRow('Cabsy fee:', '₹200/-'),
                    _infoRow('Your earning:', '₹1300/-'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle('PICKUP and DESTINATION'),
              _pickupCard(
                pickupTime: '3 August 2025 07:30 AM',
                pickupAddress:
                'Somwarpet, Survey Layout\nChota Taj Bagh, Nagpur',
                dropTime: '3 August 2025 10:30 AM',
                dropAddress: 'Itwari Railway Station,\nItwari, Nagpur, India',
                status: 'Started',
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'BASIC DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _infoRow('Trip ID:', '#14887851254'),
                    _infoRow('Trip Type:', 'Oneway'),
                    _infoRow('Trip Distance:', '89.36 km'),
                    _infoRow('Trip Duration:', '3h 00min'),
                    _infoRow('Vehicle Type:', 'Automatic - Sedan'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _swipeButton(),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'EARNING DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _infoRow('Trip ID:', '#14887851254'),
                    _infoRow('Trip Type:', 'Oneway'),
                    _infoRow('Trip Distance:', '89.36 km'),
                    _infoRow('Trip Duration:', '3h 00min'),
                    _infoRow('Vehicle Type:', 'Automatic - Sedan'),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.keyboard_arrow_up),
                  label: const Text(
                    'View Complete Ride Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ride 1 Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),

              const SizedBox(height: 10),
              _pickupCard(
                pickupTime: '3 August 2025 07:30 AM',
                pickupAddress:
                'Somwarpet, Survey Layout\nChota Taj Bagh, Nagpur',
                dropTime: '3 August 2025 10:30 AM',
                dropAddress: 'Itwari Railway Station,\nItwari, Nagpur, India',
                status: 'Completed',
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'BASIC DETAILS',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _infoRow('Trip ID:', '#14887851254'),
                    _infoRow('Trip Type:', 'Oneway'),
                    _infoRow('Trip Distance:', '89.36 km'),
                    _infoRow('Trip Duration:', '3h 00min'),
                    _infoRow('Vehicle Type:', 'Automatic - Sedan'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text(
                    'View Final Invoice',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _termsAndConditions(),
            ],
          ),
        ),
      ),
    );
  }

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
          // Timeline
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
                height: 30,
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
                _pickupRow('Pickup Time : $pickupTime', status),
                Text(pickupAddress,
                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 12),
                Text('Drop Time : $dropTime',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600)),
                Text(dropAddress,
                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _termsAndConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Terms & Conditions (नियम और नियम)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '• ₹500 fine will apply if the trip is cancelled after 30 minutes of booking.\n'
                '• Waiting time beyond 15 minutes will be charged at ₹100 per 15 mins.\n'
                '• Toll, parking, and interstate charges (if any) are not included.\n'
                '• Driver may cancel the ride if unreachable for more than 10 minutes.\n'
                '• Total fare may vary based on actual kilometers traveled.\n'
                '• No-show by customer will result in full booking amount being charged.\n\n'
                'नियम और शर्तें\n'
                '• अगर आप बुकिंग के 30 मिनट बाद यात्रा रद्द करते हैं, तो ₹500 का जुर्माना लगेगा।\n'
                '• 15 मिनट से ज़्यादा इंतजार करने पर ₹100 प्रति 15 मिनट के हिसाब से चार्ज लिया जाएगा।\n'
                '• टोल, पार्किंग और राज्य सीमा शुल्क (अगर हैं) के लिए शामिल नहीं हैं।\n'
                '• अगर ड्राइवर से 10 मिनट तक संपर्क नहीं हो पाया, तो ड्राइवर यात्रा रद्द कर सकता है।\n'
                '• कुल किराया यात्रा की वास्तविक दूरी के आधार पर बदल सकता है।\n'
                '• यदि ग्राहक यात्रा पर नहीं आता है (No-show), तो पूरी बुकिंग राशि चार्ज की जाएगी।',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ],
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
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
