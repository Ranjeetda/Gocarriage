import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import '../model/vehicle_model.dart';

class VehicleSelectionSheet extends StatefulWidget {
  final String pincode1;
  final String pincode2;


  VehicleSelectionSheet(this.pincode1, this.pincode2);

  @override
  State<VehicleSelectionSheet> createState() =>
      _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<VehicleSelectionSheet> {
  int selectedIndex = 0;

  double? totalDistance;
  int? totalTime;
  bool isLoading = true;

  final vehicles = [
    VehicleModel(
      name: "3 Wheeler",
      time: "---",
      capacity: "500 kg",
      size: "5.5ft x 4.5ft x 5ft",
      price: 653,
      recommended: true,
    ),
    VehicleModel(
      name: "Tata Ace",
      time: "",
      capacity: "750 kg",
      size: "7ft x 4.5ft x 5ft",
      price: 844,
    ),
    VehicleModel(
      name: "Pickup 8ft",
      time: "---",
      capacity: "1200 kg",
      size: "8ft x 4.5ft x 5.5ft",
      price: 1064,
    ),
    VehicleModel(
      name: "14ft Truck",
      time: "---",
      capacity: "3500 kg",
      size: "14ft x 6ft x 6ft",
      price: 1857,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDistanceAndTime();
  }

  Future<void> _loadDistanceAndTime() async {
    final result =
    await Utils.calculateDistanceAndTime(
      widget.pincode1,
      widget.pincode2,
    );

    if (!mounted) return;

    setState(() {
      totalDistance = result['distanceKm'];
      totalTime = result['estimatedTimeMin'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = vehicles[selectedIndex];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const SizedBox(height: 10),

          /// DISTANCE + TIME CARD
          isLoading
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
              : _distanceCard(),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return _vehicleTile(
                  vehicle: vehicles[index],
                  selected: selectedIndex == index,
                  onTap: () =>
                      setState(() => selectedIndex = index),
                );
              },
            ),
          ),

          _bottomBar(selectedVehicle),
        ],
      ),
    );
  }

  // ================= UI WIDGETS =================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:  BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Select Vehicle Type",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
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
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                "${totalDistance!.toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                "~$totalTime min",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(VehicleModel vehicle) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Vehicle\n${vehicle.name}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                "₹${vehicle.price}",
                style: const TextStyle(
                  fontSize: 20,
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
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, vehicle);
              },
              child: Text(
                "Confirm ${vehicle.name}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleTile({
    required VehicleModel vehicle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          selected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      if (vehicle.recommended)
                        Container(
                          margin:
                          const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Recommended",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                 /* Text(vehicle.time,
                      style:
                      const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 4),*/
                  Text(
                    "${vehicle.capacity} • ${vehicle.size}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${vehicle.price}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Text("incl. toll",
                    style: TextStyle(fontSize: 12)),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: Colors.blue),
              ],
            )
          ],
        ),
      ),
    );
  }
}
