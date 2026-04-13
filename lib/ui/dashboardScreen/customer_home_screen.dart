import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/cluster_check_provider.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/ui/auth/login_screen.dart';
import 'package:gocarriage_universal/ui/dashboardScreen/vehicle_selection_sheet.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:provider/provider.dart';
import '../../eventModel/notification_event.dart';
import '../../provider_service/booking_provider.dart';
import '../../provider_service/booking_trip.dart';
import '../../provider_service/check_area_provider.dart';
import '../../provider_service/driver_booing_request_provider.dart';
import '../../provider_service/place_details_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import '../dialogBox/driver_bottom_sheet.dart';
import '../dialogBox/login_register_dialog.dart';
import '../dialogBox/special_instructions_dialog.dart';
import '../model/booking_trip_request.dart';
import '../model/grid_item.dart';
import '../model/location_modal.dart';
import '../model/vehicle_model.dart';
import 'package:http/http.dart' as http;

import '../pleacePickerScreen/place_picker_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final  fromController = TextEditingController();
  final  toController = TextEditingController();
  final  pickupDateController = TextEditingController();
  final  pickupTimeController = TextEditingController();
  final  searchClusterController = TextEditingController();
  final  metrialController = TextEditingController();
  final  weightController = TextEditingController();

  bool isWithinCity = true;
  bool isBookingType = true;
  bool isGettingLocation = false;
  bool isLoading = false;
  bool isBookingLoading = false;
  bool sameCluster = false;
  bool isShow = false;
  String? fromLatitude;
  String? fromLongitude;
  String? toLatitude;
  String? toLongitude;

  String bookingMode = "NOW";
  String vehicleType = "";
  String mfromLable = "";
  String mtoLable = "";
  String? mPrice;

  String mLocation = "";
  String? mPincode1;
  String? mPincode2;
  BookingTripRequest? globalBookingRequest;

  String? selectedRequirement;
  final Map<String, bool> specialRequirements = {
    "Container": false,
    "Extra Length": false,
    "Covered": false,
    "Hydraulic": false,
    "Extra Large": false,
  };
  String selectedUnit = "KG";
  final List<String> units = ["KG", "TON", "GM"];

  @override
  void initState() {
    super.initState();
    localData();
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
      toLatitude = globalBookingRequest!.toLocation.lat.toString();
      toLongitude = globalBookingRequest!.toLocation.lng.toString();
      fromLatitude = globalBookingRequest!.fromLocation.lat.toString();
      fromLongitude = globalBookingRequest!.fromLocation.lng.toString();
      mPincode1 = PrefUtils.getpinCode1();
      mPincode2 = PrefUtils.getpinCode2();
      _checkCluster(PrefUtils.getpinCode1(), PrefUtils.getpinCode2());
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
        print("_checkArea ${data['message']}");
      }
    } catch (e) {
      setState(() {
        print("Exception${e.toString()}");
        isLoading = false;
      });

      // Utils.showErrorMessage(context, e.toString());
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
        });
        sameCluster = data['sameCluster'];
        isShow = true;
        if (sameCluster == true) {
          mtoLable = "Service is available";
          mfromLable = "Service is available";
          //Utils.showCustomToast(context, "Service is available");
        } else {
          mtoLable = "Service is not available";
          mfromLable = "Service is not available";
          // Utils.showCustomToast(context, "Service is not available");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print("_checkCluster ${data['message']}");
      }
    } catch (e) {
      print("Exception${e.toString()}");
      isLoading = false;

      // Utils.showErrorMessage(context, e.toString());
    }
  }

  Future<void> _bookingTripe(BookingTripRequest bookingRequest) async {
    setState(() {
      isBookingLoading = true;
    });

    http.Response response = await Provider.of<BookingTrip>(
      context,
      listen: false,
    ).bookingTrip(bookingRequest);
    var responseData = json.decode(response.body);
    setState(() {
      isBookingLoading = false;
    });

    if (responseData['success'] == true) {
      setState(() {
        fromController.text = "";
        toController.text = "";
        vehicleType = "";
        mtoLable = "";
        mfromLable = "";
        PrefUtils.setPinCode1("");
        PrefUtils.setPinCode2("");
        PrefUtils.clearBookingRequest();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() {
        isBookingLoading = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Booking failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<DriverBooingRequestProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Image.asset(ImagePaths.banner),
                  const SizedBox(height: 10),
                  bookingTypeToggle(),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        serviceTypeRadio(),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: locationFields(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        bookingMode == "SCHEDULE"
                            ? dateTimeFields()
                            : SizedBox(),
                        bookingMode == "SCHEDULE"
                            ? const SizedBox(height: 16)
                            : SizedBox(),
                        bookingMode == "SCHEDULE"
                            ? materialWeightFields()
                            : SizedBox(),
                        isBookingType == false
                            ? const SizedBox(height: 16)
                            : SizedBox(),
                        isBookingType == false
                            ? specialRequirementsDropdown()
                            : SizedBox(),
                        Row(
                          children: [
                            selectVehicle(),
                            const SizedBox(height: 10),
                            specialInstructions(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        bookButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ================= TOGGLES =================
  Widget bookingTypeToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xffE6E9F0), // light grey background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          /// 🔵 WITHIN CITY
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isBookingType = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color:
                      isBookingType
                          ? AppColors.primaryColor
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Within City",
                  style: TextStyle(
                    color: isBookingType ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          /// ⚪ OUTSIDE CITY
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isBookingType = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color:
                      !isBookingType
                          ? AppColors.primaryColor
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Outside City",
                  style: TextStyle(
                    color: !isBookingType ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceTypeRadio() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// 🔵 NOW OPTION
        GestureDetector(
          onTap: () {
            setState(() {
              isWithinCity = true;
              bookingMode = "NOW";
            });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isWithinCity
                          ? const Color(0xff4F7CFF)
                          : Colors.transparent,
                  border: Border.all(
                    color: isWithinCity ? const Color(0xff4F7CFF) : Colors.grey,
                    width: 2,
                  ),
                ),
                child:
                    isWithinCity
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 8),
              const Text(
                "NOW",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(width: 30),

        /// ⚪ SCHEDULE OPTION
        GestureDetector(
          onTap: () {
            setState(() {
              isWithinCity = false;
              bookingMode = "SCHEDULE";
            });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      !isWithinCity
                          ? const Color(0xff4F7CFF)
                          : Colors.transparent,
                  border: Border.all(
                    color:
                        !isWithinCity ? const Color(0xff4F7CFF) : Colors.grey,
                    width: 2,
                  ),
                ),
                child:
                    !isWithinCity
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 8),

              /// TEXT COLUMN (matches screenshot layout)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "SCHEDULE",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget toggleButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELDS =================
  Widget locationSearchField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),

        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, TextEditingValue value, child) {
            return TextField(
              controller: controller,
              readOnly: true,
              // ✅ Use this instead
              onTap: () {
                _openLocationBottomSheet(label, controller);
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search location",
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    value.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              if (label == 'Pickup Location') {
                                mfromLable = '';
                                mPincode1 = null;
                                fromController.clear();
                              } else if (label == 'Drop Location') {
                                mtoLable = '';
                                mPincode2 = null;
                                toController.clear();
                              }
                            });

                            controller.clear(); // ✅ Now works
                          },
                        )
                        : const Icon(Icons.search),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget locationFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            /// Pickup icon
            const Icon(Icons.location_on, color: Colors.blue, size: 28),

            /// Dotted line
            Container(
              width: 2,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxHeight = constraints.constrainHeight();
                  const dashHeight = 4;
                  const dashSpace = 4;
                  final dashCount =
                      (boxHeight / (dashHeight + dashSpace)).floor();

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(dashCount, (_) {
                      return Container(width: 2, height: 5, color: Colors.grey);
                    }),
                  );
                },
              ),
            ),

            /// Drop icon
            const Icon(Icons.location_on, color: Colors.orange, size: 28),
          ],
        ),

        /// LEFT SIDE (Fields)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              locationSearchField("Pickup Location", fromController),
              Text(
                mfromLable,
                style: TextStyle(
                  color:
                      mfromLable == "Service is available"
                          ? Colors.black
                          : Colors.red,
                ),
              ),
              locationSearchField("Drop Location", toController),
              Text(
                mtoLable,
                style: TextStyle(
                  color:
                      mtoLable == "Service is available"
                          ? Colors.black
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openLocationBottomSheet(
      String label,
      TextEditingController controller,
      ) async {
    final TextEditingController searchController =
    TextEditingController(text: controller.text);

    final FocusNode searchFocusNode = FocusNode();

    List<String> recentLocations = await PrefUtils.getRecentLocations();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool showRecent =
                searchController.text.isEmpty && recentLocations.isNotEmpty;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!searchFocusNode.hasFocus &&
                  searchController.text.isEmpty) {
                searchFocusNode.requestFocus();
              }
            });

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    /// Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    /// Title Row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            "Select $label",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              FocusScope.of(sheetContext).unfocus();
                              if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    /// Google AutoComplete Field (SAFE VERSION)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GooglePlaceAutoCompleteTextField(
                        textEditingController: searchController,
                        focusNode: searchFocusNode,
                        googleAPIKey: "AIzaSyDpH5LUm09CEiJX4cSan8SDp0vxuVLwCCQ",
                        debounceTime: 600,
                        countries: const ["in"],

                        // 🔥 IMPORTANT: DO NOT enable latLng internal fetching
                        isLatLngRequired: false,

                        inputDecoration: InputDecoration(
                          hintText: "Search location",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),

                        itemBuilder: (context, index, prediction) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.blueGrey,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    prediction.description ?? "",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },

                        seperatedBuilder: const Divider(height: 1),
                        isCrossBtnShown: true,

                        /// 🔥 SAFE PLACE SELECTION HANDLER
                        itemClick: (prediction) async {
                          final selected =
                              prediction.description ?? "";

                          controller.text = selected;
                          searchController.text = selected;

                          await PrefUtils.addLocation(selected);

                          if (!mounted) return;

                          final provider =
                          Provider.of<PlaceDetailsProvider>(
                            context,
                            listen: false,
                          );

                          // Manual place details fetch
                          await provider.fetchPlaceDetails(
                              prediction.placeId!);

                          if (!mounted) return;

                          final details = provider.placeDetails;

                          if (details != null) {
                            if (label == "Pickup Location") {
                              mPincode1 = details.postalCode;
                              PrefUtils.setPinCode1(mPincode1!);
                              fromLatitude =
                                  details.lat.toString();
                              fromLongitude =
                                  details.lng.toString();
                            } else {
                              mPincode2 = details.postalCode;
                              PrefUtils.setPinCode2(mPincode2!);
                              toLatitude =
                                  details.lat.toString();
                              toLongitude =
                                  details.lng.toString();
                            }
                          }

                          if (mPincode1 != null &&
                              mPincode2 != null) {
                            _checkCluster(
                                mPincode1!, mPincode2!);
                          } else if (mPincode1 != null) {
                            _checkArea(mPincode1!);
                          }

                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Recent Searches
                    if (showRecent) ...[
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Recent Searches",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: recentLocations.length,
                          itemBuilder: (context, index) {
                            final loc = recentLocations[index];

                            return ListTile(
                              leading: const Icon(
                                Icons.history,
                                color: Colors.grey,
                              ),
                              title: Text(
                                loc,
                                style:
                                const TextStyle(fontSize: 15),
                              ),
                              onTap: () async {
                                controller.text = loc;
                                searchController.text = loc;

                                await PrefUtils.addLocation(loc);

                                if (Navigator.of(sheetContext)
                                    .canPop()) {
                                  Navigator.of(sheetContext)
                                      .pop();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget dateTimeFields() {
    return Row(
      children: [
        Expanded(
          child: dateTimeField(
            label: "Pickup Date",
            hint: "dd/mm/yyyy",
            controller: pickupDateController,
            onTap: selectPickupDate,
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: dateTimeField(
            label: "Pickup Time",
            hint: "--:-- --",
            controller: pickupTimeController,
            onTap: selectPickupTime,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget dateTimeField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Future<void> selectPickupDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      pickupDateController.text =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }

  Future<void> selectPickupTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      pickupTimeController.text = picked.format(context);
    }
  }

  Widget materialWeightFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Material Name
        Expanded(
          flex: 2,
          child: inputField(
            "Material Name *",
            "e.g. Cement",
            controller: metrialController,
          ),
        ),
        const SizedBox(width: 12),

        // Weight
        Expanded(
          flex: 1,
          child: inputField(
            "Weight *",
            "Enter weight",
            controller: weightController,
          ),
        ),
        const SizedBox(width: 8),

        // Unit Dropdown
        SizedBox(
          width: 90, // 👈 equal & stable
          child: unitBox(),
        ),
      ],
    );
  }

  Widget inputField(
    String label,
    String hint, {
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget unitBox() {
    return SizedBox(
      width: 80, // 👈 fixed width
      height: 50,
      child: DropdownButtonFormField<String>(
        value: selectedUnit,
        items:
            units.map((unit) {
              return DropdownMenuItem(
                value: unit,
                child: Text(
                  unit,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            selectedUnit = value!;
          });
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }

  Widget specialRequirementsDropdown() {
    final selectedItems =
        specialRequirements.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Special Requirements",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // ===== Dropdown =====
        DropdownButtonFormField<String>(
          value: null,
          hint: const Text("Select special requirement"),
          items:
              specialRequirements.keys.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              specialRequirements[value] = true;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ===== Selected Chips OR Hint =====
        selectedItems.isEmpty
            ? Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                "No special requirements selected",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            )
            : Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  selectedItems.map((item) {
                    return Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          specialRequirements[item] = false;
                        });
                      },
                      backgroundColor: const Color(0xFFF2F7FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
            ),
      ],
    );
  }

  Widget selectVehicle() {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (sameCluster == true) {
            showVehicleBottomSheet(context, mPincode1!, mPincode2!);
          } else {
            Utils.showCustomToast(context, "Service is not available");
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, color: Color(0xFF356AE6), size: 18),
            SizedBox(width: 6),
            Text(
              vehicleType.isNotEmpty ? vehicleType : "Select Vehicle Type",
              style: TextStyle(
                color: const Color(0xFF356AE6),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                // 👈 underline
                decorationColor: const Color(0xFF356AE6),
                // optional
                decorationThickness: 1.5, // optional thickness
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget specialInstructions() {
    return Expanded(
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const SpecialInstructionsDialog(),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10,),
            const Text(
              "Add Special Instructions",
              style: TextStyle(
                color: const Color(0xFF356AE6),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                // 👈 underline
                decorationColor: const Color(0xFF356AE6),
                // optional
                decorationThickness: 1.5, // optional thickness
              ),
            ),
            const Text(
              "(Optional)",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                // 👈 underline
                decorationColor: Colors.grey,
                // optional
                decorationThickness: 1.5, // optional thickness
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bookButton() {
    final provider = context.read<BookingProvider>();

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          if (fromController.text.isEmpty) {
            Utils.showErrorMessage(context, 'Please search pickup location.');
            return;
          } else if (toController.text.isEmpty) {
            Utils.showErrorMessage(context, 'Please search drop location.');
            return;
          } else if (vehicleType == "") {
            Utils.showErrorMessage(context, 'Please select vehicle type.');
            return;
          }
          globalBookingRequest = BookingTripRequest(
            bookingMode: bookingMode,
            tripType: "Single",
            vehicleType: vehicleType!,
            fromLocation: LocationModal(
              address: fromController.text.trim(),
              lat: double.parse(toLatitude!),
              lng: double.parse(toLongitude!),
            ),
            toLocation: LocationModal(
              address: toController.text.trim(),
              lat: double.parse(fromLatitude!),
              lng: double.parse(fromLongitude!),
            ),
            materialName: "",
            weight: 0,
          );

          if (PrefUtils.isLoggedIn()) {
            showWaitingForDriver();
            _bookingTripe(globalBookingRequest!);
          } else {
            PrefUtils.saveBookingRequest(globalBookingRequest!);
            PrefUtils.setRole('customer');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        },
        child:
            isBookingLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  "Book Now",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Future<void> showVehicleBottomSheet(
    BuildContext context,
    String pincode1,
    String pincode2,
  ) async {
    final result = await showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: VehicleSelectionSheet(pincode1, pincode2),
        );
      },
    );

    if (result != null) {
      setState(() {
        vehicleType = result.name;
        mPrice = result.price.toString();
        print("Selected Vehicle: ${result.name}");
        print("Price: ₹${result.price}");
      });
    }
  }
}
