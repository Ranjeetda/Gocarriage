import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/driver_profile_provider.dart';

class DriverProfileViewScreen extends StatefulWidget {
  final String driverId;

  const DriverProfileViewScreen({super.key, required this.driverId});

  @override
  State<DriverProfileViewScreen> createState() => _DriverProfileViewScreenState();
}

class _DriverProfileViewScreenState extends State<DriverProfileViewScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DriverProfileProvider>(context, listen: false);
      await provider.fetchProfile(widget.driverId);
      if (mounted) setState(() => isLoading = false);
    });
  }

  String _safe(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    return value.toString();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Consumer<DriverProfileProvider>(
        builder: (context, provider, _) {
          final data = provider.profileData ?? {};

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final fullName = _safe(data['fullName']);
          final mobile = _safe(data['mobileNo']);
          final isOnVehicle = data['driver_assigned_status'] == true;
          final profilePic = data['profile_picture'];

          return Column(
            children: [
              // ── HEADER ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                decoration:  BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      backgroundImage: profilePic != null &&
                          profilePic.toString().isNotEmpty
                          ? NetworkImage(
                        profilePic.toString().startsWith('http')
                            ? profilePic
                            : 'https://your-api-domain.com/$profilePic',
                      )
                          : null,
                      child: profilePic == null || profilePic.toString().isEmpty
                          ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mobile,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnVehicle
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_filled,
                                  size: 14,
                                  color: isOnVehicle
                                      ? const Color(0xFFEF6C00)
                                      : const Color(0xFF43A047),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnVehicle ? 'On Vehicle' : 'Available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOnVehicle
                                        ? const Color(0xFFEF6C00)
                                        : const Color(0xFF43A047),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── CONTENT ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
                  child: Column(
                    children: [
                      // PERSONAL INFORMATION
                      _sectionCard(
                        title: 'PERSONAL INFORMATION',
                        children: [
                          _infoRow('Full Name', _safe(data['fullName'])),
                          _infoRow('Mobile', _safe(data['mobileNo'])),
                          _infoRow('Email', _safe(data['email'])),
                          _infoRow('Alternate Number',
                              _safe(data['alternateNumber'])),
                          _infoRow(
                            'Status',
                            (data['status'] ?? '').toString().toUpperCase(),
                            valueColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ADDRESS
                      _sectionCard(
                        title: 'ADDRESS',
                        children: [
                          _infoRow('City', _safe(data['city'])),
                          _infoRow('State', _safe(data['state'])),
                          _infoRow('Pin Code', _safe(data['pinCode'])),
                          _infoRow('House No.', _safe(data['houseNumber'])),
                          _infoRow('Street', _safe(data['street'])),
                          _infoRow('Area', _safe(data['area'])),
                          _infoRow(
                              'Complete Address', _safe(data['completeAddress'])),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // EMERGENCY CONTACT
                      _sectionCard(
                        title: 'EMERGENCY CONTACT',
                        children: [
                          _infoRow('Contact Name',
                              _safe(data['emergencyContactName'])),
                          _infoRow('Contact Number',
                              _safe(data['emergencyContactNumber'])),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // LICENSE DETAILS
                      _sectionCard(
                        title: 'LICENSE DETAILS',
                        children: [
                          _infoRow(
                              'License Number', _safe(data['licenseNumber'])),
                          _infoRow(
                              'License Type', _safe(data['license_type'])),
                          _infoRow('Valid From',
                              _formatDate(data['license_from_date']?.toString())),
                          _infoRow('Valid Upto',
                              _formatDate(data['license_expiry_date']?.toString())),
                          _infoRowWithButton(
                            'License Doc',
                            data['driversLicenseUpload'],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // IDENTITY DOCUMENTS
                      _sectionCard(
                        title: 'IDENTITY DOCUMENTS',
                        children: [
                          _infoRow('Aadhaar Number',
                              _safe(data['aadhaarCardNumber'])),
                          _infoRowWithButton(
                              'Aadhaar Doc', data['aadhaarCardUpload']),
                          _infoRow('PAN Number', _safe(data['panCardNumber'])),
                          _infoRowWithButton(
                              'PAN Doc', data['panCardUpload']),
                          _infoRowWithButton(
                              'Insurance Doc', data['insuranceDocumentUpload']),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // BANK DETAILS
                      _sectionCard(
                        title: 'BANK DETAILS',
                        children: [
                          _infoRow('Bank Name', _safe(data['bankName'])),
                          _infoRow(
                              'Account Number', _safe(data['accountNumber'])),
                          _infoRow('IFSC Code', _safe(data['ifscCode'])),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // WORK DETAILS
                      _sectionCard(
                        title: 'WORK DETAILS',
                        children: [
                          _infoRow('Service Type',
                              _safe(data['service_type'])),
                          _infoRow('Experience (yrs)',
                              _safe(data['experience_in_yrs'])),
                          _infoRow('Vehicle Type Pref.',
                              _safe(data['vehicle_type_preference'])),
                          _infoRow(
                              'Transport Type', _safe(data['transportType'])),
                          _infoRow(
                              'Vehicle Number', _safe(data['vehicleNumber'])),
                          _infoRow(
                              'Vehicle Model', _safe(data['vehicleModel'])),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ACCOUNT INFO
                      _sectionCard(
                        title: 'ACCOUNT INFO',
                        children: [
                          _infoRow(
                            'Profile Updated',
                            data['isProfileUpdated'] == true ? 'Yes' : 'No',
                          ),
                          _infoRow('Joined',
                              _formatDate(data['createdAt']?.toString())),
                          _infoRow('Last Updated',
                              _formatDate(data['updatedAt']?.toString())),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── SECTION CARD ─────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7F4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF0D7377),
              ),
            ),
          ),
          // Rows
          ...children,
        ],
      ),
    );
  }

  // ── INFO ROW ─────────────────────────────────────────────────────
  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO ROW WITH VIEW BUTTON ────────────────────────────────────
  Widget _infoRowWithButton(String label, dynamic docUrl) {
    final hasDoc = docUrl != null && docUrl.toString().trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (hasDoc)
            GestureDetector(
              onTap: () {
                // TODO: Open document viewer / browser
                // You can use url_launcher or a PDF viewer
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00BFA5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.visibility_outlined,
                        size: 16, color: Color(0xFF0D7377)),
                    SizedBox(width: 4),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D7377),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}