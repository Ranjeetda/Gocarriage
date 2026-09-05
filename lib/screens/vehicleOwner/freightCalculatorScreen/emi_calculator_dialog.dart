import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/FreightEmiPreviewProvider.dart';
import '../../../provider_service/freight_emi_default_provider.dart';


class EmiCalculatorDialog extends StatefulWidget {
  final String initialOnRoadPrice;

  const EmiCalculatorDialog({
    super.key,
    this.initialOnRoadPrice = '0',
  });

  @override
  State<EmiCalculatorDialog> createState() => _EmiCalculatorDialogState();
}

class _EmiCalculatorDialogState extends State<EmiCalculatorDialog> {
  final _onRoadCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController(text: '0');
  final _interestCtrl = TextEditingController(text: '0');
  final _tenureCtrl = TextEditingController(text: '0');

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
     _onRoadCtrl.text=widget.initialOnRoadPrice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FreightEmiDefaultProvider>(
        context,
        listen: false,
      ).fetchEmiDefault();
    });
    // Listen to all fields
    for (final c in [_onRoadCtrl, _downPaymentCtrl, _interestCtrl, _tenureCtrl]) {
      c.addListener(_onAnyFieldChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _onRoadCtrl.dispose();
    _downPaymentCtrl.dispose();
    _interestCtrl.dispose();
    _tenureCtrl.dispose();
    super.dispose();
  }

  void _onAnyFieldChanged() {
    // Debounce so we don't spam the API while typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final provider = context.read<FreightEmiPreviewProvider>();
      provider.fetchEmiPreview(
        onRoadPrice: _onRoadCtrl.text.trim(),
        downPaymentPercent: _downPaymentCtrl.text.trim().isEmpty
            ? '0'
            : _downPaymentCtrl.text.trim(),
        interestRatePercent: _interestCtrl.text.trim().isEmpty
            ? '0'
            : _interestCtrl.text.trim(),
        tenureMonths:
        _tenureCtrl.text.trim().isEmpty ? '0' : _tenureCtrl.text.trim(),
      );
    });
  }

  String _formatAmount(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(value % 100000 == 0 ? 0 : 1)}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FreightEmiPreviewProvider>();
    final providerDefault = context.watch<FreightEmiDefaultProvider>();

    _downPaymentCtrl.text=providerDefault.downPaymentPercent.toString();
    _interestCtrl.text=providerDefault.interestRatePercent.toString();
    _tenureCtrl.text=providerDefault.tenureMonths.toString();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMI Calculator',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drives the Vehicle EMI Per Day row',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── On-road Price ───────────────────────────────────────
                const _SectionLabel(label: 'On-road price', isRequired: true),
                const SizedBox(height: 10),
                _StyledTextField(
                  controller: _onRoadCtrl,
                  prefixText: '₹ ',
                  hintText: '0',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 22),

                // ── Three inputs ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactField(
                        label: 'Down payment',
                        suffix: '%',
                        controller: _downPaymentCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactField(
                        label: 'Interest rate',
                        suffix: '%',
                        controller: _interestCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactField(
                        label: 'Tenure',
                        suffix: 'mo',
                        controller: _tenureCtrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Result Card ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0F7FF), Color(0xFFE8F1FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                    height: 70,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                      : provider.error != null
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          title: 'FINANCED',
                          value: _formatAmount(provider.financedAmount),
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _SummaryTile(
                          title: 'EMI / MONTH',
                          value: _formatAmount(provider.emiPerMonth),
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _SummaryTile(
                          title: 'EMI / DAY',
                          value: _formatAmount(provider.emiPerDay),
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Formula hint ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'EMI/month = P × i × (1+i)ⁿ / ((1+i)ⁿ − 1)\n'
                        'EMI/day   = EMI/month ÷ 30',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.55,
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Actions ─────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ||
                            provider.emiDefaultData == null
                            ? null
                            : () {
                          // Return the calculated values to the caller
                          Navigator.pop(context, {
                            'financed_amount': provider.financedAmount,
                            'emi_per_month': provider.emiPerMonth,
                            'emi_per_day': provider.emiPerDay,
                            'on_road_price': _onRoadCtrl.text,
                            'down_payment_percent': _downPaymentCtrl.text,
                            'interest_rate_percent': _interestCtrl.text,
                            'tenure_months': _tenureCtrl.text,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF2563EB).withValues(alpha: 0.45),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Apply EMI',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactField({
    required String label,
    required String suffix,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: controller,
          suffixText: suffix,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Reusable pieces (same as before, just added controller support) ────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _SectionLabel({
    required this.label,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF334155),
            letterSpacing: -0.2,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? prefixText;
  final String? suffixText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextAlign textAlign;

  const _StyledTextField({
    this.controller,
    this.prefixText,
    this.suffixText,
    this.hintText,
    this.keyboardType,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        prefixText: prefixText,
        suffixText: suffixText,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFF3B82F6), width: 1.8),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _SummaryTile({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: highlight
                ? const Color(0xFF2563EB)
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: highlight
                ? const Color(0xFF2563EB)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFBFDBFE),
    );
  }
}