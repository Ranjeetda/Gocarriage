import 'package:flutter/material.dart';

import '../company_form_page.dart';

class CorporateServicesCard extends StatelessWidget {
  const CorporateServicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dark Header ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // deep navy
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316), // orange
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded, // or Icons.business
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Corporate Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Unlock exclusive business benefits with a verified corporate account',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Benefits List ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: const [
                  _BenefitItem(text: 'Priority booking & dedicated support'),
                  SizedBox(height: 16),
                  _BenefitItem(text: 'Consolidated monthly GST billing'),
                  SizedBox(height: 16),
                  _BenefitItem(text: 'Business analytics & reporting'),
                  SizedBox(height: 16),
                  _BenefitItem(text: 'Dedicated account manager'),
                ],
              ),
            ),

            // ── CTA Button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CompanyFormPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C), // deep orange
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Apply for Corporate Account',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;

  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7), // light green
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Color(0xFF16A34A), // green
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}