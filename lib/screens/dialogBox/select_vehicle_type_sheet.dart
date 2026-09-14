import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/vehicle_type_provider.dart';
import '../../resource/app_snack_bar.dart';

class SelectVehicleTypeSheet extends StatefulWidget {
  final String from_lat;
  final String from_lng;
  final String to_lat;
  final String to_lng;
  final String weight_kg;
  final String cluster_id;
  final String service_type;
  final String booking_mode;
  final String mDistance;
  final String mDuration;
  final String fromName;
  final String toName;

  const SelectVehicleTypeSheet({
    super.key,
    required this.from_lat,
    required this.from_lng,
    required this.to_lat,
    required this.to_lng,
    required this.weight_kg,
    required this.cluster_id,
    required this.service_type,
    required this.booking_mode,
    required this.mDistance,
    required this.mDuration,
    required this.fromName,
    required this.toName,
  });

  @override
  State<SelectVehicleTypeSheet> createState() => _SelectVehicleTypeSheetState();
}

class _SelectVehicleTypeSheetState extends State<SelectVehicleTypeSheet> {
  bool isInstant = true;
  bool _isLoading = true;

  // Parsed data
  List<Map<String, dynamic>> groupedVehicles = [];
  Map<String, dynamic>? selectedVehicle;

  double offerPrice = 0;
  double minPrice = 0;
  double maxPrice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final fareProvider = Provider.of<FareCalculateProvider>(context, listen: false);

    final response = await fareProvider.fetchFareCalculate(
      widget.from_lat,
      widget.from_lng,
      widget.to_lat,
      widget.to_lng,
      widget.weight_kg,
      widget.cluster_id,
      widget.service_type,
      widget.booking_mode,
    );

    if (!mounted) return;

    if (response != null && response['status'] == 'success') {
      _parseVehicleData(response);
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
      final errorMsg = fareProvider.error ?? "Something went wrong. Please try again.";
      AppSnackBar.show(context, message: errorMsg, isError: true);
    }
  }

  // ─────────────── PARSE API DATA ───────────────
  void _parseVehicleData(Map<String, dynamic> response) {
    final List types = response['data']?['types'] ?? [];

    // Group by v_cat
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in types) {
      final String category = item['v_cat'] ?? 'Uncategorized';
      final bool hasPrice = item['price_min'] != null && item['price_max'] != null;

      // Only show vehicles that have pricing or are available
      if (!hasPrice && (item['vehicle_count'] ?? 0) == 0) continue;

      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add({
        "id": item['id'],
        "name": item['name']?.toString() ?? "",
        "payload": item['max_payload_kg'] != null
            ? "${_formatNumber(double.tryParse(item['max_payload_kg'].toString()) ?? 0)} kg"
            : "${item['name']} kg",
        "nearby": item['vehicle_count'] ?? 0,
        "priceMin": item['price_min'] != null ? (item['price_min'] as num).toDouble() : 0,
        "priceMax": item['price_max'] != null ? (item['price_max'] as num).toDouble() : 0,
        "negotiationFloor": item['negotiation_floor'] != null
            ? (item['negotiation_floor'] as num).toDouble()
            : 0,
        "negotiationCeiling": item['negotiation_ceiling'] != null
            ? (item['negotiation_ceiling'] as num).toDouble()
            : 0,
        "freightAvailable": item['freight_available'] ?? false,
      });
    }

    // Convert to list for UI
    groupedVehicles = grouped.entries.map((e) {
      return {
        "group": e.key,
        "options": e.value,
      };
    }).toList();

    // Auto-select first available vehicle
    if (groupedVehicles.isNotEmpty) {
      final firstGroup = groupedVehicles.first;
      final options = firstGroup['options'] as List;
      if (options.isNotEmpty) {
        _selectVehicle(options.first);
      }
    }
  }

  void _selectVehicle(Map<String, dynamic> vehicle) {
    setState(() {
      selectedVehicle = vehicle;
      minPrice = vehicle['negotiationFloor'] > 0
          ? vehicle['negotiationFloor']
          : vehicle['priceMin'];
      maxPrice = vehicle['negotiationCeiling'] > 0
          ? vehicle['negotiationCeiling']
          : vehicle['priceMax'];
      offerPrice = minPrice;
    });
  }

  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _format(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── HEADER ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Select Vehicle Type",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Choose the best option for your shipment",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Route card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.fromName,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.toName,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.mDistance,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── BODY ──────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedVehicles.isEmpty
                ? const Center(child: Text("No vehicles available"))
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  // Instant / Negotiate Toggle
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isInstant = true),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isInstant
                                    ? const Color(0xFF16A34A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    color: isInstant
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Instant",
                                    style: TextStyle(
                                      color: isInstant
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isInstant = false),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: !isInstant
                                    ? const Color(0xFF7C3AED)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.handshake_rounded,
                                    color: !isInstant
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Negotiate",
                                    style: TextStyle(
                                      color: !isInstant
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dynamic Vehicle Groups
                  ...groupedVehicles.map((group) {
                    final options = group['options'] as List;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Group Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group['group'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${options.length} option${options.length > 1 ? 's' : ''}",
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          // Vehicle Options
                          ...options.map((v) {
                            final isSelected =
                                selectedVehicle?['id'] == v['id'];

                            return GestureDetector(
                              onTap: () => _selectVehicle(v),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0F9FF)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFBFDBFE)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping,
                                        color: Color(0xFF2563EB),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v['payload'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Payload capacity · ${v['nearby']} vehicles nearby",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${_format(v['priceMin'])}–₹${_format(v['priceMax'])}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "incl. toll",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey.shade400,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),

                  // Selected Summary
                  if (selectedVehicle != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Selected",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                              Text(
                                isInstant
                                    ? "Price Range"
                                    : "Negotiable Range",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedVehicle!['payload'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    selectedVehicle!['name'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                              Text(
                                "₹${_format(selectedVehicle!['priceMin'])}–₹${_format(selectedVehicle!['priceMax'])}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          if (!isInstant) ...[
                            const SizedBox(height: 16),
                            const Text(
                              "Your opening offer",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF7C3AED),
                                inactiveTrackColor:
                                const Color(0xFFE9D5FF),
                                thumbColor: const Color(0xFF7C3AED),
                                overlayColor: const Color(0xFF7C3AED)
                                    .withOpacity(0.2),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: offerPrice,
                                min: minPrice,
                                max: maxPrice,
                                onChanged: (v) =>
                                    setState(() => offerPrice = v),
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text("₹${_format(minPrice)}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  "₹${_format(offerPrice.round())}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                Text("₹${_format(maxPrice)}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Owners can accept your offer directly, or send their own price + arrival time — you pick after booking.",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              "Final price is whichever nearby owner accepts first, at their own real cost.",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── BOTTOM BUTTON ─────────────────────────────────────────
          if (selectedVehicle != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          "mode": isInstant ? "instant" : "negotiate",
                          "price": isInstant
                              ? selectedVehicle!['priceMin']
                              : offerPrice.round(),
                          "vehicleId": selectedVehicle!['id'],
                          "payload": selectedVehicle!['name'],
                          "vehicleType": selectedVehicle!['name'],
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInstant
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isInstant
                            ? "Request Now · ₹${_format(selectedVehicle!['priceMin'])}"
                            : "Send Offer · ₹${_format(offerPrice.round())}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text("Payment Method",
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Cash / Online",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}