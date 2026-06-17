import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:provider/provider.dart';
import '../../provider_service/URLS.dart';
import '../../provider_service/myrides_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/common_btn.dart';
import '../../resource/common_text.dart';
import '../../resource/sized_box.dart';
import 'driver_tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isUpcoming = true;
  bool isLoading = false;
  int currentPage = 1;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();
  String? mDate;
  String? mTime;
  DateTime selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if(PrefUtils.isLoggedIn()) {
      _bookingAllRideService(page: currentPage);
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final provider = Provider.of<MyridesProvider>(context, listen: false);
    if (!isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      if (isUpcoming) {
        if (provider.currentPagination != null &&
            provider.currentPagination['next_page'] == true) {
          _loadMoreRides();
        }
      } else {
        if (provider.completedPagination != null &&
            provider.completedPagination['next_page'] == true) {
          _loadMoreRides();
        }
      }
    }
  }

  Future<void> _bookingAllRideService({
    int page = 1,
    bool isRefresh = false,
  }) async {
    if (isRefresh) currentPage = 1;
    setState(() => isLoading = true);

    try {
      await Provider.of<MyridesProvider>(context, listen: false).validateList(
        endpoint: URLS.bookingAllRide,
        page: currentPage,
        limit: limit,
        append: !isRefresh && page > 1,
      );
    } catch (error) {
      Utils.showErrorMessage(context, 'An error occurred: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreRides() async {
    currentPage++;
    await _bookingAllRideService(page: currentPage);
  }

  void callDateTime(String defaultBookingHour, String mUrid) {
    final result = Utils.convertMillisecondsToDateAndTime(
      int.parse(defaultBookingHour),
    );

    mDate = result['date'];
    mTime = result['time'];

    try {
      if (mDate != null && mTime != null) {
        final dateParts = mDate!.split('-');
        final timeParts = mTime!.split(':');

        int year, month, day;
        if (dateParts[0].length == 4) {
          year = int.parse(dateParts[0]);
          month = int.parse(dateParts[1]);
          day = int.parse(dateParts[2]);
        } else {
          day = int.parse(dateParts[0]);
          month = int.parse(dateParts[1]);
          year = int.parse(dateParts[2]);
        }

        selectedDateTime = DateTime(
          year,
          month,
          day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } else {
        selectedDateTime = DateTime.now();
      }
    } catch (e) {
      selectedDateTime = DateTime.now();
    }
    _pickDateTime(mUrid);
  }

  Future<void> _pickDateTime(String mUrid) async {
    DateTime now = DateTime.now();
    DateTime initialDateTime =
        selectedDateTime.isBefore(now) ? now : selectedDateTime;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    TimeOfDay initialTime = TimeOfDay(
      hour: initialDateTime.hour,
      minute: initialDateTime.minute,
    );

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) return;

    DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day &&
        pickedDateTime.isBefore(now)) {
      Utils.showErrorToast(context, "Please select a future time today");
      return;
    }

    setState(() {
      selectedDateTime = pickedDateTime;
      mDate =
          "${selectedDateTime.day.toString().padLeft(2, '0')}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.year}";
      mTime =
          "${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}";
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFDFF1FF), Colors.white],
          ),
        ),
        child: Consumer<MyridesProvider>(
          builder: (context, provider, _) {
            final upcomingRides = provider.cureentRideListData;
            final completedRides = provider.completeRideListData;
            final selectedList = isUpcoming ? upcomingRides : completedRides;

            return Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Toggle Buttons
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 1,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 5,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isUpcoming = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isUpcoming
                                            ? AppColors.primaryColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Upcoming Ride",
                                    style: TextStyle(
                                      color:
                                          isUpcoming
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isUpcoming = false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        !isUpcoming
                                            ? AppColors.primaryColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Completed",
                                    style: TextStyle(
                                      color:
                                          !isUpcoming
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  /// Ride List with Pull-to-Refresh
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _bookingAllRideService(isRefresh: true);
                      },
                      child:
                          selectedList.isEmpty
                              ? Center(
                                child: Text(
                                  isUpcoming
                                      ? 'No upcoming bookings available'
                                      : 'No completed bookings found',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              )
                              : _rideCard(selectedList, isUpcoming),
                    ),
                  ),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🪪 Ride card
  Widget _rideCard(List<dynamic> rides, bool isUpcoming) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverTrackingScreen(ride!['fromLocation']['lat'],ride!['fromLocation']['lng'],ride!['toLocation']['lat'],ride!['toLocation']['lng']),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🚘 Top section
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),

                      child: Icon(
                        Icons.local_shipping,
                        size: 36,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride['bookingMode'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "#ID: ${ride['_id'] ?? '---'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${ride['estimated_price'] ?? '--'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 28),

                /// 👨‍✈️ Driver info
                if (ride['show_driver_details']?? false)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ride['driver_details'] != null
                            ? ride['driver_details']['full_name']
                            : "",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ride['driver_details']['cab_reg'],
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                      /*Row(
                        children: [
                          InkWell(
                            onTap: () {
                              openWhatsApp(
                                ride['driver_details']['mobile'],
                                ride['driver_details']['default_msg'],
                              );
                            },
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEAF6FB),
                              child: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap:
                                () => makePhoneCall(
                                  ride['driver_details']['mobile'],
                                ),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEAF6FB),
                              child: Icon(Icons.call, color: Colors.teal),
                            ),
                          ),
                        ],
                      ),*/
                    ],
                  ),
                if (ride['show_driver_details']?? false)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      const Divider(
                        height: 1,
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                if (ride['show_captain_details']??false)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            textKey:
                                ride['ride_captain_details'] != null
                                    ? ride['ride_captain_details']['full_name']
                                    : "",
                            fontWeight: FontWeight.bold,
                          ),
                          CustomText(
                            textKey: 'Captain',
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      /*Row(
                        children: [
                          InkWell(
                            onTap: () {
                              openWhatsApp(
                                ride['ride_captain_details']['mobile'],
                                ride['ride_captain_details']['default_msg'],
                              );
                            },
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEAF6FB),
                              child: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap:
                                () => makePhoneCall(
                                  ride['ride_captain_details']['mobile'],
                                ),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEAF6FB),
                              child: Icon(Icons.call, color: Colors.teal),
                            ),
                          ),
                        ],
                      ),*/
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CustomText(
                      textKey: Utils.formatIsoDate(ride['createdAt']),
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    const Spacer(),
                    CustomText(
                      textKey: ride['status'],
                      fontSize: 16,
                      color:
                          ride['status'] == 'cancelled'
                              ? Colors.red
                              : Colors.black,
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 12),
                    SizedBox(width: 8),
                    CustomText(
                      textKey: "Pickup location",
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ],
                ),
                CustomText(
                  textKey: ride['fromLocation']['address'] ?? '---',
                  maxLine: 2,
                ),
                const Divider(height: 20),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.green),
                    SizedBox(width: 8),
                    CustomText(
                      textKey: "Drop off",
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ],
                ),
                CustomText(
                  textKey: ride['toLocation']['address'] ?? '---',
                  maxLine: 2,
                ),
                height20,
                if (isUpcoming &&
                    (ride['is_cancellable'] == true ||
                        ride['is_reschedule'] == true))
                  Row(
                    children: [
                      if (ride['is_cancellable'] == true)
                        Expanded(
                          child: CommonBtn(
                            text: 'Cancel',
                            onPressed: () {
                              /* Get.to(() =>
                                  CancelBookingReasonScreen(ride['urid']));*/
                            },
                            bgColor: Colors.grey.shade100,
                            textColor: Colors.black,
                          ),
                        ),
                      if (ride['is_reschedule'] == true) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              callDateTime(
                                ride['default_booking_hour'].toString(),
                                ride['urid'],
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Reschedule",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (ride['payment_required'] == true) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              /*
                              Get.to(PaymentMethodScreen(
                                  ride,
                                  ride['payment_required'],
                                  ride['urid'],
                                  ride['advance_amt'].toString(),
                                  ride['booking_source'],
                                  ride['booking_destination'],false));
                              */
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Pay Now ₹${ride['advance_amt']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

/*  void openWhatsApp(String mobileNo, String defaultMsg) async {
    final message = Uri.encodeComponent(defaultMsg);
    final url = 'https://wa.me/$mobileNo?text=$message';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }*/
}
