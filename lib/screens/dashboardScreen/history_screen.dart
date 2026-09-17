import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import '../../provider_service/URLS.dart';
import '../../provider_service/myrides_provider.dart';
import '../../resource/Utils.dart';
import '../dialogBox/booking_details_dialog.dart';
import 'driver_tracking_screen.dart';

enum BookingStatus { cancelled, driverAssigned, active, completed }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int currentPage = 1;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();
  String selectedFilter = 'All'; // All | Active | Completed | Cancelled

  @override
  void initState() {
    super.initState();
    if (PrefUtils.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRides(page: 1, isRefresh: true);
      });
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<MyridesProvider>(context, listen: false);
    if (provider.isLoading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      final hasNext = (selectedFilter == 'Completed' ||
          selectedFilter == 'Cancelled')
          ? provider.hasNextCompletedPage
          : provider.hasNextCurrentPage;

      if (hasNext) {
        currentPage++;
        _loadRides(page: currentPage, append: true);
      }
    }
  }

  Future<void> _loadRides({
    int page = 1,
    bool isRefresh = false,
    bool append = false,
  }) async {
    if (isRefresh) currentPage = 1;

    try {
      await Provider.of<MyridesProvider>(context, listen: false).validateList(
        endpoint: URLS.bookingAllRide,
        page: page,
        limit: limit,
        append: append && !isRefresh,
      );
    } catch (error) {
      if (mounted) {
        Utils.showErrorMessage(context, 'Failed to load rides: $error');
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadRides(page: 1, isRefresh: true);
  }

  // ---------- Status mapping ----------
  BookingStatus _mapStatus(String? apiStatus) {
    switch (apiStatus?.toUpperCase()) {
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'ACCEPTED':
        return BookingStatus.driverAssigned;
      case 'TENDERING':
        return BookingStatus.active;
      case 'COMPLETED':
        return BookingStatus.completed;
      default:
        return BookingStatus.active;
    }
  }

  // ---------- Filter helpers ----------
  List<dynamic> _getFilteredList(MyridesProvider provider) {
    final upcoming = provider.cureentRideListData;
    final completed = provider.completeRideListData;

    switch (selectedFilter) {
      case 'Active':
        return upcoming
            .where((b) =>
        b['status'] == 'ACCEPTED' || b['status'] == 'TENDERING')
            .toList();
      case 'Completed':
        return completed
            .where((b) => b['status'] == 'COMPLETED')
            .toList();
      case 'Cancelled':
        return completed
            .where((b) => b['status'] == 'CANCELLED')
            .toList();
      case 'All':
      default:
        return [...upcoming, ...completed];
    }
  }

  Map<String, int> _getCounts(MyridesProvider provider) {
    final upcoming = provider.cureentRideListData;
    final completed = provider.completeRideListData;

    final active = upcoming
        .where((b) =>
    b['status'] == 'ACCEPTED' || b['status'] == 'TENDERING')
        .length;
    final completedCount =
        completed.where((b) => b['status'] == 'COMPLETED').length;
    final cancelled =
        completed.where((b) => b['status'] == 'CANCELLED').length;

    return {
      'All': upcoming.length + completed.length,
      'Active': active,
      'Completed': completedCount,
      'Cancelled': cancelled,
    };
  }

  // ---------- Date / Time formatting ----------
  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')} ${_month(dt.month)} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return iso;
    }
  }

  String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m];
  }

  List<String> _buildTags(Map<String, dynamic> special) {
    final tags = <String>[];
    if (special['container'] == true) tags.add('Container');
    if (special['extraLength'] == true) tags.add('Extra Length');
    if (special['covered'] == true) tags.add('Covered');
    if (special['hydraulic'] == true) tags.add('Hydraulic');
    if (special['extraLarge'] == true) tags.add('Extra Large');
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Consumer<MyridesProvider>(
        builder: (context, provider, _) {
          final counts = _getCounts(provider);
          final filteredList = _getFilteredList(provider);

          return Column(
            children: [
              // ---------- Filter Chips ----------
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: counts['All'] ?? 0,
                        isSelected: selectedFilter == 'All',
                        onTap: () => setState(() => selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Active',
                        count: counts['Active'] ?? 0,
                        isSelected: selectedFilter == 'Active',
                        onTap: () => setState(() => selectedFilter = 'Active'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        count: counts['Completed'] ?? 0,
                        isSelected: selectedFilter == 'Completed',
                        onTap: () =>
                            setState(() => selectedFilter = 'Completed'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Cancelled',
                        count: counts['Cancelled'] ?? 0,
                        isSelected: selectedFilter == 'Cancelled',
                        onTap: () =>
                            setState(() => selectedFilter = 'Cancelled'),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- List + Pull to Refresh ----------
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFFFF6B00),
                  child: provider.isLoading && filteredList.isEmpty
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B00),
                    ),
                  )
                      : filteredList.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height:
                        MediaQuery.of(context).size.height * 0.6,
                        child: const Center(
                          child: Text(
                            'No bookings found',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length +
                        (provider.isLoading ? 1 : 0),
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B00),
                            ),
                          ),
                        );
                      }

                      final booking = filteredList[index];
                      final special =
                          booking['specialRequirements'] ?? {};
                      final status = _mapStatus(booking['status']);

                      return BookingCard(
                        booking: booking,
                        bookingId: booking['_id'] ??
                            booking['bookingCode'] ??
                            '-',
                        status: status,
                        from: booking['fromLocation']?['address'] ??
                            '-',
                        to: booking['toLocation']?['address'] ?? '-',
                        pickupDate:
                        _formatDate(booking['pickupDate']),
                        pickupTime:
                        _formatTime(booking['pickupDate']),
                        vehicle: booking['vehicleType']?.toString() ??
                            '-',
                        weight:
                        '${booking['weight'] ?? 0} ${booking['weightUnit'] ?? 'KG'}',
                        material:
                        booking['materialName'] ?? 'General',
                        tags: _buildTags(
                            Map<String, dynamic>.from(special)),
                        showDriverSection: status ==
                            BookingStatus.driverAssigned &&
                            booking['assignedVehicleNumber'] != null,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// Booking Card
// ============================================================
class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String bookingId;
  final BookingStatus status;
  final String from;
  final String to;
  final String pickupDate;
  final String pickupTime;
  final String vehicle;
  final String weight;
  final String material;
  final List<String> tags;
  final bool showDriverSection;

  const BookingCard({
    super.key,
    required this.booking,
    required this.bookingId,
    required this.status,
    required this.from,
    required this.to,
    required this.pickupDate,
    required this.pickupTime,
    required this.vehicle,
    required this.weight,
    required this.material,
    this.tags = const [],
    this.showDriverSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Color(0xFFFF9800), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking ID',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        bookingId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
          ),

          // From → To
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                      Text(from,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      const Text('To',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                      Text(to,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Pickup',
                    value: '$pickupDate\n$pickupTime',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Vehicle',
                    value: vehicle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Weight',
                    value: weight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.category_outlined,
                    label: 'Material',
                    value: material,
                  ),
                ),
              ],
            ),
          ),

          // Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: tags
                    .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          ],

          // Driver section
          if (showDriverSection) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_outline,
                      color: Color(0xFF0EA5E9), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Driver Assigned',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (status == BookingStatus.cancelled) {
                    // Show booking details dialog for cancelled bookings
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => BookingDetailsDialog(booking: booking),
                    );
                  } else {
                    // Navigate to DriverTrackingScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverTrackingScreen(
                          fromLat: booking['fromLocation']?['lat'],
                          fromLang: booking['fromLocation']?['lng'],
                          toLat: booking['toLocation']?['lat'],
                          toLang: booking['toLocation']?['lng'],
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == BookingStatus.cancelled
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFFF6B00),
                  foregroundColor: status == BookingStatus.cancelled
                      ? const Color(0xFF4B5563)
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  status == BookingStatus.cancelled
                      ? '→ View Details'
                      : '→ Track Booking',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Filter Chip
// ============================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B00)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Status Chip
// ============================================================
class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color text;
    late String label;
    late IconData icon;

    switch (status) {
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case BookingStatus.driverAssigned:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        label = 'Driver Assigned';
        icon = Icons.person_pin_circle_outlined;
        break;
      case BookingStatus.completed:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF16A34A);
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Active';
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Info Tile
// ============================================================
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}