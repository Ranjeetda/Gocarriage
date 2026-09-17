import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider_service/booking_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../dashboardScreen/driver_tracking_screen.dart';

class DriverBottomSheet extends StatefulWidget {
  const DriverBottomSheet({super.key});

  @override
  State<DriverBottomSheet> createState() => _DriverBottomSheetState();
}

class _DriverBottomSheetState extends State<DriverBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString();
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {

        /// ================= ACCEPTED =================
        if (provider.rideStatus == RideStatus.accepted &&
            provider.upcomingRide != null) {

          final ride = provider.upcomingRide!;

          // Parse API response
          final booking = ride["booking"] ?? {};
          final driver = ride["driver"] ?? {};

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 10),

                      /// Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      /// Date + OTP
                      Row(
                        children: [
                          Text(
                            Utils.formatIsoDate(
                              booking["pickupDate"]!.toString(),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "OTP : ${ride["otp"] ?? "--"}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// Pickup
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking["fromLocation"]?["address"] ?? "--",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// Drop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.flag,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking["toLocation"]?["address"] ?? "--",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// Driver Info
                      const Text(
                        "Driver Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Name : ${driver["fullName"] ?? "--"}",
                        style: const TextStyle(fontSize: 15),
                      ),

                      Text(
                        "Phone : ${driver["mobileNo"] ?? "--"}",
                        style: const TextStyle(fontSize: 15),
                      ),

                      Text(
                        "Experience : ${driver["experienceYears"] ?? "--"} Years",
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 16),

                      /// Pickup Time + Vehicle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                booking["pickupTime"]?.toString() ?? "--",
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping,
                                  size: 18, color: Colors.black87),
                              const SizedBox(width: 5),
                              Text(
                                driver["vehicleNumber"] ?? "--",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                driver["vehicleColor"] ?? "--",
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Track Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondarycolor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {

                            final from = booking["fromLocation"];
                            final to = booking["toLocation"];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverTrackingScreen(
                                  fromLat: (from?["lat"] as num?)!.toDouble(),
                                  fromLang: (from?["lng"] as num?)!.toDouble(),
                                  toLat: (to?["lat"] as num?)!.toDouble(),
                                  toLang: (to?["lng"] as num?)!.toDouble(),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Track Driver",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Close
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        provider.clearRide();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        /// ================= SEARCHING =================
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110 + (_pulseController.value * 18),
                          height: 110 + (_pulseController.value * 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFEDD5)
                                .withOpacity(1 - _pulseController.value),
                          ),
                        ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFED7AA),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF97316),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Finding Your Driver...",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Searching for nearby drivers in your area...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value =
                        ((_pulseController.value + delay) % 1.0);
                        final opacity =
                        value < 0.5 ? value * 2 : 2 - value * 2;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF97316)
                                .withOpacity(0.3 + opacity * 0.7),
                          ),
                        );
                      },
                    );
                  }),
                ),

                const SizedBox(height: 20),

                Text(
                  "Time elapsed: $_formattedTime",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      provider.cancelRide();
                      Navigator.pop(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text(
                          "Cancel Search",
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}