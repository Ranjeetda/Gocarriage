import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/cluster_check_provider.dart';
import 'package:gocarriage_universal/resource/app_snack_bar.dart';
import 'package:gocarriage_universal/resource/image_paths.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/screens/dashboardScreen/vehicle_selection_sheet.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider_service/URLS.dart';
import '../../provider_service/booking_trip.dart';
import '../../provider_service/bottom_navigation_provider.dart';
import '../../provider_service/check_area_provider.dart';
import '../../provider_service/distance_provider.dart';
import '../../provider_service/driver_booing_request_provider.dart';
import '../../provider_service/fare_calculate_provider.dart';
import '../../provider_service/myrides_provider.dart';
import '../../provider_service/near_by_vehicle_provider.dart';
import '../../provider_service/pincode_city_provider.dart';
import '../../provider_service/place_details_provider.dart';
import '../../resource/Utils.dart';
import '../dialogBox/app_message_dialog.dart';
import '../dialogBox/pickup_location_dialog.dart';
import '../dialogBox/select_vehicle_type_sheet.dart';
import '../dialogBox/special_instructions_dialog.dart';
import '../widgets/advance_payment_info_banner.dart';
import '../widgets/material_details_form.dart';
import '../widgets/mode_button.dart';
import '../widgets/pickup_date_time_selector.dart';
import '../widgets/selectable_scroll_box.dart';
import '../auth/login_screen.dart';
import '../dialogBox/driver_bottom_sheet.dart';
import '../model/RecentLocation.dart';
import '../model/booking_trip_request.dart';
import '../model/location_modal.dart';
import '../model/special_requirements.dart';
import 'package:http/http.dart' as http;

import '../widgets/service_mode_selector.dart';
import '../widgets/status_dialog.dart';

class BookVehicleScreen extends StatefulWidget {
  const BookVehicleScreen({super.key});

  @override
  State<BookVehicleScreen> createState() => _BookVehicleScreenState();
}

class _BookVehicleScreenState extends State<BookVehicleScreen> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final searchClusterController = TextEditingController();

  bool isLoading = false;
  bool isBookingLoading = false;
  bool sameCluster = false;

  String? fromLatitude;
  String? fromLongitude;

  String? toLatitude;
  String? toLongitude;

  String? fromAddress, toAddress;
  String bookingMode = 'NOW';
  String clusterId = "";
  String distance = "";
  String mDistance = "";
  String mDuration = "";
  String mServiceType = "";

  String vehicleType = "";
  String weightUnit = "";

  String mfromLable = "";
  String mtoLable = "";

  String? mPrice;
  String selectedRole = 'Customer';
  String mButtonName = 'Find City Vehicles';
  String mLocation = "";

  String? mPincode1;
  String? mPincode2;

  String? mDate;
  String? mTime;

  BookingTripRequest? globalBookingRequest;
  Map<String, dynamic> materialData = {};
  ServiceMode? _selectedMode;
  bool _userHasSelected = false;
  BookingMode selectedMode = BookingMode.now;

  // Keys to force rebuild of selectors
  Key _serviceModeKey = UniqueKey();
  Key _bookingModeKey = UniqueKey();

  int currentPage = 1;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    localData();
    if (PrefUtils.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bookingAllRideService(page: currentPage);
      });
    }
  }

  // ─── HELPER METHODS ───────────────────────────────────────────────────────
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
        mServiceType = "in_city";
        mButtonName = 'Find City Vehicles';
        break;
      case ServiceMode.outcity:
        mServiceType = "out_city";
        mButtonName = 'Find OutCity Vehicles';
        break;
      case ServiceMode.rental:
        mServiceType = "rental";
        mButtonName = 'Find Rentals';
        break;
      case ServiceMode.international:
        mServiceType = "international";
        mButtonName = 'Get International Quote';
        break;
    }
  }

  Future<void> _bookingAllRideService({
    int page = 1,
    bool isRefresh = false,
  }) async {
    if (isRefresh) currentPage = 1;
    try {
      await Provider.of<MyridesProvider>(context, listen: false).validateList(
        endpoint: URLS.bookingAllRide,
        page: currentPage,
        limit: limit,
        append: !isRefresh && page > 1,
      );
    } catch (error) {
      AppSnackBar.showDialogMessage(
        context,
        title: 'Something went wrong!',
        message: error.toString(),
        isError: true,
      );
    }
  }

  void showWaitingForDriver() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DriverBottomSheet();
      },
    );
  }

  Future<void> localData() async {
    globalBookingRequest = await PrefUtils.getBookingRequest();

    if (globalBookingRequest != null) {
      fromController.text = globalBookingRequest!.fromLocation.address;
      toController.text = globalBookingRequest!.toLocation.address;
      vehicleType = globalBookingRequest!.vehicleType;
      weightUnit = globalBookingRequest!.weightUnit!;
      toLatitude = globalBookingRequest!.toLocation.lat.toString();
      toLongitude = globalBookingRequest!.toLocation.lng.toString();
      fromLatitude = globalBookingRequest!.fromLocation.lat.toString();
      fromLongitude = globalBookingRequest!.fromLocation.lng.toString();
      mPincode1 = PrefUtils.getpinCode1();
      mPincode2 = PrefUtils.getpinCode2();
      _checkCluster(PrefUtils.getpinCode1(), PrefUtils.getpinCode2());
      _checkDistance(PrefUtils.getpinCode1(), PrefUtils.getpinCode2());

      if (mPincode1 != null &&
          mPincode2 != null &&
          mPincode1!.isNotEmpty &&
          mPincode2!.isNotEmpty) {
        final provider = Provider.of<PincodeCityProvider>(
          context,
          listen: false,
        );
        provider.checkCity(mPincode1!, mPincode2!);
      }

      print(globalBookingRequest!.weight);
    }
  }

  Future<void> _checkArea(String pinCode) async {
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
            mLocation = " 🟢 ${searchClusterController.text} ";
            mfromLable = "Service is available";
          });
        } else {
          setState(() {
            mLocation = " 🔴 ${searchClusterController.text} ";
            mfromLable = "Service is not available";
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

  Future<void> _checkCluster(String pinCode1, String pinCode2) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Provider.of<ClusterCheckProvider>(
        context,
        listen: false,
      ).clusterCheck(pinCode1, pinCode2);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
          sameCluster = data['sameCluster'];
          if (sameCluster == true) {
            mtoLable = "Service is available";
            mfromLable = "Service is available";
            clusterId = data['cluster_id'].toString();
          } else {
            mtoLable = "Service is not available";
            mfromLable = "Service is not available";
          }
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception${e.toString()}");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkDistance(String pinCode1, String pinCode2) async {
    try {
      final response = await Provider.of<DistanceProvider>(
        context,
        listen: false,
      ).fetchDistance(pinCode1, pinCode2);
      distance =
          double.parse(response['distance']!.replaceAll(" km", "")).toString();
      mDistance = response['distance']!;
      mDuration = response['duration']!;
      print("distance ${distance}");
    } catch (e) {
      print("Exception${e.toString()}");
    }
  }

  // ─── BOOKING TRIP (Full Screen Refresh) ───────────────────────────────────
  Future<void> _bookingTripe(BookingTripRequest bookingRequest) async {
    setState(() {
      isBookingLoading = true;
    });

    try {
      http.Response response = await Provider.of<BookingTrip>(
        context,
        listen: false,
      ).bookingTrip(bookingRequest);

      var responseData = json.decode(response.body);

      setState(() {
        isBookingLoading = false;
      });

      if (responseData['success'] == true) {
        // ── Full screen refresh ──────────────────────────────────────────────
        setState(() {
          // Controllers
          fromController.clear();
          toController.clear();
          searchClusterController.clear();

          // Location data
          fromLatitude = null;
          fromLongitude = null;
          toLatitude = null;
          toLongitude = null;
          fromAddress = null;
          toAddress = null;
          mPincode1 = null;
          mPincode2 = null;
          mfromLable = "";
          mtoLable = "";
          mLocation = "";

          // Booking Mode reset
          bookingMode = 'NOW';
          selectedMode = BookingMode.now;

          // Service Type reset
          mServiceType = "";
          _selectedMode = null;
          _userHasSelected = false;
          mButtonName = 'Find City Vehicles';

          // Force selectors to rebuild completely
          _serviceModeKey = UniqueKey();
          _bookingModeKey = UniqueKey();

          // Other booking state
          clusterId = "";
          distance = "";
          mDistance = "";
          mDuration = "";
          vehicleType = "";
          weightUnit = "";
          mPrice = null;
          mDate = null;
          mTime = null;
          materialData = {};
          globalBookingRequest = null;
        });

        // Clear persisted data
        PrefUtils.setPinCode1("");
        PrefUtils.setPinCode2("");
        PrefUtils.clearBookingRequest();

        // Refresh recent rides
        if (PrefUtils.isLoggedIn()) {
          _bookingAllRideService(page: 1, isRefresh: true);
        }

        showWaitingForDriver();
      } else {
        AppSnackBar.showDialogMessage(
          context,
          title: "Booking Failed",
          message: responseData['message'] ?? "Something went wrong",
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        isBookingLoading = false;
      });

      AppSnackBar.showDialogMessage(
        context,
        title: "Error",
        message: e.toString(),
        isError: true,
      );
    }
  }

  // ─── NEARBY VEHICLE ───────────────────────────────────────────────────────
  void nearByVehicleData(String bookingMode, String lat, String lng) async {
    setState(() {
      isBookingLoading = true;
    });

    try {
      if (bookingMode == 'Schedule') {
        final response = await Provider.of<NearByVehicleProvider>(
          context,
          listen: false,
        ).fetchVehicleType(bookingMode, lat, lng);

        setState(() {
          isBookingLoading = false;
        });

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return SelectVehicleTypeSheet(
              from_lat: fromLatitude!,
              from_lng: fromLongitude!,
              to_lat: toLatitude!,
              to_lng: toLongitude!,
              weight_kg: materialData['weight'] ?? '0',
              cluster_id: clusterId,
              service_type: mServiceType,
              booking_mode: bookingMode,
              mDistance: mDistance,
              mDuration: mDuration,
              fromName: fromAddress!,
              toName: toAddress!,
            );
          },
        ).then((result) {
          if (result != null) {
            DateTime? pickupDate;

            if (mDate != null && mDate!.isNotEmpty) {
              final parts = mDate!.split('/');
              pickupDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }

            globalBookingRequest = BookingTripRequest(
              bookingMode: bookingMode == 'Schedule' ? 'LATER' : bookingMode,
              tripType: "Single",
              vehicleType: result['vehicleType'],
              vehicleTypeId: result['vehicleId'].toString(),
              serviceType: mServiceType,
              pricingMode: result['mode']=='negotiate'?'negotiable':result['mode'],
              pickupDate: pickupDate,
              pickupTime: mTime,
              fromLocation: LocationModal(
                address: fromController.text.trim(),
                lat: double.parse(fromLatitude!),
                lng: double.parse(fromLongitude!),
              ),
              toLocation: LocationModal(
                address: toController.text.trim(),
                lat: double.parse(toLatitude!),
                lng: double.parse(toLongitude!),
              ),
              materialName: materialData['material_name'] ?? "General",
              weight: double.tryParse(materialData['weight']?.toString() ?? "0") ?? 0,
              weightUnit: materialData['unit'] ?? "KG",
              customerId: int.parse(PrefUtils.getUserId()),
              specialRequirements: SpecialRequirements.fromJson(
                materialData['specialRequirements'] ?? {},
              ),
            );
            if (PrefUtils.isLoggedIn()) {
              _bookingTripe(globalBookingRequest!);
            } else {
              PrefUtils.saveBookingRequest(globalBookingRequest!);
              PrefUtils.setRole('customer');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
          }
        });
      } else {
        final response = await Provider.of<NearByVehicleProvider>(
          context,
          listen: false,
        ).fetchNearByVehicle(bookingMode, lat, lng);

        final vehicleTypeIds = List<int>.from(
          response?['data']?['vehicleTypeIds'] ?? [],
        );

        setState(() {
          isBookingLoading = false;
        });

        if (vehicleTypeIds.isEmpty) {
          final message = response?['message'] ?? "No eligible nearby drivers";

          AppSnackBar.showErrorWithRetry(
            context,
            title: "No Vehicles Found",
            message: message,
            onRetry: () {
              nearByVehicleData(
                bookingMode,
                fromLatitude.toString(),
                fromLongitude.toString(),
              );
            },
          );
          return;
        }

        showVehicleBottomSheet(
          context,
          fromLatitude!,
          fromLongitude!,
          toLatitude!,
          toLongitude!,
          materialData['weight'] ?? '0',
          clusterId,
          mServiceType,
          bookingMode,
          mDistance,
          mDuration,
        );
      }
    } catch (e) {
      setState(() {
        isBookingLoading = false;
      });

      AppSnackBar.showErrorWithRetry(
        context,
        title: "Something went wrong",
        message: e.toString(),
        onRetry: () {
          nearByVehicleData(
            bookingMode,
            fromLatitude.toString(),
            fromLongitude.toString(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<DriverBooingRequestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            SelectableScrollBox(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBookingCard(),
                    const SizedBox(height: 16),
                    _buildBanner(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildWhyChooseUs(),
                    const SizedBox(height: 16),
                    Consumer<MyridesProvider>(
                      builder: (context, provider, _) {
                        final upcomingRides = provider.cureentRideListData;
                        return _buildRecentBookings(upcomingRides);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildNeedHelp(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOOKING CARD ─────────────────────────────────────────────────────────
  Widget _buildBookingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

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

                if (!_userHasSelected &&
                    pincodeProvider.suggestedMode != null &&
                    _selectedMode != pincodeProvider.suggestedMode) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _userHasSelected) return;
                    setState(() {
                      _selectedMode = pincodeProvider.suggestedMode;
                      _applyServiceMode(_selectedMode!);
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

            const SizedBox(height: 16),
            BookingModeSelector(
              key: _bookingModeKey,
              initialMode: selectedMode,
              onChanged: (mode) {
                setState(() {
                  selectedMode = mode;
                  bookingMode =
                  "${mode.name[0].toUpperCase()}${mode.name.substring(1)}";
                  print(bookingMode);
                });
              },
            ),
            const SizedBox(height: 16),

            _locationRow(),

            if (selectedMode == BookingMode.schedule) ...[
              const SizedBox(height: 16),
              PickupDateTimeSelector(
                minHoursFromNow: 3,
                onDateChanged: (date) {
                  mDate = DateFormat('dd/MM/yyyy').format(date);
                },
                onTimeChanged: (time) {
                  final now = DateTime.now();
                  final dateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                  mTime = DateFormat('hh:mm a').format(dateTime);
                }, txtMessage: 'Scheduled pickup must be at least 3 hours from now.',
              ),
              const SizedBox(height: 16),
              const AdvancePaymentInfoBanner(),
            ],

            if (mServiceType == 'out_city') ...[
              const SizedBox(height: 16),
              MaterialDetailsForm(
                onChanged: (values) {
                  setState(() {
                    materialData = values;
                  });
                },
              ),
            ],

            const SizedBox(height: 16),
            GestureDetector(
              onTap: openSpecialInstructionsDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Add Special Instructions (Optional)",
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _findVehiclesButton(),
          ],
        ),
      ),
    );
  }

  Future<void> openSpecialInstructionsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SpecialInstructionsDialog(),
    );

    if (result != null) {
      final int loadingTime = result['loadingTime'] as int;
      final int unloadingTime = result['unloadingTime'] as int;
      final TimeOfDay? noEntryFrom = result['noEntryFrom'] as TimeOfDay?;
      final TimeOfDay? noEntryTo = result['noEntryTo'] as TimeOfDay?;
      final String notes = result['notes'] as String;

      print('Loading: $loadingTime hrs');
      print('Unloading: $unloadingTime hrs');
      print('No Entry From: ${Utils.formatTime(noEntryFrom)}');
      print('No Entry To: ${Utils.formatTime(noEntryTo)}');
      print('Notes: $notes');
    }
  }

  Widget _locationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 14),
            const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 22),
            ...List.generate(
              5,
                  (_) => Container(
                width: 2,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.grey.shade300,
              ),
            ),
            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 22),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _locationField(
                label: 'Pickup Location',
                controller: fromController,
                serviceLabel: mfromLable,
                onClear: () {
                  setState(() {
                    mfromLable = '';
                    mPincode1 = null;
                    fromController.clear();
                  });
                },
              ),
              const SizedBox(height: 10),
              _locationField(
                label: 'Drop Location',
                controller: toController,
                serviceLabel: mtoLable,
                onClear: () {
                  setState(() {
                    mtoLable = '';
                    mPincode2 = null;
                    toController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationField({
    required String label,
    required TextEditingController controller,
    required String serviceLabel,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, TextEditingValue value, child) {
            return GestureDetector(
              onTap: () => _openLocationBottomSheet(
                label == 'Pickup Location' ? 'Pickup Location' : 'Drop Location',
                controller,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.text.isEmpty
                            ? 'Enter ${label.toLowerCase()}'
                            : value.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: value.text.isEmpty ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (value.text.isNotEmpty)
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      )
                    else
                      const Icon(
                        Icons.my_location,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── FIND VEHICLES BUTTON ─────────────────────────────────────────────────
  Widget _findVehiclesButton() {
    return Consumer<PincodeCityProvider>(
      builder: (context, pincodeProvider, _) {
        final bool isPincodeLoading = pincodeProvider.isLoading;
        final bool showLoader = isBookingLoading || isPincodeLoading;

        final bool isEnabled =
            mServiceType.isNotEmpty && !isPincodeLoading && !isBookingLoading;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isEnabled ? const Color(0xFF2563EB) : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: isEnabled
                ? () {
              if (fromController.text.isEmpty) {
                AppSnackBar.showDialogMessage(
                  context,
                  title: "Missing Information",
                  message: "Please search pickup location.",
                  isError: true,
                );
                return;
              }
              if (toController.text.isEmpty) {
                AppSnackBar.showDialogMessage(
                  context,
                  title: "Missing Information",
                  message: "Please search drop location.",
                  isError: true,
                );
                return;
              }
              if (bookingMode == 'Schedule' &&
                  (mDate == null || mTime == null)) {
                AppSnackBar.showDialogMessage(
                  context,
                  title: "Missing Information",
                  message: "Please fill date and time",
                  isError: true,
                );
                return;
              }
              if (mServiceType == 'out_city') {
                final materialName =
                (materialData['material_name'] ?? '')
                    .toString()
                    .trim();
                final weight =
                (materialData['weight'] ?? '').toString().trim();

                if (materialName.isEmpty || weight.isEmpty) {
                  AppSnackBar.showDialogMessage(
                    context,
                    title: "Missing Information",
                    message: "Please fill Material Name and Weight",
                    isError: true,
                  );
                  return;
                }
              }

              nearByVehicleData(
                bookingMode,
                fromLatitude.toString(),
                fromLongitude.toString(),
              );
            }
                : null,
            child: showLoader
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              mButtonName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── BANNER ───────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Image.asset(ImagePaths.banner, fit: BoxFit.fill),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Quick Booking',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'My Bookings',
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFF0FDF4),
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Live Tracking',
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
      },
      {
        'icon': Icons.calculate_outlined,
        'label': 'Rate Calculator',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              switch (index) {
                case 0:
                  print("Quick Booking Clicked");
                  break;
                case 1:
                  context.read<BottomNavigationProvider>().changeIndex(1);
                  break;
                case 2:
                  print("Live Tracking Clicked");
                  break;
                case 3:
                  print("Rate Calculator Clicked");
                  break;
              }
            },
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: a['bg'] as Color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    a['icon'] as IconData,
                    color: a['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── WHY CHOOSE US ────────────────────────────────────────────────────────
  Widget _buildWhyChooseUs() {
    final items = [
      {
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF2563EB),
        'title': 'Verified Vehicles',
        'sub': '100% Verified & Trusted',
      },
      {
        'icon': Icons.security_outlined,
        'color': const Color(0xFF16A34A),
        'title': 'Safe & Secure',
        'sub': 'Your Safety is Our Priority',
      },
      {
        'icon': Icons.wifi_tethering,
        'color': const Color(0xFFEA580C),
        'title': 'Live Tracking',
        'sub': 'Track in Real-time',
      },
      {
        'icon': Icons.local_offer_outlined,
        'color': const Color(0xFFDB2777),
        'title': 'Best Prices',
        'sub': 'Transparent Pricing',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Choose Us',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: items.map((item) {
              return Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item['sub'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── RECENT BOOKINGS ──────────────────────────────────────────────────────
  Widget _buildRecentBookings(List<dynamic> rides) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<BottomNavigationProvider>().changeIndex(2);
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                return _recentBookingTile(
                  from: rides[index]['fromLocation']['address'],
                  to: rides[index]['toLocation']['address'],
                  date: '--',
                  time: '--',
                  status: rides[index]['status'],
                  price: "₹${rides[index]['estimated_price'] ?? '--'}",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentBookingTile({
    required String from,
    required String to,
    required String date,
    required String time,
    required String status,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFF2563EB),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                to,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              time,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const Text(
              'View Details',
              style: TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
            ),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
      ],
    );
  }

  // ─── NEED HELP ────────────────────────────────────────────────────────────
  Widget _buildNeedHelp() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Our support team is ready to assist you',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, size: 14),
            label: const Text(
              'Contact Support',
              style: TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCATION BOTTOM SHEET ────────────────────────────────────────────────
  Future<void> _openLocationBottomSheet(
      String title,
      TextEditingController controller,
      ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PickupLocationDialog(title),
    );

    if (result == null) return;

    setState(() {
      if (title == 'Pickup Location') {
        fromAddress = result['address']?.toString() ??
            result['formatted_address']?.toString() ??
            result['name']?.toString() ??
            "";
        fromLatitude = result['latitude'].toString();
        fromLongitude = result['longitude'].toString();
        mPincode1 = result['pincode'].toString();

        if (mPincode1 != null && mPincode2 != null) {
          _checkArea(mPincode1!);
        }
      } else {
        toAddress = result['address']?.toString() ??
            result['formatted_address']?.toString() ??
            result['name']?.toString() ??
            "";
        toLatitude = result['latitude'].toString();
        toLongitude = result['longitude'].toString();
        mPincode2 = result['pincode'].toString();
        if (mPincode1 != null && mPincode2 != null) {
          _checkCluster(mPincode1!, mPincode2!);
          _checkDistance(mPincode1!, mPincode2!);
          final provider = Provider.of<PincodeCityProvider>(
            context,
            listen: false,
          );
          provider.checkCity(mPincode1!, mPincode2!);
        }
      }
      controller.text = result['address'] ?? '';
    });
  }

  // ─── VEHICLE BOTTOM SHEET ─────────────────────────────────────────────────
  Future<void> showVehicleBottomSheet(
      BuildContext context,
      final String from_lat,
      final String from_lng,
      final String to_lat,
      final String to_lng,
      final String weight_kg,
      final String cluster_id,
      final String service_type,
      final String booking_mode,
      final String mDistance,
      final String mDuration,
      ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: VehicleSelectionSheet(
            from_lat: from_lat,
            from_lng: from_lng,
            to_lat: to_lat,
            to_lng: to_lng,
            weight_kg: weight_kg,
            cluster_id: cluster_id,
            service_type: service_type,
            booking_mode: booking_mode,
            mDistance: mDistance,
            mDuration: mDuration,
            fromName: fromAddress!,
            toName: toAddress!,
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        vehicleType = result["vehicleType"] ?? "";
        mPrice = result["price"]?.toString() ?? "0";

        globalBookingRequest = BookingTripRequest(
          bookingMode: bookingMode,
          tripType: "Single",
          vehicleType: vehicleType,
          fromLocation: LocationModal(
            address: fromController.text.trim(),
            lat: double.parse(fromLatitude!),
            lng: double.parse(fromLongitude!),
          ),
          toLocation: LocationModal(
            address: toController.text.trim(),
            lat: double.parse(toLatitude!),
            lng: double.parse(toLongitude!),
          ),
          materialName: materialData['material_name'] ?? "General",
          weight:
          double.tryParse(materialData['weight']?.toString() ?? "0") ?? 0,
          weightUnit: materialData['unit'] ?? 'KG',
          customerId: int.parse(PrefUtils.getUserId()),
          specialRequirements: materialData['specialRequirements'] ?? {},
          serviceType: mServiceType,
        );

        if (PrefUtils.isLoggedIn()) {
          _bookingTripe(globalBookingRequest!);
        } else {
          PrefUtils.saveBookingRequest(globalBookingRequest!);
          PrefUtils.setRole('customer');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      });
    }
  }
}