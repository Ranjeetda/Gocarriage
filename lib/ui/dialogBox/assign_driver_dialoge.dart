import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider_service/assign_vehicle_driver_provider.dart';
import '../../provider_service/vechile_owner_driver_list.dart';
import '../../provider_service/vechile_owner_fleets_list.dart';
import '../../resource/Utils.dart';
import 'package:http/http.dart' as http;

class AssignDriverDialoge extends StatefulWidget {
  const AssignDriverDialoge({super.key});

  @override
  State<AssignDriverDialoge> createState() => _AssignDriverDialogeState();
}

class _AssignDriverDialogeState extends State<AssignDriverDialoge> {
  String? selectedServiceType;
  int? selectedVehicleId;
  int? selectedDriver;
  int? selectedDriverId;
  String? selectedShift;
  bool isLoading = false;


  final List<String> shifts = [
    'Morning (6AM - 2PM)',
    'Afternoon (2PM - 10PM)',
    'Night (10PM - 6AM)',
  ];

  void assignDriver() {
    if (selectedServiceType == null ||
        selectedVehicleId == null ||
        selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    _assignDriver(selectedDriverId.toString(),selectedVehicleId.toString());

  }

  Future<void> _assignDriver(String? driverId, String? vehicleId) async {
    if (vehicleId == null) {
      Utils.showErrorMessage(context, "Please select vehicle");
      return;
    }  if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return;
    }
    setState(() {
      isLoading = true;
    });
    http.Response response = await Provider.of<AssignVehicleDriverProvider>(
      context,
      listen: false,
    ).assignVechicleDriver(driverId, vehicleId);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() {
        isLoading = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Assign Driver failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

// 74368764416
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(),
              const SizedBox(height: 20),

              /// SERVICE TYPE
              _label('Service Type *'),
              DropdownButtonFormField<String>(
                value: selectedServiceType,
                hint: const Text('-- Select Service Type --'),
                items: const [
                  DropdownMenuItem(
                      value: 'in_city', child: Text('Within City')),
                  DropdownMenuItem(
                      value: 'out_city', child: Text('Outside City')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedServiceType = value;
                    selectedVehicleId = null;
                  });

                  Provider.of<VechileOwnerFleetsList>(
                    context,
                    listen: false,
                  ).fetchList(value!);


                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<VechileOwnerDriverList>(context, listen: false).fetchList(value);
                  });
                },
                decoration:
                const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 16),

              /// VEHICLE DROPDOWN
              _label('Select Vehicle *'),
              Consumer<VechileOwnerFleetsList>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    itemHeight: 60,
                    value: selectedVehicleId,
                    hint: const Text('-- Select Vehicle --'),
                    items: provider.listData.map<DropdownMenuItem<int>>((v) {
                      return DropdownMenuItem<int>(
                        value: v['id'], // ✅ VEHICLE ID
                        child: Text(v['vehicle_number']),
                      );
                    }).toList(),
                    onChanged: selectedServiceType == null
                        ? null
                        : (value) {
                      setState(() {
                        selectedVehicleId = value;
                      });
                    },
                    decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),

              const SizedBox(height: 16),

              /// DRIVER
              _label('Select Driver *'),
              Consumer<VechileOwnerDriverList>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    value: selectedDriver,
                    hint: const Text('-- Select Driver --'),
                    items: provider.listData.map<DropdownMenuItem<int>>((v) {
                      return DropdownMenuItem<int>(
                        value: v['driver_id'],
                        child: Text(
                          "${v['Driver']['fullName']}",
                        ),
                      );
                    }).toList(),
                    onChanged: selectedServiceType == null
                        ? null
                        : (value) {
                      setState(() {
                        selectedDriver = value;
                        print('RanjeetTest ===========>${value}');
                        print('RanjeetTest ===========>${selectedDriver}');
                        selectedDriverId = value;
                      });
                    },
                    decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),

              const SizedBox(height: 16),

              /// SHIFT
              _label('Select Shift (Optional)'),
              DropdownButtonFormField<String>(
                value: selectedShift,
                hint: const Text('-- Select Shift --'),
                items: shifts
                    .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedShift = value),
                decoration:
                const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),

              /// ASSIGN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: assignDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      :const Text('Assign Driver',style: TextStyle(color: Colors.white),),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Assign Driver to Vehicle',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
