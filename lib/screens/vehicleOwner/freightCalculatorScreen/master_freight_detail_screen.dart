import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/screens/vehicleOwner/freightCalculatorScreen/trip_cost_preview_screen.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/FreightComponentViewProvider.dart';
import '../../../provider_service/master_freight_post_provider.dart';
import '../../../resource/Utils.dart';
import '../../widgets/rate_card.dart';

class MasterFreightDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? item;

  const MasterFreightDetailScreen(this.item, {super.key});

  @override
  State<MasterFreightDetailScreen> createState() =>
      _MasterFreightDetailScreenState();
}

class _MasterFreightDetailScreenState extends State<MasterFreightDetailScreen> {
  // Controllers for editable rates
  final Map<String, TextEditingController> _rateControllers = {};
  // Whether the operator can edit that component
  final Map<String, bool> _componentEditable = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Freightcomponentviewprovider>(
        context,
        listen: false,
      ).fetchFreightComponent("/${widget.item?['id']}");
    });
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Master Freight',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripCostPreviewScreen(widget.item?['id'],'master'),
                  ),
                );
              },
              icon: const Icon(Icons.route_outlined, size: 18),
              label: const Text('Trip Cost'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vehicle Summary Card ─────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item?['model_name']?.toString() ?? '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item?['brand']?.toString() ?? '—',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _InfoChip(
                        label: 'EMI/day',
                        value: '₹${Utils.format(widget.item?['emi_per_day'])}',
                        isPrimary: false,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: 'Admin base/day',
                        value:
                        '₹${Utils.format(widget.item?['base_fixed_per_day'])}',
                        isPrimary: false,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: 'Your base/day',
                        value:
                        '₹${Utils.format(widget.item?['base_fixed_per_day'])}',
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Base pay rate-card ───────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Base pay rate-card',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Recomputed on every save · provisional',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: RateCard(
                        title: 'FIXED / DAY',
                        value:
                        '₹${Utils.format(widget.item?['base_fixed_per_day'])}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RateCard(
                        title: 'PER KM',
                        value: '₹${Utils.format(widget.item?['base_per_km'])}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RateCard(
                        title: 'PER TON',
                        value: '₹${Utils.format(widget.item?['base_per_ton'])}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RateCard(
                        title: 'FLAT / TRIP',
                        value:
                        '₹${Utils.format(widget.item?['base_flat_per_trip'])}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Cost Components Card ─────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cost components',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '14 rows · 13 operator-editable',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Manage template'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('COMPONENT', style: _headerStyle),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('UNIT', style: _headerStyle),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('ADMIN RATE', style: _headerStyle),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'YOUR RATE',
                          style: _headerStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rows
                Consumer<Freightcomponentviewprovider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (provider.componentsList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text("No components found")),
                      );
                    }

                    // Initialise controllers only once
                    if (_rateControllers.isEmpty) {
                      for (final item in provider.componentsList) {
                        final id = item['id']?.toString() ??
                            item['component_master_id']?.toString() ??
                            '';

                        final initialRate = item['default_rate']?.toString() ??
                            item['operator_rate']?.toString() ??
                            '0';

                        _rateControllers[id] = TextEditingController(
                          text: Utils.formatRate(initialRate),
                        );

                        _componentEditable[id] = (item['is_operator_editable'] == 1 || item['is_operator_editable'] == true);
                      }
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.componentsList.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = provider.componentsList[index];
                        final String id = item['id']?.toString() ??
                            item['component_master_id']?.toString() ??
                            '';
                        final String name = item['name']?.toString() ?? '';
                        final String unit = item['rate_unit']?.toString() ?? '';
                        final bool isEditable = _componentEditable[id] ?? false;

                        // Admin rate
                        String adminRate =
                            item['admin_rate']?.toString() ?? '0';
                        if (index == 0 && widget.item != null) {
                          adminRate = widget.item?['emi_per_day']?.toString() ??
                              adminRate;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // COMPONENT
                              Expanded(
                                flex: 4,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),

                              // UNIT
                              Expanded(
                                flex: 2,
                                child: Text(
                                  unit.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // ADMIN RATE
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: index == 0
                                      ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'EMI ₹${Utils.formatRate(adminRate)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                      : Text(
                                    '₹${Utils.formatRate(adminRate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),

                              // YOUR RATE
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: isEditable
                                      ? SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: _rateControllers[id],
                                      keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'fixed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),

      // ── Bottom action bar ───────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Consumer<MasterFreightPostProvider>(
          builder: (context, provider, _) {
            return ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                final componentProvider =
                Provider.of<Freightcomponentviewprovider>(
                  context,
                  listen: false,
                );

                final List<Map<String, dynamic>> components = [];

                for (final item in componentProvider.componentsList) {
                  final String id = item['id']?.toString() ??
                      item['component_master_id']?.toString() ??
                      '';

                  final String rateStr =
                      _rateControllers[id]?.text ?? '0';
                  final double rate = double.tryParse(rateStr) ?? 0.0;

                  components.add({
                    "component_id": id,
                    "operator_rate": rate,
                  });
                }

                final body = {"components": components};

                debugPrint("========================================");
                debugPrint("📤 FULL SAVE BODY:");
                debugPrint(
                  const JsonEncoder.withIndent('  ').convert(body),
                );
                debugPrint("========================================");

                final result = await provider.uploadFreightVehicleData(
                  body: body,
                  freightId: widget.item?['id'],
                );

                if (!mounted) return;

                final bool success = result?['success'] == true;
                final message = result?['message']?.toString() ??
                    (success
                        ? "Saved successfully"
                        : "Something went wrong");

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                    success ? Colors.green : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: provider.isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(provider.isLoading ? "Saving..." : "Save Draft"),
            );
          },
        ),
      ),
    );
  }
}

// ─── Reusable pieces ────────────────────────────────────────────────────────



class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _InfoChip({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 13,
                color: isPrimary
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Color(0xFF6B7280),
  letterSpacing: 0.3,
);