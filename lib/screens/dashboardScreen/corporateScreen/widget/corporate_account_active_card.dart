import 'package:flutter/material.dart';

class CorporateAccountActiveCard extends StatefulWidget {
  Map<String, dynamic> profileData;
  CorporateAccountActiveCard(this.profileData);

  @override
  State<CorporateAccountActiveCard> createState() => _CorporateAccountActiveCard();
}
class _CorporateAccountActiveCard extends State<CorporateAccountActiveCard> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD1FAE5), // soft green border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Soft Green Header ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              color: const Color(0xFFECFDF5), // very light green
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded, // or Icons.verified
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Texts
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corporate Account Active',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46), // dark green
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Verified business customer',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF10B981), // medium green
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Details ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children:  [
                  _InfoRow(label: 'Company', value: widget.profileData['customerType']),
                  SizedBox(height: 14),
                  _InfoRow(label: 'Type', value: 'Private Limited'),
                  SizedBox(height: 14),
                  _InfoRow(label: 'GST No.', value: widget.profileData['gstNumber']),
                  SizedBox(height: 14),
                  _InfoRow(label: 'Email', value: widget.profileData['user']['email']),
                  SizedBox(height: 14),
                  _InfoRow(label: 'City', value: widget.profileData['city']),
                  SizedBox(height: 14),
                  _InfoRow(label: 'Address', value: widget.profileData['address']),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 24,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            ),

            // ── GST Certificate Row ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text(
                      'GST Cert',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: open certificate
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View Certificate',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}