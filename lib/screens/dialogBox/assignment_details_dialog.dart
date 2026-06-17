import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../resource/Utils.dart';
import '../../provider_service/owner_unassign_driver_vehicle.dart';

class AssignmentDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const AssignmentDetailsDialog(this.data, {super.key});

  @override
  State<AssignmentDetailsDialog> createState() =>
      _AssignmentDetailsDialogState();
}

class _AssignmentDetailsDialogState
    extends State<AssignmentDetailsDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final driver = widget.data['Driver'] ?? {};
    final fleet = widget.data['Fleet'] ?? {};

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F8A7B),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    const Icon(Icons.visibility, color: Colors.white),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Assignment Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Full assignment information",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                      const Icon(Icons.close, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),

            /// BODY
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// DRIVER INFO
                  _infoCard(
                    icon: Icons.person_outline,
                    title: "Driver Information",
                    color: Colors.green,
                    children: [
                      _row("Name",
                          driver['fullName']?.toString() ?? "N/A"),
                      _row("Mobile",
                          driver['mobileNo']?.toString() ?? "N/A"),
                      _row("Email", "N/A"),
                      _row("Service",
                          driver['service_type']?.toString() ?? "N/A"),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// VEHICLE INFO
                  _infoCard(
                    icon: Icons.local_shipping_outlined,
                    title: "Vehicle Information",
                    color: Colors.blue,
                    children: [
                      _row("Number",
                          fleet['vehicle_number']?.toString() ?? "N/A"),
                      _row("Type", "N/A"),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// ASSIGNMENT INFO
                  _infoCard(
                    icon: Icons.calendar_today_outlined,
                    title: "Assignment Info",
                    color: Colors.grey,
                    children: [
                      _row("Assigned On",
                          widget.data['assigned_at']?.toString() ?? "N/A"),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Status"),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (widget.data['is_active'] ?? false)
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor:
                                  (widget.data['is_active'] ?? false)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (widget.data['is_active'] ?? false)
                                      ? "Active"
                                      : "In-Active",
                                  style: TextStyle(
                                    color:
                                    (widget.data['is_active'] ?? false)
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            showDeleteDriverDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text(
                            "Unassign",
                            style:
                            TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- DELETE DIALOG ----------------
  Future<void> showDeleteDriverDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unassign"),
        content: const Text(
          "Are you sure you want to unassign this driver?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unAssignDriver(
                widget.data['driver_id']?.toString(),
                widget.data['vehicle_id']?.toString(),
              );
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- API CALL ----------------
  Future<void> _unAssignDriver(
      String? driverId, String? vehicleId) async {
    if (vehicleId == null) {
      Utils.showErrorMessage(context, "Please select vehicle");
      return;
    }
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select driver");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response =
      await Provider.of<OwnerUnassignDriverVehicle>(
        context,
        listen: false,
      ).unAssignDriver(driverId, vehicleId);

      final responseData = json.decode(response.body);

      setState(() => isLoading = false);

      if (responseData['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        Utils.showErrorMessage(
          context,
          responseData['message'] ?? "Failed",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      Utils.showErrorMessage(context, "Something went wrong");
    }
  }
}

/// ---------------- CARD ----------------
Widget _infoCard({
  required IconData icon,
  required String title,
  required Color color,
  required List<Widget> children,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children
      ],
    ),
  );
}

/// ---------------- ROW ----------------
class _row extends StatelessWidget {
  final String label;
  final String value;

  const _row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}