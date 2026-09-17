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

    // Start elapsed timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        // ====================== ACCEPTED STATE ======================
        if (provider.rideStatus == RideStatus.accepted) {
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
                              provider.upcomingRide!["pickupDate"],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "OTP : ${provider.upcomingRide!["otp"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// Locations
                      Text(
                        "📍 ${provider.upcomingRide!['fromLocation']['address']}",
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "🏁 ${provider.upcomingRide!['toLocation']['address']}",
                      ),

                      const SizedBox(height: 12),

                      /// Driver Info
                      Text(
                        "Name : ${provider.upcomingRide!['driverDetails']['name'] ?? "--"}",
                      ),
                      Text(
                        "Phone : ${provider.upcomingRide!['driverDetails']['mobileNo'] ?? "--"}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      /// Fare Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                provider.upcomingRide!['pickupTime'] ?? "--",
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.directions_car,
                                  size: 18, color: Colors.black87),
                              const SizedBox(width: 6),
                              Text(
                                provider.upcomingRide!['driverDetails']
                                ['vehicleNumber'] ??
                                    "--",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                provider.upcomingRide!['driverDetails']
                                ['vehicleColor'] ??
                                    "--",
                                style: const TextStyle(fontSize: 16),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverTrackingScreen(
                                  fromLat: provider.upcomingRide!['fromLocation']['lat'],
                                  fromLang: provider.upcomingRide!['fromLocation']['lng'],
                                  toLat: provider.upcomingRide!['toLocation']['lat'],
                                  toLang: provider.upcomingRide!['toLocation']['lng'],
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Track",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Close Button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ====================== SEARCHING STATE (NEW DESIGN) ======================
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
                // ===== Pulsing Truck Icon =====
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 110 + (_pulseController.value * 18),
                          height: 110 + (_pulseController.value * 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFEDD5)
                                .withOpacity(1 - _pulseController.value),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFED7AA),
                          ),
                        ),
                        // Main circle
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF97316), // orange
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

                const SizedBox(height: 28),

                // ===== Title =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sync,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Finding Your Driver...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ===== Subtitle =====
                const Text(
                  'Searching for nearby drivers in your area...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Loading Dots =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value =
                        ((_pulseController.value + delay) % 1.0);
                        final opacity = value < 0.5 ? value * 2 : 2 - value * 2;

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

                // ===== Time Elapsed =====
                Text(
                  'Time elapsed: $_formattedTime',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 28),

                // ===== Cancel Button =====
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
                        Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cancel Search',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
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