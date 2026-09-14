import 'package:flutter/cupertino.dart';

class AdvancePaymentInfoBanner extends StatelessWidget {
  final String message;

  const AdvancePaymentInfoBanner({
    super.key,
    this.message =
    "A 10% advance payment is required to confirm a scheduled within-city booking.",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF5E6C8),
          width: 1,
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}