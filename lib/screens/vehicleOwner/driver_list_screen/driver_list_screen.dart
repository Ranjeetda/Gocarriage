import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../provider_service/owner_un_assign_driver_provider.dart';
import '../../../provider_service/vechile_owner_driver_list.dart';
import '../../../resource/Utils.dart';
import '../../driver/driverProfile/driver_profile.dart';
import '../vehicleListScreen/select_driver_dialog.dart';

import 'driver_profile_view_screen.dart';
import 'edit_driver_screen.dart';

class DriverListScreen extends StatefulWidget {
  final bool isHeader;

  const DriverListScreen(this.isHeader, {super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  bool isLoading = false;
  List<dynamic> filteredList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await refreshDrivers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 🔍 Search
  void filterDrivers(String query) {
    final provider = Provider.of<VechileOwnerDriverList>(
      context,
      listen: false,
    );
    final all = provider.listData ?? [];

    if (query.trim().isEmpty) {
      setState(() => filteredList = all);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      filteredList =
          all.where((item) {
            final d = item['Driver'] ?? {};
            final name = (d['fullName'] ?? '').toString().toLowerCase();
            final mobile = (d['mobileNo'] ?? '').toString().toLowerCase();
            final email = (d['email'] ?? '').toString().toLowerCase();
            final service = (d['service_type'] ?? '').toString().toLowerCase();

            return name.contains(q) ||
                mobile.contains(q) ||
                email.contains(q) ||
                service.contains(q);
          }).toList();
    });
  }

  Future<void> refreshDrivers() async {
    final provider = Provider.of<VechileOwnerDriverList>(
      context,
      listen: false,
    );
    await provider.fetchList('in_city'); // keep your existing API

    setState(() {
      filteredList = provider.listData ?? [];
      if (searchController.text.isNotEmpty) {
        filterDrivers(searchController.text);
      }
    });
  }

  Map<String, int> getStats(List<dynamic> list) {
    int total = list.length;
    int onVehicle = 0;
    int available = 0;

    for (var item in list) {
      final d = item['Driver'] ?? {};
      final assigned =
          d['driver_assigned_status'] == true || item['is_active'] == true;
      if (assigned) {
        onVehicle++;
      } else {
        available++;
      }
    }
    return {
      'total': total,
      'available': available,
      'onVehicle': onVehicle,
      'docsDue': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar:
          widget.isHeader
              ? AppBar(
                backgroundColor: AppColors.primaryColor,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Driver List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SelectDriverDialog(),
                      );
                    },
                    child: const Text(
                      'Add Driver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
              : null,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: [
                  // ── STATS ────────────────────────────────────────
                  Consumer<VechileOwnerDriverList>(
                    builder: (context, provider, _) {
                      final stats = getStats(provider.listData ?? []);
                      return Row(
                        children: [
                          _statCard(
                            icon: Icons.people_outline_rounded,
                            value: stats['total']!,
                            label: 'Total',
                            bg: const Color(0xFFE0F7F4),
                            iconColor: const Color(0xFF00BFA5),
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            icon: Icons.check_circle_outline_rounded,
                            value: stats['available']!,
                            label: 'Available',
                            bg: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF43A047),
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            icon: Icons.local_shipping_outlined,
                            value: stats['onVehicle']!,
                            label: 'On Vehicle',
                            bg: const Color(0xFFFFF3E0),
                            iconColor: const Color(0xFFFB8C00),
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            icon: Icons.warning_amber_rounded,
                            value: stats['docsDue']!,
                            label: 'Docs Due',
                            bg: const Color(0xFFFFEBEE),
                            iconColor: const Color(0xFFE53935),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── SEARCH BAR ───────────────────────────────────
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 22,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: filterDrivers,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by name, mobile or vehicle type...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F7F4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filteredList.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── DRIVER LIST ──────────────────────────────────
                  Expanded(
                    child: Consumer<VechileOwnerDriverList>(
                      builder: (context, provider, _) {
                        return RefreshIndicator(
                          onRefresh: refreshDrivers,
                          color: AppColors.primaryColor,
                          child:
                              (provider.isLoading && filteredList.isEmpty)
                                  ? shimmerList()
                                  : filteredList.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 180),
                                      Center(
                                        child: Text(
                                          'No drivers found',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: filteredList.length,
                                    itemBuilder: (context, index) {
                                      return _driverCard(filteredList[index]);
                                    },
                                  ),
                        );
                      },
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

  // ── STAT CARD ────────────────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required int value,
    required String label,
    required Color bg,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── DRIVER CARD ──────────────────────────────────────────────────
  Widget _driverCard(dynamic driverData) {
    final driver = driverData['Driver'] ?? {};
    final String fullName = driver['fullName'] ?? 'Unknown';
    final String mobile = driver['mobileNo'] ?? '—';
    final String serviceType =
        (driver['service_type'] ?? '').toString().toLowerCase();
    final bool isOnVehicle =
        driver['driver_assigned_status'] == true ||
        driverData['is_active'] == true;
    final String? profilePic = driver['profile_picture'];

    final String initial =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    final bool isInCity = serviceType == 'in_city';
    final String serviceLabel = isInCity ? 'Within City' : 'Outside City';
    final Color serviceBg =
        isInCity ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0);
    final Color serviceText =
        isInCity ? const Color(0xFF1976D2) : const Color(0xFFEF6C00);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => DriverProfile(
                      'ownerDriverList',
                      driver['id'].toString(),
                    ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAvatar(initial, profilePic),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isOnVehicle
                                      ? const Color(0xFFFFF3E0)
                                      : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_filled_rounded,
                                  size: 13,
                                  color:
                                      isOnVehicle
                                          ? const Color(0xFFFB8C00)
                                          : const Color(0xFF43A047),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnVehicle ? 'On Vehicle' : 'Available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isOnVehicle
                                            ? const Color(0xFFFB8C00)
                                            : const Color(0xFF43A047),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── 3-DOT MENU (matches screenshot) ────────────
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DriverProfileViewScreen(
                                    driverId: driver['id'].toString(),
                                  ),
                            ),
                          );
                        } else if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditDriverScreen(
                                    driverId: driver['id'].toString(),
                                  ),
                            ),
                          );
                        } else if (value == 'unassign') {
                          showUnassignDialog(context, driverData);
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          // View Details
                          PopupMenuItem<String>(
                            value: 'view',
                            height: 44,
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                  color: Color(0xFF00BFA5),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF00BFA5),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit Driver
                          PopupMenuItem<String>(
                            value: 'edit',
                            height: 44,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit Driver',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(height: 1),

                          // Unassign (disabled when on vehicle)
                          PopupMenuItem<String>(
                            value: isOnVehicle ? null : 'unassign',
                            enabled: !isOnVehicle,
                            height: 48,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 20,
                                  color:
                                      isOnVehicle
                                          ? Colors.grey.shade400
                                          : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isOnVehicle
                                        ? 'On vehicle — unassign first'
                                        : 'Unassign',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isOnVehicle
                                              ? Colors.grey.shade400
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),

              // ── BODY ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  children: [
                    // Phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 17,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          mobile,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Service type
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: serviceBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            serviceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: serviceText,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 12),

                    // License
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'License',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        _licenseBadge(driverData),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AVATAR (safe image loading) ──────────────────────────────────
  Widget _buildAvatar(String initial, String? profilePic) {
    String? imageUrl;
    if (profilePic != null && profilePic.trim().isNotEmpty) {
      if (profilePic.startsWith('http')) {
        imageUrl = profilePic;
      } else {
        // ⚠️ Change this to your real image base URL
        imageUrl = 'https://your-api-domain.com/$profilePic';
      }
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE0F7F4),
      child:
          imageUrl == null
              ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00BFA5),
                ),
              )
              : ClipOval(
                child: Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFE0F7F4),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFE0F7F4),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  // ── LICENSE BADGE ────────────────────────────────────────────────
  Widget _licenseBadge(dynamic driverData) {
    String text = '—';
    Color bg = const Color(0xFFE8F5E9);
    Color color = const Color(0xFF2E7D32);

    try {
      if (driverData['assigned_at'] != null) {
        final assigned = DateTime.parse(driverData['assigned_at']);
        final daysPassed = DateTime.now().difference(assigned).inDays;
        final remaining = 365 - (daysPassed % 400); // demo only

        text = '${remaining}d left';
        if (remaining < 30) {
          bg = const Color(0xFFFFF3E0);
          color = const Color(0xFFEF6C00);
        }
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── UNASSIGN DIALOG ──────────────────────────────────────────────
  void showUnassignDialog(BuildContext context, final data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        bool dialogLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_off,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unassign Driver',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Remove from your fleet',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unassign "${data['Driver']['fullName']}"?\nThey will become available for other fleet owners.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                dialogLoading
                                    ? null
                                    : () async {
                                      setStateDialog(
                                        () => dialogLoading = true,
                                      );
                                      final success = await _unAssignDriver(
                                        data['driver_id'].toString(),
                                      );
                                      setStateDialog(
                                        () => dialogLoading = false,
                                      );
                                      if (success && mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                dialogLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('Yes, Unassign'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                dialogLoading
                                    ? null
                                    : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide.none,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _unAssignDriver(String? driverId) async {
    if (driverId == null) {
      Utils.showErrorMessage(context, 'Please select Driver');
      return false;
    }

    setState(() => isLoading = true);

    final response = await Provider.of<OwnerUnAssignDriverProvider>(
      context,
      listen: false,
    ).unAssignDriver(driverId);

    final responseData = json.decode(response.body);
    setState(() => isLoading = false);

    if (responseData['success'] == true) {
      await refreshDrivers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Success')),
        );
      }
      return true;
    } else {
      Utils.showErrorMessage(
        context,
        responseData['message'] ?? 'Unassign failed. Please try again.',
      );
      return false;
    }
  }

  // ── SHIMMER ──────────────────────────────────────────────────────
  Widget shimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
