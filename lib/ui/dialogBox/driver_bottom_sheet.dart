import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider_service/booking_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../dashboardScreen/driver_tracking_screen.dart';

class DriverBottomSheet extends StatelessWidget {
  const DriverBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        return provider.rideStatus == RideStatus.accepted
            ? Container(
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

                        /// Date
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
                            SizedBox(width: 90,),
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

                        /// Customer
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
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  provider.upcomingRide!['pickupTime'] ?? "--",
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  provider.upcomingRide!['driverDetails']['vehicleNumber'] ??
                                      "--",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  provider.upcomingRide!['driverDetails']['vehicleColor'] ??
                                      "--",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Action Button
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
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverTrackingScreen(provider.upcomingRide!['fromLocation']['lat'],provider.upcomingRide!['fromLocation']['lng'],provider.upcomingRide!['toLocation']['lat'],provider.upcomingRide!['toLocation']['lng']),
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

                    /// 🔴 Close Button (Top Right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
            : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 20),

                  const Text(
                    "Looking for nearby drivers...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    "Please wait while we find a driver",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        provider.cancelRide();
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel Ride"),
                    ),
                  ),
                ],
              ),
            );
      },
    );
  }
}
