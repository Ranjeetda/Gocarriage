import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/vehicle_type_provider.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_snack_bar.dart';

class VehicleSelectionSheet extends StatefulWidget {
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

  const VehicleSelectionSheet({
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
  State<VehicleSelectionSheet> createState() => _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<VehicleSelectionSheet> {
  Map<String, dynamic>? fareData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final vehicleProvider = Provider.of<VehicleTypeProvider>(context, listen: false);
    final fareProvider = Provider.of<FareCalculateProvider>(context, listen: false);

    await vehicleProvider.fetchVehicleType();

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
      setState(() {
        fareData = response;
        _isLoading = false;
      });
      vehicleProvider.applyFareResponse(response);
    } else {
      setState(() => _isLoading = false);
      final errorMsg = fareProvider.error ?? "Something went wrong. Please try again.";
      AppSnackBar.show(context, message: errorMsg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                _routeCard(),
                const SizedBox(height: 12),
                _searchBar(),
                const SizedBox(height: 8),
                Expanded(child: _vehicleList()),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // ────────────────────────── HEADER ──────────────────────────
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Select Vehicle Type",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Choose the best option for your shipment",
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── ROUTE CARD ──────────────────────────
  Widget _routeCard() {
    final distance = fareData?['data']?['distance_km']?.toString() ?? widget.mDistance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // From → To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.fromName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A237E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.toName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A237E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "$distance km",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  // ────────────────────────── SEARCH BAR ──────────────────────────
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search by group or payload (e.g. 2000, Light...)",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (q) {
          // Optional: implement filter later
        },
      ),
    );
  }

  // ────────────────────────── VEHICLE LIST ──────────────────────────
  Widget _vehicleList() {
    return Consumer<VehicleTypeProvider>(
      builder: (context, provider, _) {
        final types = fareData?['data']?['types'] as List? ?? [];

        // Only keep groups that have at least one available vehicle with price
        final availableGroups = <Map<String, dynamic>>[];

        for (final group in provider.vehicleTypes) {
          final availableOptions = <Map<String, dynamic>>[];

          for (final option in group.options) {
            final match = types.cast<Map<String, dynamic>>().firstWhere(
                  (t) => t['id'] == option.id && (t['freight_available'] == true || t['price'] != null),
              orElse: () => {},
            );

            if (match.isNotEmpty) {
              availableOptions.add({
                'option': option,
                'price': match['price'] ?? 0,
                'max_payload': match['max_payload_kg'],   // ← only use the value coming from fare API
              });
            }
          }

          if (availableOptions.isNotEmpty) {
            availableGroups.add({
              'group': group.group,
              'options': availableOptions,
            });
          }
        }

        if (availableGroups.isEmpty) {
          return const Center(
            child: Text("No vehicles available for this route"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: availableGroups.length,
          itemBuilder: (context, index) {
            final group = availableGroups[index];
            return _groupCard(
              groupName: group['group'],
              options: group['options'],
              provider: provider,
            );
          },
        );
      },
    );
  }

  Widget _groupCard({
    required String groupName,
    required List options,
    required VehicleTypeProvider provider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  "${options.length} option${options.length > 1 ? 's' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Options
          ...options.map((item) {
            final option = item['option'];
            final price = item['price'] as num;
            final isSelected = provider.selectedVehicleId == option.id;

            return GestureDetector(
              onTap: () {
                provider.setSelectedGroup(groupName);
                provider.setSelectedVehicle(option.id, option.name);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.primaryColor.withOpacity(0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    // Truck icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor.withOpacity(0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + capacity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${option.name} kg",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Payload capacity",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${price.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isSelected ? AppColors.primaryColor : Colors.black87,
                          ),
                        ),
                        Text(
                          "incl. toll",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: AppColors.primaryColor, size: 22),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ────────────────────────── BOTTOM BAR ──────────────────────────
  Widget _bottomBar() {
    return Consumer<VehicleTypeProvider>(
      builder: (context, provider, _) {
        final types = fareData?['data']?['types'] as List? ?? [];
        final selected = types.cast<Map<String, dynamic>>().firstWhere(
              (t) => t['id'] == provider.selectedVehicleId,
          orElse: () => {},
        );

        final price = selected['price'] ?? 0;
        final name = provider.selectedVehicleName ?? "-";
        final group = provider.selectedGroup ?? "";

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selected summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selected",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$name kg",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          group,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Price",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "₹${price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  "Vehicle will be assigned from nearby drivers at this price.",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 12),

                // Book Now button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: provider.selectedVehicleId == null
                        ? null
                        : () {
                      Navigator.pop(context, {
                        "vehicleTypeId": provider.selectedVehicleId,
                        "vehicleType": provider.selectedVehicleName,
                        "group": provider.selectedGroup,
                        "price": price,
                      });
                    },
                    child: Text(
                      "Book Now · ₹${price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Payment method row
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "Payment Method",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const Spacer(),
                    Text(
                      "Cash / Online",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}