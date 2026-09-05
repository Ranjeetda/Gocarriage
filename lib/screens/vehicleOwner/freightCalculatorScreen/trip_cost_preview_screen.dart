import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;

import '../../../provider_service/URLS.dart';

class TripCostPreviewScreen extends StatefulWidget {
  String vehicleId;
  String comeFrom;


  TripCostPreviewScreen(this.vehicleId,this.comeFrom);

  @override
  State<TripCostPreviewScreen> createState() => _TripCostPreviewScreenState();
}

class _TripCostPreviewScreenState extends State<TripCostPreviewScreen> {
  final _distanceCtrl = TextEditingController(text: '500');
  final _weightCtrl = TextEditingController(text: '');
  final _kmPerDayCtrl = TextEditingController(text: '500');
  final _loadingDaysCtrl = TextEditingController(text: '1');
  final _unloadingDaysCtrl = TextEditingController(text: '1');
  final _extraTollsCtrl = TextEditingController(text: '0');

  bool _loading = false;
  bool _computed = false;
  String? _error;
  String URLs='';
  // From API
  String _modelName = 'Pro 2055T';
  Map<String, dynamic>? _trip;
  List<Map<String, dynamic>> _lineItems = [];
  double _subtotal = 0;
  double _total = 0;



  @override
  void dispose() {
    _distanceCtrl.dispose();
    _weightCtrl.dispose();
    _kmPerDayCtrl.dispose();
    _loadingDaysCtrl.dispose();
    _unloadingDaysCtrl.dispose();
    _extraTollsCtrl.dispose();
    super.dispose();
  }

  Future<void> _computeTripCost() async {
    final distance = double.tryParse(_distanceCtrl.text) ?? 0;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final kmPerDay = double.tryParse(_kmPerDayCtrl.text) ?? 0;
    final loadingDays = int.tryParse(_loadingDaysCtrl.text) ?? 0;
    final unloadingDays = int.tryParse(_unloadingDaysCtrl.text) ?? 0;
    final extraTolls = double.tryParse(_extraTollsCtrl.text) ?? 0;

    if (distance <= 0) {
      setState(() => _error = 'Distance is required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _computed = false;
    });

    try {
      if(widget.comeFrom=='master'){
        URLs='${URLS.baseUrl}/freight/owner/vehicle/${widget.vehicleId}/trip-cost';
      }{
        URLs='${URLS.baseUrl}/freight/fleet/${widget.vehicleId}/trip-cost';

      }
      final uri = Uri.parse(URLs,);
      final body = {
        'total_distance': distance,
        'weight_tons': weight,
        'km_per_day': kmPerDay,
        'loading_days': loadingDays,
        'unloading_days': unloadingDays,
        'extra_tolls': extraTolls,
      };
      print("URLS =============${uri.toString()}");
      print("Request =============${body.toString()}");
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${PrefUtils.getToken()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception('API error ${res.statusCode}: ${res.body}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        throw Exception(json['message'] ?? 'Request failed');
      }

      final data = json['data'] as Map<String, dynamic>;
      final vehicle = data['vehicle_freight'] as Map<String, dynamic>;
      final calc = data['calculation'] as Map<String, dynamic>;
      final trip = calc['trip'] as Map<String, dynamic>;
      final items = (calc['line_items'] as List).cast<Map<String, dynamic>>();

      setState(() {
        _modelName = vehicle['model_name']?.toString() ?? 'Pro 2055T';
        _trip = trip;
        _lineItems = items;
        _subtotal = (calc['subtotal'] as num).toDouble();
        _total = (calc['total'] as num).toDouble();
        _computed = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _computed = false;
      });
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _formatInr(num value) {
    // Simple Indian-style formatting
    final abs = value.abs();
    final str = abs.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    final parts = str.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formatted;
    if (intPart.length <= 3) {
      formatted = intPart;
    } else {
      final last3 = intPart.substring(intPart.length - 3);
      var rest = intPart.substring(0, intPart.length - 3);
      final buffer = StringBuffer();
      while (rest.length > 2) {
        buffer.write(',${rest.substring(rest.length - 2)}');
        rest = rest.substring(0, rest.length - 2);
      }
      formatted = '$rest$buffer,$last3';
    }
    return '₹$formatted$decPart';
  }

  String _unitLabel(String rateUnit) {
    switch (rateUnit.toUpperCase()) {
      case 'PER_DAY':
        return 'per day';
      case 'PER_KM':
        return 'per km';
      case 'PER_YEAR':
        return 'per year';
      case 'PER_MONTH':
        return 'per month';
      case 'PER_TON':
        return 'per ton';
      case 'PER_TRIP':
        return 'per trip';
      default:
        return rateUnit.toLowerCase().replaceAll('_', ' ');
    }
  }

  String _qtyLabel(dynamic qty) {
    if (qty is num) {
      if (qty == qty.roundToDouble()) return qty.toInt().toString();
      return qty.toStringAsFixed(2);
    }
    return qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip Cost Preview',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _modelName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Input fields ──────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        label: 'Distance (km)',
                        isRequired: true,
                        controller: _distanceCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InputField(
                        label: 'Weight (tons)',
                        controller: _weightCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        label: 'Km / day',
                        controller: _kmPerDayCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InputField(
                        label: 'Loading days',
                        controller: _loadingDaysCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        label: 'Unloading days',
                        controller: _unloadingDaysCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InputField(
                        label: 'Extra tolls (₹)',
                        controller: _extraTollsCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _computeTripCost,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.route, size: 20),
                    label: Text(
                      _loading ? 'Computing…' : 'Compute trip cost',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFA78BFA),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          if (_computed && _trip != null) ...[
            const SizedBox(height: 16),

            // ── Summary chips ───────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SummaryChip(
                    title: 'DISTANCE',
                    value: '${_formatNumber(_trip!['total_distance'])} km',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'WEIGHT',
                    value: '${_formatNumber(_trip!['weight_tons'])} t',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'KM / DAY',
                    value: _formatNumber(_trip!['km_per_day']),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'RUNNING',
                    value: '${_trip!['running_days']} d',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'LOADING',
                    value: '${_trip!['loading_days']} d',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'UNLOADING',
                    value: '${_trip!['unloading_days']} d',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    title: 'TOTAL DAYS',
                    value: '${_trip!['total_days']}',
                    highlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Cost breakdown table ────────────────────────────
            _Card(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 24, child: Text('#', style: _hStyle)),
                        Expanded(flex: 5, child: Text('COMPONENT', style: _hStyle)),
                        Expanded(flex: 2, child: Text('UNIT', style: _hStyle)),
                        Expanded(flex: 2, child: Text('RATE', style: _hStyle)),
                        Expanded(flex: 2, child: Text('QTY', style: _hStyle)),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'AMOUNT',
                            style: _hStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dynamic rows from API
                  ...List.generate(_lineItems.length, (i) {
                    final c = _lineItems[i];
                    final isComputed = c['is_computed'] == true;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == _lineItems.length - 1
                                ? Colors.transparent
                                : const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (isComputed)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'computed',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _unitLabel(c['rate_unit']?.toString() ?? ''),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatNumber(c['rate']),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _qtyLabel(c['quantity']),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatInr(c['amount'] as num),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Totals ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SUBTOTAL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          _formatInr(_subtotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL FREIGHT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          _formatInr(_total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}

// ─── Reusable widgets (unchanged) ───────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;

  const _InputField({
    required this.label,
    required this.controller,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _SummaryChip({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: highlight ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlight ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Color(0xFF64748B),
  letterSpacing: 0.3,
);