import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider_service/check_area_provider.dart';
import '../../provider_service/cluster_check_provider.dart';
import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/near_by_vehicle_provider.dart';
import '../../provider_service/place_details_provider.dart';
import '../dialogBox/pickup_location_dialog.dart';
import '../model/ShipmentData.dart';
import '../model/booking_trip_request.dart';
import '../widgets/city_type_selector.dart';
import '../widgets/date_time_picker_row.dart';

class BulkBookingScreen extends StatefulWidget {
  const BulkBookingScreen({super.key});

  @override
  State<BulkBookingScreen> createState() => _BulkBookingScreenState();
}

class _BulkBookingScreenState extends State<BulkBookingScreen> {
  bool isNowSelected = true;

  // List of shipments (each item holds its own state)
  final List<ShipmentData> shipments = [ShipmentData(id: 1)];

  bool isWithinCity = true;
  bool isBookingType = true;
  bool isGettingLocation = false;
  bool isLoading = false;
  bool isBookingLoading = false;
  bool sameCluster = false;
  bool isShow = false;

  String bookingMode = "NOW";
  String clusterId = "";
  String distance = "";
  String mDistance = "";
  String mDuration = "";
  String vehicleType = "";
  String weightUnit = "";
  String mfromLable = "";
  String mtoLable = "";
  bool isService = false;
  String? mPrice;
  String selectedRole = 'Customer';
  String mButtonName = 'Find City Vehicles';

  String mLocation = "";
  String? mPincode1;
  String? mPincode2;
  BookingTripRequest? globalBookingRequest;
  Map<String, dynamic>? nearbyData;
  Map<String, dynamic>? fareData;

  // For scheduled booking
  DateTime? scheduledDateTime;

  Future<void> _checkArea(String pinCode, String isFrom, int shipmentIndex) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Provider.of<CheckAreaProvider>(
        context,
        listen: false,
      ).checkArea(pinCode);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        if (data['success'] == true && data['exists'] == true) {
          setState(() {
            if (isFrom == 'from') {
              shipments[shipmentIndex].mfromLable = "Service is available";
            } else {
              shipments[shipmentIndex].isService = true;
              shipments[shipmentIndex].mtoLable = "Service is available";
            }
          });
        } else {
          setState(() {
            shipments[shipmentIndex].isService = false;
            shipments[shipmentIndex].mfromLable = "Service is not available";
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        print("Exception${e.toString()}");
        isLoading = false;
      });
    }
  }

  void _addShipment() {
    setState(() {
      final nextId = shipments.isEmpty ? 1 : shipments.last.id + 1;
      shipments.add(ShipmentData(id: nextId));
    });
  }

  void _removeShipment(int index) {
    if (shipments.length <= 1) return; // keep at least one
    setState(() {
      shipments.removeAt(index);
    });
  }

  /// Collects all shipment data + booking mode
  void _confirmBulkBooking() {
    // Basic validation
    final incomplete = shipments.where((s) =>
    s.pickupAddress == null ||
        s.dropAddress == null ||
        s.pickupLat == null ||
        s.dropLat == null).toList();

    if (incomplete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please set pickup & drop for all shipments '
                '(${incomplete.length} incomplete)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Build the final payload
    final List<Map<String, dynamic>> shipmentList = shipments.map((s) {
      return {
        "shipment_id": s.id,
        "pickup": {
          "address": s.pickupAddress,
          "latitude": s.pickupLat,
          "longitude": s.pickupLng,
          "pincode": s.mPincode1,
        },
        "drop": {
          "address": s.dropAddress,
          "latitude": s.dropLat,
          "longitude": s.dropLng,
          "pincode": s.mPincode2,
        },
        "material": s.material,          // add TextEditingController if needed
        "weight": s.weight,              // add TextEditingController if needed
        "weight_unit": s.weightUnit,
        "quantity": s.quantity,
        "is_service_available": s.isService,
      };
    }).toList();

    final Map<String, dynamic> bulkBookingData = {
      "booking_mode": isNowSelected ? "NOW" : "SCHEDULE",
      "scheduled_datetime": isNowSelected
          ? null
          : scheduledDateTime?.toIso8601String(),
      "total_shipments": shipments.length,
      "total_vehicles": shipments.fold<int>(0, (sum, s) => sum + s.quantity),
      "shipments": shipmentList,
    };

    // Print / Log the complete data
    print("========== BULK BOOKING DATA ==========");
    print(const JsonEncoder.withIndent('  ').convert(bulkBookingData));
    print("=======================================");

    // Show confirmation dialog (replace with your API call later)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bulk Booking Data"),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(bulkBookingData),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call your bulk booking API here
              // Example:
              // await Provider.of<YourProvider>(context, listen: false)
              //     .createBulkBooking(bulkBookingData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
            ),
            child: const Text("Proceed to Book", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // ───────── Header ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Booking',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.history,
                      size: 18,
                      color: Color(0xFFE85D04),
                    ),
                    label: const Text(
                      'Past Bulk Orders',
                      style: TextStyle(
                        color: Color(0xFFE85D04),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Add each shipment below, price it, then confirm the whole batch at once.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ───────── Scrollable Content ─────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // When should this batch go out?
                    _buildTimingCard(),

                    const SizedBox(height: 16),

                    // Dynamic Shipment Cards
                    ...List.generate(shipments.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildShipmentCard(index),
                      );
                    }),

                    // Add Shipment Button
                    _buildAddShipmentButton(),

                    const SizedBox(height: 100), // space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ───────── Bottom Bar ─────────
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────── Widgets ───────────────────

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When should this batch go out?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isNowSelected = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                      isNowSelected
                          ? const Color(0xFFE85D04)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 18,
                          color:
                          isNowSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Now',
                          style: TextStyle(
                            color:
                            isNowSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isNowSelected = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                      !isNowSelected
                          ? const Color(0xFFE85D04)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 18,
                          color:
                          !isNowSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Schedule',
                          style: TextStyle(
                            color:
                            !isNowSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
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
          const SizedBox(height: 12),
          isNowSelected
              ? const Text(
            'Every shipment starts searching for a driver immediately after you confirm.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.3,
            ),
          )
              : DateTimePickerRow(
            initialDateTime: DateTime.now(),
            onDateTimeChanged: (dateTime) {
              print('Selected: $dateTime');
              setState(() {
                scheduledDateTime = dateTime;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard(int index) {
    final shipment = shipments[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHIPMENT ${shipment.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Not priced',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (shipments.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeShipment(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pickup & Drop
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>  PickupLocationDialog('Pickup Location'),
                    );

                    if (result != null) {
                      print(
                        "RanjeetTest Pickup Location =============>${result.toString()}",
                      );
                      setState(() {
                        shipment.pickupAddress = result['address'];
                        shipment.pickupLat = result['latitude'];
                        shipment.pickupLng = result['longitude'];
                        shipment.mPincode1 = result['pincode'];
                        if (shipment.mPincode1 != null) {
                          _checkArea(shipment.mPincode1!, 'from', index);
                        }
                      });
                    }
                  },
                  child: _locationField(
                    shipment.pickupAddress ?? 'Set pickup location',
                    isSelected: shipment.pickupAddress != null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) =>
                       PickupLocationDialog('Drop Location'), // same dialog
                    );

                    if (result != null) {
                      print(
                        "RanjeetTest Drop Location=============>${result.toString()}",
                      );

                      setState(() {
                        shipment.dropAddress = result['address'];
                        shipment.dropLat = result['latitude'];
                        shipment.dropLng = result['longitude'];
                        shipment.mPincode2 = result['pincode'];
                        if (shipment.mPincode1 != null &&
                            shipment.mPincode2 != null) {
                          _checkArea(shipment.mPincode2!, 'to', index);
                        }
                      });
                    }
                  },
                  child: _locationField(
                    shipment.dropAddress ?? 'Set drop location',
                    isSelected: shipment.dropAddress != null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          shipment.isService
              ? CityTypeSelector(
            isInCity: true,
            isServiceAvailable: true,
            onChanged: (isInCity) {
              print(isInCity ? "In City selected" : "Out City selected");
            },
          )
              : const SizedBox(),
          shipment.isService ? const SizedBox(height: 20) : const SizedBox(),

          // Material, Weight, Unit, Quantity
          Row(
            children: [
              Expanded(flex: 3, child: _inputField('Material (optional)')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _inputField('Weight')),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: shipment.weightUnit,
                      isExpanded: true,
                      items:
                      ['KG', 'TON', 'LB']
                          .map(
                            (e) =>
                            DropdownMenuItem(value: e, child: Text(e)),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => shipment.weightUnit = value);
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quantity stepper
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (shipment.quantity > 1) {
                          setState(() => shipment.quantity--);
                        }
                      },
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                    ),
                    Text(
                      '${shipment.quantity}×',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => shipment.quantity++),
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Get Prices Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: null, // still disabled for now
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF7ED),
                disabledBackgroundColor: const Color(0xFFFFF7ED),
                foregroundColor: const Color(0xFFE85D04),
                disabledForegroundColor: const Color(0xFFFDBA74),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Prices',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField(String text, {bool isSelected = false}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color:
            isSelected ? const Color(0xFFE85D04) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                isSelected
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String hint) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        hint,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
    );
  }

  Widget _buildAddShipmentButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _addShipment,
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: Color(0xFF4B5563)),
                SizedBox(width: 6),
                Text(
                  'Add Shipment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalVehicles = shipments.fold<int>(0, (sum, s) => sum + s.quantity);

    // Check if all shipments have pickup + drop
    final bool canConfirm = shipments.every((s) =>
    s.pickupAddress != null &&
        s.dropAddress != null &&
        s.pickupLat != null &&
        s.dropLat != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
      child: Row(
        children: [
          // Price info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0 of ${shipments.length} route(s) priced · $totalVehicles vehicle(s) total',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFFE85D04),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '₹0',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Confirm Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: canConfirm ? _confirmBulkBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canConfirm
                    ? const Color(0xFFE85D04)
                    : const Color(0xFFD1D5DB),
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Row(
                children: [
                  Text(
                    'Confirm Bulk Booking',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}