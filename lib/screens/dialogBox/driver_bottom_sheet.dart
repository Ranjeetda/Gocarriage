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

  // ===================== DYNAMIC STATUS CONFIG =====================
  static const Map<String, Map<String, dynamic>> _statusConfig = {
    "SEARCHING": {
      "label": "Searching Driver",
      "bg": Color(0xFFFFF7ED),
      "text": Color(0xFFC2410C),
    },
    "ACCEPTED": {
      "label": "Driver Accepted",
      "bg": Color(0xFFDCFCE7),
      "text": Color(0xFF166534),
    },
    "ARRIVED": {
      "label": "Driver Arrived",
      "bg": Color(0xFFDBEAFE),
      "text": Color(0xFF1E40AF),
    },
    "LOADING": {
      "label": "Loading",
      "bg": Color(0xFFFEF3C7),
      "text": Color(0xFF92400E),
    },
    "IN_TRANSIT": {
      "label": "In Transit",
      "bg": Color(0xFFE0E7FF),
      "text": Color(0xFF3730A3),
    },
    "REACHED": {
      "label": "Reached Destination",
      "bg": Color(0xFFD1FAE5),
      "text": Color(0xFF065F46),
    },
    "UNLOADING": {
      "label": "Unloading",
      "bg": Color(0xFFFCE7F3),
      "text": Color(0xFF9D174D),
    },
    "COMPLETED": {
      "label": "Completed",
      "bg": Color(0xFFF0FDF4),
      "text": Color(0xFF15803D),
    },
    "CANCELLED": {
      "label": "Cancelled",
      "bg": Color(0xFFFEE2E2),
      "text": Color(0xFFB91C1C),
    },
  };

  // Order of statuses for timeline progress
  static const List<String> _statusOrder = [
    "ACCEPTED",
    "ARRIVED",
    "LOADING",
    "IN_TRANSIT",
    "REACHED",
    "UNLOADING",
    "COMPLETED",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // ---------- Dynamic Status Badge ----------
  Widget _buildStatusBadge(String status) {
    final config = _statusConfig[status.toUpperCase()] ??
        _statusConfig["SEARCHING"]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config["bg"] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config["label"] as String,
        style: TextStyle(
          color: config["text"] as Color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ---------- Timeline Step ----------
  Widget _buildTimelineStep({
    required bool isActive,
    required bool isCompleted,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : isActive
                    ? const Color(0xFFF97316)
                    : Colors.grey.shade300,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            if (!isCompleted)
              Container(
                width: 2,
                height: 40,
                color: isActive
                    ? const Color(0xFFF97316)
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isActive || isCompleted
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Main Build ----------
  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final booking = provider.upcomingRide != null
            ? Map<String, dynamic>.from(provider.upcomingRide!)
            : null;

        final status =
            booking?["status"]?.toString().toUpperCase() ?? "SEARCHING";

        final isSearching = provider.rideStatus != RideStatus.accepted &&
            !_statusOrder.contains(status) &&
            status != "CANCELLED";

        if (isSearching) {
          return _buildSearchingSheet(provider);
        }

        return _buildFullStatusSheet(context, provider, booking!, status);
      },
    );
  }

  // ---------------------------------------------------------------
  // SEARCHING SHEET
  // ---------------------------------------------------------------
  Widget _buildSearchingSheet(BookingProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120 + (_pulseController.value * 24),
                      height: 120 + (_pulseController.value * 24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFEDD5)
                            .withOpacity(1 - _pulseController.value),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFED7AA),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
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
            const SizedBox(height: 28),
            const Text(
              "Finding Your Driver",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're searching for the nearest available driver\nin your area",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: Color(0xFFC2410C)),
                  const SizedBox(width: 6),
                  Text(
                    "Elapsed $_formattedTime",
                    style: const TextStyle(
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  provider.cancelRide();
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Cancel Search",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
  }

  // ---------------------------------------------------------------
  // FULL STATUS SHEET
  // ---------------------------------------------------------------
  Widget _buildFullStatusSheet(
      BuildContext context,
      BookingProvider provider,
      Map<String, dynamic> booking,
      String status,
      ) {
    final driver = Map<String, dynamic>.from(booking["driverDetails"] ?? {});
    final from = booking["fromLocation"];
    final to = booking["toLocation"];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ========== HEADER ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          provider.clearRide();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(status),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 16, color: Color(0xFFEA580C)),
                            const SizedBox(width: 6),
                            Text(
                              "OTP ${booking["otp"] ?? "--"}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        Utils.formatIsoDate(
                            booking["pickupDate"]?.toString() ?? ""),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        (booking["bookingCode"]?.toString() ?? "")
                            .padRight(12)
                            .substring(0, 12),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ========== SCROLLABLE CONTENT ==========
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationCard(from, to),
                    const SizedBox(height: 22),
                    _buildDriverCard(driver),
                    const SizedBox(height: 22),
                    const Text(
                      "Trip Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTimeline(status: status),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ========== BOTTOM ACTION ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarycolor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (from == null || to == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverTrackingScreen(
                          fromLat: (from["lat"] as num).toDouble(),
                          fromLang: (from["lng"] as num).toDouble(),
                          toLat: (to["lat"] as num).toDouble(),
                          toLang: (to["lng"] as num).toDouble(),
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Track Driver Live",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Sub widgets ----------

  Widget _buildLocationCard(dynamic from, dynamic to) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location,
                    color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      from?["address"] ?? "--",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Column(
              children: List.generate(
                3,
                    (i) => Container(
                  width: 2,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.grey.shade300,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: Color(0xFFDC2626), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Drop-off",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      to?["address"] ?? "--",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
            ),
            child: Center(
              child: Text(
                (driver["name"]?.toString().isNotEmpty == true)
                    ? driver["name"].toString()[0].toUpperCase()
                    : "D",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver["name"] ?? "Driver",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      driver["mobileNo"] ?? "--",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${driver["experienceYears"] ?? "--"} yrs exp  •  ${driver["vehicleNumber"] ?? "--"}  •  ${driver["vehicleColor"] ?? ""}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Dynamic Timeline based on your statuses ----------
  Widget _buildTimeline({required String status}) {
    final currentIndex = _statusOrder.indexOf(status.toUpperCase());

    // Helper to decide state of each step
    bool isCompleted(int stepIndex) =>
        currentIndex > stepIndex || status.toUpperCase() == "COMPLETED";
    bool isActive(int stepIndex) => currentIndex == stepIndex;

    return Column(
      children: [
        // 1. ACCEPTED
        _buildTimelineStep(
          isActive: isActive(0),
          isCompleted: isCompleted(0),
          title: "Driver Accepted",
          subtitle: isCompleted(0) ? "Driver is on the way" : "Waiting for driver",
          icon: Icons.person_search_rounded,
        ),

        // 2. ARRIVED
        _buildTimelineStep(
          isActive: isActive(1),
          isCompleted: isCompleted(1),
          title: "Driver Arrived",
          subtitle: isCompleted(1) ? "Driver reached pickup location" : "Going to pickup",
          icon: Icons.location_on_outlined,
        ),

        // 3. LOADING
        _buildTimelineStep(
          isActive: isActive(2),
          isCompleted: isCompleted(2),
          title: "Loading",
          subtitle: isCompleted(2) ? "Goods are being loaded" : "Waiting to load",
          icon: Icons.inventory_2_outlined,
        ),

        // 4. IN_TRANSIT
        _buildTimelineStep(
          isActive: isActive(3),
          isCompleted: isCompleted(3),
          title: "In Transit",
          subtitle: isCompleted(3) ? "On the way to destination" : "Not started yet",
          icon: Icons.local_shipping_outlined,
        ),

        // 5. REACHED
        _buildTimelineStep(
          isActive: isActive(4),
          isCompleted: isCompleted(4),
          title: "Reached Destination",
          subtitle: isCompleted(4) ? "Arrived at drop location" : "Still on the way",
          icon: Icons.flag_outlined,
        ),

        // 6. UNLOADING
        _buildTimelineStep(
          isActive: isActive(5),
          isCompleted: isCompleted(5),
          title: "Unloading",
          subtitle: isCompleted(5) ? "Goods are being unloaded" : "Pending",
          icon: Icons.unarchive_outlined,
        ),

        // 7. COMPLETED
        _buildTimelineStep(
          isActive: isActive(6),
          isCompleted: isCompleted(6),
          title: "Completed",
          subtitle: isCompleted(6) ? "Trip finished successfully" : "Pending",
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}