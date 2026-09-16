import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/screens/dashboardScreen/vehicle_selection_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../provider_service/URLS.dart';
import '../../provider_service/bluk_booking_trip_provider.dart';
import '../../provider_service/booking_trip.dart';
import '../../provider_service/check_area_provider.dart';
import '../../provider_service/cluster_check_provider.dart';
import '../../provider_service/distance_provider.dart';
import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/near_by_vehicle_provider.dart';
import '../../provider_service/pincode_city_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_snack_bar.dart';
import '../../resource/pref_utils.dart';
import '../auth/login_screen.dart';
import '../dialogBox/bulk_waiting_bottom_sheet.dart';
import '../dialogBox/driver_bottom_sheet.dart';
import '../dialogBox/pickup_location_dialog.dart';
import '../dialogBox/select_vehicle_type_sheet.dart';
import '../dialogBox/special_instructions_dialog.dart';
import '../model/ShipmentData.dart';
import '../model/bluk_booking_trip_request.dart';
import '../model/booking_trip_request.dart';
import '../model/location_modal.dart';
import '../model/special_requirements.dart';
import '../widgets/advance_payment_info_banner.dart';
import '../widgets/city_type_selector.dart';
import '../widgets/date_time_picker_row.dart';
import '../widgets/material_details_form.dart';
import '../widgets/pickup_date_time_selector.dart';
import '../widgets/service_mode_selector.dart';
import 'bulk_orders_screen.dart';

enum BookingMode { now, schedule }

class BulkBookingScreen extends StatefulWidget {
  const BulkBookingScreen({super.key});

  @override
  State<BulkBookingScreen> createState() => _BulkBookingScreenState();
}

class _BulkBookingScreenState extends State<BulkBookingScreen> {
  // ─── State ────────────────────────────────────────────────────────────────
  final List<ShipmentData> shipments = [ShipmentData(id: 1)];

  bool isLoading = false;
  bool isBookingLoading = false;
  bool sameCluster = false;

  String bookingMode = 'NOW';
  BookingMode selectedMode = BookingMode.now;
  ServiceMode? _selectedMode;
  bool _userHasSelected = false;
  String mServiceType = 'in_city';

  String clusterId = '';
  String distance = '';
  String mDistance = '';
  String mDuration = '';
  String vehicleType = '';
  String weightUnit = '';

  String? mPrice;
  String? mDate;
  String? mTime;
  DateTime? scheduledDateTime;

  Map<String, dynamic> materialData = {};

  Key _serviceModeKey = UniqueKey();
  Key _bookingModeKey = UniqueKey();

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedMode = ServiceMode.incity;
    _applyServiceMode(ServiceMode.incity);
  }

  // ─── Computed helpers ─────────────────────────────────────────────────────
  int get _pricedCount => shipments.where((s) => s.isPriced).length;

  int get _totalVehiclesNeeded =>
      shipments.fold<int>(0, (sum, s) => sum + s.quantity);

  int get _totalAllocated =>
      shipments.fold<int>(0, (sum, s) => sum + s.totalAllocated);

  double get _totalPrice =>
      shipments.fold<double>(0, (sum, s) => sum + s.totalPrice);

  bool get _allLocationsSet => shipments.every(
        (s) =>
    s.pickupAddress != null &&
        s.dropAddress != null &&
        s.pickupLat != null &&
        s.dropLat != null,
  );

  bool get _canConfirm {
    if (!_allLocationsSet) return false;
    if (selectedMode == BookingMode.schedule &&
        (mDate == null || mTime == null)) {
      return false;
    }
    return shipments.every(
          (s) => s.isPriced && s.totalAllocated >= s.quantity,
    );
  }

  // ─── Service Mode ─────────────────────────────────────────────────────────
  void _onServiceModeChanged(ServiceMode mode) {
    setState(() {
      _userHasSelected = true;
      _selectedMode = mode;
      _applyServiceMode(mode);
    });
  }

  void _applyServiceMode(ServiceMode mode) {
    switch (mode) {
      case ServiceMode.incity:
        mServiceType = 'in_city';
        break;
      case ServiceMode.outcity:
        mServiceType = 'out_city';
        break;
      case ServiceMode.rental:
        mServiceType = 'rental';
        break;
      case ServiceMode.international:
        mServiceType = 'international';
        break;
    }
  }

  // ─── Area / Cluster / Distance ────────────────────────────────────────────
  Future<void> _checkArea(
      String pinCode,
      String isFrom,
      int shipmentIndex,
      ) async {
    setState(() => isLoading = true);
    try {
      final response = await Provider.of<CheckAreaProvider>(
        context,
        listen: false,
      ).checkArea(pinCode);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
          if (data['success'] == true && data['exists'] == true) {
            if (isFrom == 'from') {
              shipments[shipmentIndex].mfromLable = 'Service is available';
            } else {
              shipments[shipmentIndex].isService = true;
              shipments[shipmentIndex].mtoLable = 'Service is available';
            }
          } else {
            shipments[shipmentIndex].isService = false;
            shipments[shipmentIndex].mfromLable = 'Service is not available';
          }
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Exception: $e');
    }
  }

  Future<void> _checkCluster(String pinCode1, String pinCode2) async {
    setState(() => isLoading = true);
    try {
      final response = await Provider.of<ClusterCheckProvider>(
        context,
        listen: false,
      ).clusterCheck(pinCode1, pinCode2);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
          sameCluster = data['sameCluster'] ?? false;
          if (sameCluster) {
            clusterId = data['cluster_id'].toString();
          }
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Exception: $e');
    }
  }

  Future<void> _checkDistance(String pinCode1, String pinCode2) async {
    try {
      final response = await Provider.of<DistanceProvider>(
        context,
        listen: false,
      ).fetchDistance(pinCode1, pinCode2);
      distance =
          double.parse(response['distance']!.replaceAll(' km', '')).toString();
      mDistance = response['distance']!;
      mDuration = response['duration']!;
    } catch (e) {
      print('Exception: $e');
    }
  }

  // ─── Shipment helpers ─────────────────────────────────────────────────────
  void _addShipment() {
    setState(() {
      final nextId = shipments.isEmpty ? 1 : shipments.last.id + 1;
      shipments.add(ShipmentData(id: nextId));
    });
  }

  void _removeShipment(int index) {
    if (shipments.length <= 1) return;
    setState(() => shipments.removeAt(index));
  }

  // ─── Booking Trip ─────────────────────────────────────────────────────────
  Future<void> _bookingTripe(BlukBookingTripRequest bookingRequest) async {
    setState(() => isBookingLoading = true);
    try {
      final response = await Provider.of<BlukBookingTripProvider>(
        context,
        listen: false,
      ).blukBookingTrip(bookingRequest);
      final responseData = json.decode(response.body);

      setState(() => isBookingLoading = false);

      if (responseData['success'] == true) {
        setState(() {
          shipments.clear();
          shipments.add(ShipmentData(id: 1));
          bookingMode = 'NOW';
          selectedMode = BookingMode.now;
          mServiceType = 'in_city';
          _selectedMode = ServiceMode.incity;
          _userHasSelected = false;
          _serviceModeKey = UniqueKey();
          _bookingModeKey = UniqueKey();
          clusterId = '';
          distance = '';
          mDistance = '';
          mDuration = '';
          vehicleType = '';
          weightUnit = '';
          mPrice = null;
          mDate = null;
          mTime = null;
          materialData = {};
        });
        if (responseData['success'] == true) {
          final bulkId = responseData['data']?['bulkOrderId'];
              showBulkWaitingSheet(bulkOrderId: bulkId,);
        }
      } else {
        AppSnackBar.showDialogMessage(
          context,
          title: 'Booking Failed',
          message: responseData['message'] ?? 'Something went wrong',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => isBookingLoading = false);
      AppSnackBar.showDialogMessage(
        context,
        title: 'Error',
        message: e.toString(),
        isError: true,
      );
    }
  }

  void showBulkWaitingSheet({
    required String bulkOrderId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return BulkWaitingBottomSheet(
            bulkId: bulkOrderId, // e.g. "BULK_12fb2908-..."
            headar: 'Searching for drivers',
            onClose: () => Navigator.pop(context),
            onViewDetails: () {
              Navigator.pop(context);
              // Navigate to bulk order detail screen
            },
          );
        },
      ),
    );
  }

  // ─── Confirm bulk ─────────────────────────────────────────────────────────
  void _confirmBulkBooking() {
    final incomplete = shipments
        .where(
          (s) =>
      s.pickupAddress == null ||
          s.dropAddress == null ||
          s.pickupLat == null ||
          s.dropLat == null,
    )
        .toList();

    if (incomplete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please set pickup & drop for all shipments (${incomplete.length} incomplete)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Schedule validation
    if (selectedMode == BookingMode.schedule &&
        (mDate == null || mTime == null)) {
      AppSnackBar.showDialogMessage(
        context,
        title: 'Missing Information',
        message: 'Please fill date and time',
        isError: true,
      );
      return;
    }

    final notFullyAllocated = shipments
        .where((s) => !s.isPriced || s.totalAllocated < s.quantity)
        .toList();
    if (notFullyAllocated.isNotEmpty) {
      AppSnackBar.showDialogMessage(
        context,
        title: 'Incomplete Allocation',
        message:
        'Please select vehicles for all shipments (${notFullyAllocated.length} remaining)',
        isError: true,
      );
      return;
    }

    if (mServiceType == 'out_city') {
      for (final s in shipments) {
        final materialName = (s.material ?? '').toString().trim();
        final weight = (s.weight ?? '').toString().trim();
        if (weight.isEmpty) {
          AppSnackBar.showDialogMessage(
            context,
            title: 'Missing Information',
            message: 'Please fill and Weight for all shipments',
            isError: true,
          );
          return;
        }
      }
    }

    // ── Build rows (one row per selected vehicle unit) ──────────────────────
    final List<Map<String, dynamic>> rows = [];

    for (final shipment in shipments) {
      for (int vIndex = 0; vIndex < shipment.availableVehicles.length; vIndex++) {
        final selectedCount = shipment.getSelectedCount(vIndex);
        if (selectedCount <= 0) continue;

        final vehicle = shipment.availableVehicles[vIndex];
        final vehicleTypeName = vehicle['name']?.toString() ??
            vehicle['vehicleType']?.toString() ??
            'Vehicle';
        final vehicleTypeId = vehicle['id'] ??
            vehicle['vehicle_type_id'] ??
            vehicle['vehicleId'] ??
            0;

        for (int i = 0; i < selectedCount; i++) {
          rows.add({
            'fromLocation': {
              'address': shipment.pickupAddress ?? '',
              'lat': shipment.pickupLat,
              'lng': shipment.pickupLng,
            },
            'toLocation': {
              'address': shipment.dropAddress ?? '',
              'lat': shipment.dropLat,
              'lng': shipment.dropLng,
            },
            'vehicleType': vehicleTypeName,
            'vehicle_type_id': vehicleTypeId is int
                ? vehicleTypeId
                : int.tryParse(vehicleTypeId.toString()) ?? 0,
            'cluster_id': int.tryParse(clusterId) ?? 0,
            'materialName': (shipment.material?.trim().isNotEmpty == true)
                ? shipment.material!.trim()
                : 'General',
            'weight': double.tryParse(shipment.weight ?? '0') ?? 0,
            'weightUnit': shipment.weightUnit,
            'service_type': mServiceType,
          });
        }
      }
    }

    if (rows.isEmpty) {
      AppSnackBar.showDialogMessage(
        context,
        title: 'No Vehicles Selected',
        message: 'Please allocate at least one vehicle',
        isError: true,
      );
      return;
    }

    final request = BlukBookingTripRequest(
      bookingMode: selectedMode == BookingMode.schedule ? 'LATER' : 'NOW',
      rows: rows,
    );

    if (PrefUtils.isLoggedIn()) {
      _bookingTripe(request);
    } else {
      PrefUtils.setRole('customer');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BulkOrdersScreen(),
                        ),
                      );
                    },
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
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildBookingModeSegment(),
                    const SizedBox(height: 16),

                    // ── Schedule date/time (with setState) ──────────────────
                    if (selectedMode == BookingMode.schedule) ...[
                      PickupDateTimeSelector(
                        minHoursFromNow: 3,
                        onDateChanged: (date) {
                          setState(() {
                            mDate = DateFormat('dd/MM/yyyy').format(date);
                          });
                        },
                        onTimeChanged: (time) {
                          setState(() {
                            final now = DateTime.now();
                            final dateTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              time.hour,
                              time.minute,
                            );
                            mTime = DateFormat('hh:mm a').format(dateTime);
                          });
                        },
                        txtMessage:
                        'Applies to the whole batch — all shipments start searching for a driver at this date and time.',
                      ),
                      const SizedBox(height: 16),
                    ],

                    ...List.generate(shipments.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildShipmentCard(index),
                      );
                    }),
                    _buildAddShipmentButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Booking Mode Segment ─────────────────────────────────────────────────
  Widget _buildBookingModeSegment() {
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
                  onTap: () => setState(() {
                    selectedMode = BookingMode.now;
                    bookingMode = 'NOW';
                    // clear schedule values when switching to Now
                    mDate = null;
                    mTime = null;
                  }),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: selectedMode == BookingMode.now
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
                          color: selectedMode == BookingMode.now
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Now',
                          style: TextStyle(
                            color: selectedMode == BookingMode.now
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
                  onTap: () => setState(() {
                    selectedMode = BookingMode.schedule;
                    bookingMode = 'Schedule';
                  }),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: selectedMode == BookingMode.schedule
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
                          color: selectedMode == BookingMode.schedule
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Schedule',
                          style: TextStyle(
                            color: selectedMode == BookingMode.schedule
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
          Text(
            selectedMode == BookingMode.now
                ? 'Every shipment starts searching for a driver immediately after you confirm.'
                : 'Choose a future date & time for the whole batch.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shipment Card ────────────────────────────────────────────────────────
  Widget _buildShipmentCard(int index) {
    final shipment = shipments[index];
    final bool hasLocations =
        shipment.pickupAddress != null && shipment.dropAddress != null;
    final bool isPriced = shipment.isPriced;
    final int allocated = shipment.totalAllocated;
    final int remaining = shipment.quantity - allocated;

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
                      color: isPriced
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPriced ? 'Priced' : 'Not priced',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPriced
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
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
          const SizedBox(height: 14),
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
                      builder: (_) => PickupLocationDialog('Pickup Location'),
                    );
                    if (result != null) {
                      setState(() {
                        shipment.pickupAddress = result['address'];
                        shipment.pickupLat = result['latitude'];
                        shipment.pickupLng = result['longitude'];
                        shipment.mPincode1 = result['pincode']?.toString();
                        _userHasSelected = false;
                        _selectedMode = null;
                        shipment.isPriced = false;
                        shipment.availableVehicles = [];
                        shipment.resetSelections();
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
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PickupLocationDialog('Drop Location'),
                    );
                    if (result != null) {
                      setState(() {
                        shipment.dropAddress = result['address'];
                        shipment.dropLat = result['latitude'];
                        shipment.dropLng = result['longitude'];
                        shipment.mPincode2 = result['pincode']?.toString();
                        _userHasSelected = false;
                        _selectedMode = null;
                        shipment.isPriced = false;
                        shipment.availableVehicles = [];
                        shipment.resetSelections();
                        if (shipment.mPincode1 != null &&
                            shipment.mPincode2 != null) {
                          _checkArea(shipment.mPincode2!, 'to', index);
                          _checkCluster(
                            shipment.mPincode1!,
                            shipment.mPincode2!,
                          );
                          _checkDistance(
                            shipment.mPincode1!,
                            shipment.mPincode2!,
                          );
                          Provider.of<PincodeCityProvider>(
                            context,
                            listen: false,
                          ).checkCity(
                            shipment.mPincode1!,
                            shipment.mPincode2!,
                          );
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
          if (hasLocations) ...[
            const SizedBox(height: 12),
            Consumer<PincodeCityProvider>(
              builder: (context, pincodeProvider, _) {
                if (pincodeProvider.errorMessage != null) {
                  return Column(
                    children: [
                      Text(
                        pincodeProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ServiceModeSelector(
                        key: _serviceModeKey,
                        selectedMode: _selectedMode,
                        onChanged: _onServiceModeChanged,
                      ),
                    ],
                  );
                }
                final suggested = pincodeProvider.suggestedMode;
                if (!_userHasSelected &&
                    suggested != null &&
                    _selectedMode != suggested) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _userHasSelected) return;
                    setState(() {
                      _selectedMode = suggested;
                      _applyServiceMode(suggested);
                    });
                  });
                }
                return ServiceModeSelector(
                  key: _serviceModeKey,
                  selectedMode: _selectedMode,
                  onChanged: _onServiceModeChanged,
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  hint: 'Material (optional)',
                  value: shipment.material,
                  onChanged: (v) => setState(() => shipment.material = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  hint: 'Weight',
                  value: shipment.weight,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => shipment.weight = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: shipment.weightUnit,
                      isExpanded: true,
                      items: ['KG', 'TON', 'LB']
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
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
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (shipment.quantity > 1) {
                      setState(() {
                        shipment.quantity--;
                        shipment.clampSelectionsToQuantity();
                      });
                    }
                  },
                  icon: const Icon(Icons.remove, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34),
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
                  constraints: const BoxConstraints(minWidth: 34),
                ),
              ],
            ),
          ),
          if (isPriced) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '~${shipment.distance ?? '0'} km · Select vehicles — $allocated of ${shipment.quantity} allocated',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (remaining > 0)
                  Text(
                    '$remaining more needed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE85D04),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Fully allocated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(shipment.availableVehicles.length, (vIndex) {
              final vehicle = shipment.availableVehicles[vIndex];
              final selected = shipment.getSelectedCount(vIndex);
              final price = (vehicle['price'] as num?)?.toDouble() ?? 0.0;
              final payload =
                  vehicle['max_payload_kg'] ?? vehicle['name'] ?? '0';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected > 0
                        ? const Color(0xFFE85D04)
                        : const Color(0xFFE5E7EB),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: selected > 0
                      ? const Color(0xFFFFF7ED)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 22, color: Color(0xFFE85D04)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$payload kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₹${NumberFormat('#,##0').format(price)} /vehicle',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: selected > 0
                                ? () {
                              setState(() {
                                shipment.setSelectedCount(
                                    vIndex, selected - 1);
                              });
                            }
                                : null,
                            icon: const Icon(Icons.remove, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                          ),
                          Text(
                            '$selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            onPressed: remaining > 0
                                ? () {
                              setState(() {
                                shipment.setSelectedCount(
                                    vIndex, selected + 1);
                              });
                            }
                                : null,
                            icon: const Icon(Icons.add, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (hasLocations) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  final s = shipments[index];
                  final weightStr = (s.weight ?? '').trim();
                  final weightValue = double.tryParse(weightStr);

                  if (weightStr.isEmpty ||
                      weightValue == null ||
                      weightValue <= 0) {
                    AppSnackBar.showDialogMessage(
                      context,
                      title: 'Missing Information',
                      message: 'Please enter a valid weight',
                      isError: true,
                    );
                    return;
                  }

                  setState(() => isLoading = true);
                  try {
                    final response =
                    await Provider.of<FareCalculateProvider>(
                      context,
                      listen: false,
                    ).fetchFareCalculate(
                      s.pickupLat?.toString() ?? '',
                      s.pickupLng?.toString() ?? '',
                      s.dropLat?.toString() ?? '',
                      s.dropLng?.toString() ?? '',
                      weightStr,
                      clusterId,
                      mServiceType,
                      bookingMode,
                    );

                    if (response != null &&
                        response['status'] == 'success') {
                      final data = response['data'];
                      setState(() {
                        shipment.distance =
                            data['distance_km']?.toString() ?? '0';
                        shipment.availableVehicles =
                        List<Map<String, dynamic>>.from(
                            data['types'] ?? []);
                        shipment.isPriced = true;
                        shipment.resetSelections();
                        if (shipment.availableVehicles.isNotEmpty) {
                          shipment.pricePerVehicle = shipment
                              .availableVehicles.first['price']
                              ?.toString();
                        }
                      });
                    } else {
                      AppSnackBar.showDialogMessage(
                        context,
                        title: 'Fare Error',
                        message: response?['message'] ??
                            'Unable to get prices',
                        isError: true,
                      );
                    }
                  } catch (e) {
                    AppSnackBar.showDialogMessage(
                      context,
                      title: 'Error',
                      message: e.toString(),
                      isError: true,
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF7ED),
                  foregroundColor: const Color(0xFFE85D04),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFE85D04),
                  ),
                )
                    : const Text(
                  'Get Prices',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    String? value,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection =
          TextSelection.collapsed(offset: value?.length ?? 0),
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _locationField(String text, {bool isSelected = false}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
        border: Border.all(
          color:
          isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: isSelected
                ? const Color(0xFF16A34A)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF9CA3AF),
                fontSize: 13.5,
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

  Widget _buildAddShipmentButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
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
    final pricedCount = _pricedCount;
    final totalNeeded = _totalVehiclesNeeded;
    final totalAllocated = _totalAllocated;
    final totalPrice = _totalPrice;
    final canConfirm = _canConfirm;

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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pricedCount of ${shipments.length} route(s) priced · $totalAllocated of $totalNeeded vehicle(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
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
                    Text(
                      '₹${NumberFormat('#,##0').format(totalPrice)}',
                      style: const TextStyle(
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
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed:
              canConfirm && !isBookingLoading ? _confirmBulkBooking : null,
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
              child: isBookingLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Row(
                children: [
                  Text(
                    'Confirm Bulk Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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

// ─── Shipment Data Model ────────────────────────────────────────────────────
class ShipmentData {
  final int id;
  String? pickupAddress;
  double? pickupLat;
  double? pickupLng;
  String? dropAddress;
  double? dropLat;
  double? dropLng;
  String? mPincode1;
  String? mPincode2;
  String mfromLable = '';
  String mtoLable = '';
  bool isService = false;
  bool? isInCity;
  bool isPriced = false;
  String? material;
  String? weight;
  String weightUnit = 'KG';
  int quantity = 1;
  String? distance;
  String? pricePerVehicle;

  List<Map<String, dynamic>> availableVehicles = [];

  final Map<int, int> _selectedCounts = {};

  ShipmentData({required this.id});

  int getSelectedCount(int vehicleIndex) =>
      _selectedCounts[vehicleIndex] ?? 0;

  void setSelectedCount(int vehicleIndex, int count) {
    if (count <= 0) {
      _selectedCounts.remove(vehicleIndex);
    } else {
      _selectedCounts[vehicleIndex] = count;
    }
  }

  void resetSelections() {
    _selectedCounts.clear();
  }

  int get totalAllocated =>
      _selectedCounts.values.fold(0, (sum, c) => sum + c);

  double get totalPrice {
    double sum = 0;
    _selectedCounts.forEach((index, count) {
      if (index >= 0 && index < availableVehicles.length) {
        final price =
            (availableVehicles[index]['price'] as num?)?.toDouble() ?? 0.0;
        sum += price * count;
      }
    });
    return sum;
  }

  void clampSelectionsToQuantity() {
    int current = totalAllocated;
    if (current <= quantity) return;

    final keys = _selectedCounts.keys.toList()..sort();
    for (final key in keys.reversed) {
      if (current <= quantity) break;
      final excess = current - quantity;
      final canReduce = _selectedCounts[key]!;
      if (canReduce <= excess) {
        current -= canReduce;
        _selectedCounts.remove(key);
      } else {
        _selectedCounts[key] = canReduce - excess;
        current = quantity;
      }
    }
  }
}