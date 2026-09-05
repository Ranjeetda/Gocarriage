import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common_btn.dart';

class LiveShipmentEmptyState extends StatelessWidget {
  final VoidCallback? onBookVehicle;

  const LiveShipmentEmptyState({
    super.key,
    this.onBookVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Shipment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No active shipment right now',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Using your CommonBtn
              CommonBtn(
                text: 'Book a Vehicle',
                onPressed: onBookVehicle,
                bgColor: const Color(0xFF4F46E5), // indigo/purple like the design
                textColor: Colors.white,
                height: 48,
                radius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}