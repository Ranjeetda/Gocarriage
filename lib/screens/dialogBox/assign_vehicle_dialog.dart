import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../provider_service/assign_bulk_vehicle_provider.dart';
import '../../provider_service/fleet_vehicle_list_provider.dart';
import '../../resource/Utils.dart';

class AssignVehicleDialog extends StatefulWidget {
  final String vehicleTypeTitle;
  final String vehiclesId;
  final String bulkOrderId;
  final Function(Map<String, dynamic> selectedVehicle) onConfirm;

  const AssignVehicleDialog({
    Key? key,
    required this.vehicleTypeTitle,
    required this.vehiclesId,
    required this.bulkOrderId,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AssignVehicleDialog> createState() => _AssignVehicleDialogState();
}

class _AssignVehicleDialogState extends State<AssignVehicleDialog> {
  int? selectedIndex;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FleetVehicleListProvider>(
        context,
        listen: false,
      ).fetchList(widget.vehiclesId);
    });
  }

  Future<void> _assignBulkVehicle(String fleetId, String bulkOrderId) async {
    setState(() => isLoading = true);

    http.Response response = await Provider.of<AssignBulkVehicleProvider>(
      context,
      listen: false,
    ).acceptBooking(fleetId, bulkOrderId,'accept');
    setState(() => isLoading = false);
    final data = json.decode(response.body);

    if (data['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
      Navigator.pop(context);
    } else {
      Utils.showErrorMessage(context, data['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedIndex != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: 620,
        child: Column(
          children: [
            // ---------------- Header ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Assign a Vehicle",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.vehicleTypeTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ---------------- Vehicle List ----------------
            Expanded(
              child: Consumer<FleetVehicleListProvider>(
                builder: (context, service, _) {
                  // Loading
                  if (service.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Empty
                  if (service.listData.isEmpty) {
                    return const Center(
                      child: Text(
                        "No vehicles available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // List
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: service.listData.length,
                    itemBuilder: (context, index) {
                      final vehicle = service.listData[index];
                      final isSelected = selectedIndex == index;

                      final plate = vehicle["vehicle_number"] ?? "N/A";

                      final type =
                          vehicle["vehicleType"] ??
                          vehicle["type"] ??
                          widget.vehicleTypeTitle;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFE8F7F2)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF0D7A5F)
                                      : const Color(0xFFE0E5EF),
                              width: isSelected ? 1.8 : 1.2,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0D7A5F,
                                        ).withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xFF0D7A5F,
                                          ).withOpacity(0.12)
                                          : const Color(0xFFF4F6F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color:
                                      isSelected
                                          ? const Color(0xFF0D7A5F)
                                          : Colors.grey,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plate.toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isSelected
                                                ? const Color(0xFF0D7A5F)
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      type.toString(),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0D7A5F),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ---------------- Bottom Button ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Consumer<FleetVehicleListProvider>(
                  builder: (context, service, _) {
                    return ElevatedButton.icon(
                      onPressed:
                          hasSelection
                              ? () {
                                _assignBulkVehicle(
                                  service.listData[selectedIndex!]['id'].toString(),
                                  widget.bulkOrderId,
                                );
                                final selected =
                                    service.listData[selectedIndex!];
                                widget.onConfirm(selected);
                              }
                              : null,
                      icon: const Icon(Icons.check),
                      label:
                          isLoading
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                "Confirm Assignment",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasSelection
                                ? const Color(0xFF0D7A5F)
                                : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
