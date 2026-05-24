import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider_service/vehicle_type_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';

class VehicleSelectionSheet extends StatefulWidget {
  final String pincode1;
  final String pincode2;
  final String mDistance;
  final String mDuration;
  final Map<String, dynamic>? fareData;

  const VehicleSelectionSheet(
      this.pincode1, this.pincode2,this.mDistance,this.mDuration,this.fareData,
      {super.key});

  @override
  State<VehicleSelectionSheet> createState() =>
      _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<VehicleSelectionSheet> {


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider =
      Provider.of<VehicleTypeProvider>(context, listen: false);

      await provider.fetchVehicleType();

      // ✅ Apply fare selection
      if (widget.fareData != null) {
        provider.applyFareResponse(widget.fareData!);
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const SizedBox(height: 10),
          _distanceCard(),

          const SizedBox(height: 10),

          /// ✅ VEHICLE LIST
          Consumer<VehicleTypeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final fareList =
                  widget.fareData?['data']?['fares'] ?? [];

              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.vehicleTypes.length,
                  itemBuilder: (context, index) {
                    final group = provider.vehicleTypes[index];

                    // ✅ filter by vehicle_type_id
                    final options = group.options.where((option) {
                      return fareList.any(
                            (f) =>
                        f['vehicle_type_id'] == option.id,
                      );
                    }).toList();

                    if (options.isEmpty) {
                      return const SizedBox();
                    }

                    return _vehicleGroupCard(
                      groupName: group.group ?? "",
                      options: options,
                      provider: provider,
                      fareList: fareList,
                    );
                  },
                ),
              );
            },
          ),

          _bottomBar(),
        ],
      ),
    );
  }

  // ================= UI =================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Select Vehicle Type",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _distanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                widget.mDistance,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                widget.mDuration,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= GROUP CARD =================

  Widget _vehicleGroupCard({
    required String groupName,
    required List options,
    required VehicleTypeProvider provider,
    required List fareList,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                Text("${options.length} option"),
              ],
            ),
          ),

          // OPTIONS
          ...options.map((option) {
            final fare = fareList.firstWhere(
                  (f) => f['vehicle_type_id'] == option.id,
              orElse: () => {},
            );

            final price =
                fare['approximate_fare']?['total'] ?? 0;

            final isSelected =
                provider.selectedVehicleId == option.id;

            return GestureDetector(
              onTap: () {
                provider.setSelectedGroup(groupName);
                provider.setSelectedVehicle(option.id, option.name);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade50
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                        color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${option.name} kg",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Payload capacity",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${price.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        const Text("incl. toll",
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),

                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle,
                            color: Colors.blue),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= BOTTOM =================

  Widget _bottomBar() {
    return Consumer<VehicleTypeProvider>(
      builder: (context, provider, _) {
        final fareList =
            widget.fareData?['data']?['fares'] ?? [];

        final selectedFare = fareList.firstWhere(
              (f) =>
          f['vehicle_type_id'] ==
              provider.selectedVehicleId,
          orElse: () => {},
        );

        final price = selectedFare['approximate_fare']?['total'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Vehicle\n${provider.selectedVehicleId ?? "-"} kg",
                  ),
                  Text(
                    "₹${price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    AppColors.primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      "vehicleType": provider.selectedVehicleName,
                      "price": price,
                    });
                  },
                  child: const Text("Confirm",style: TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}