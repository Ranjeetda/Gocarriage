import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../provider_service/vehicle_details_provider.dart';
import '../../../resource/app_colors.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailsScreen(this.vehicleId, {super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final DateFormat _dateFormat = DateFormat("dd MMM yyyy");

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return "-";
    try {
      final date = DateTime.parse(dateStr.toString());
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _getDaysLeft(dynamic dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final expiry = DateTime.parse(dateStr.toString());
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      return daysLeft > 0 ? "${daysLeft}d left" : "Expired";
    } catch (e) {
      return "N/A";
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleDetailsProvider>(context, listen: false)
          .fetchBooking(widget.vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vehicle Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Consumer<VehicleDetailsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SizedBox(height: 500, child: Center(child: CircularProgressIndicator()));
            }

            if (provider.vehicleDetailsData==null) {
              return const SizedBox(
                height: 500,
                child: Center(child: Text('No vehicle details available')),
              );
            }

            return Column(
              children: [
                _buildTopBanner(provider.vehicleDetailsData, isTablet),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isTablet) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildVehicleDetailsCard(provider.vehicleDetailsData)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildComplianceAndSummary(provider.vehicleDetailsData)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildVehicleDetailsCard(provider.vehicleDetailsData),
                            const SizedBox(height: 16),
                            _buildComplianceAndSummary(provider.vehicleDetailsData),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDocumentsSection(provider.vehicleDetailsData, isTablet),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== Top Banner ====================
  Widget _buildTopBanner(dynamic data, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00695C), Color(0xFF009688)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_shipping, size: 48, color: Color(0xFF00695C)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['vehicle_number'] ?? "N/A", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)),
                          child: Text((data['status'] ?? "active").toString().toUpperCase(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text("${data['VehicleType']?['brand'] ?? ''} ${data['VehicleType']?['model'] ?? ''} • Within City", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip("Vehicle Age", "<1 mo", "Since ${_formatDate(data['registered_date'])}"),
              _infoChip("Payload", "${data['payload'] ?? '0'} kg", "Capacity"),
              _infoChip("Fuel", data['fuel_type'] ?? "Diesel", data['color'] ?? "Red"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String title, String value, String subtitle) {
    return Column(children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]);
  }

  // ==================== Vehicle Details Card ====================
  Widget _buildVehicleDetailsCard(dynamic data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vehicle Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow("Chassis Number", data['chassis_number']),
            _detailRow("Engine Number", data['engine_number']),
            _detailRow("Fuel Type", data['fuel_type']),
            _detailRow("Color", data['color']),
            _detailRow("RTO", data['rto']),
            _detailRow("Brand / Model", "${data['VehicleType']?['brand'] ?? ''} • ${data['VehicleType']?['model'] ?? ''}"),
            _detailRow("Service Type", "Within City"),
            _detailRow("Payload", "${data['payload']} kg"),
            _detailRow("Registered On", _formatDate(data['registered_date'])),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          const Text(" : ", style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value?.toString() ?? "-", style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ==================== Compliance & Summary ====================
  Widget _buildComplianceAndSummary(dynamic data) {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Compliance Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _complianceItem("RC Certificate", _getDaysLeft(data['rc_validity_date']), Colors.orange),
                _complianceItem("Fitness Certificate", _getDaysLeft(data['fitness_validity_date']), Colors.orange),
                _complianceItem("Permit Document", _getDaysLeft(data['permit_to_date']), Colors.orange),
                _complianceItem("Insurance", _getDaysLeft(data['insurance_upto']), Colors.redAccent),
                _complianceItem("Pollution Cert.", _getDaysLeft(data['pollution_validity_date']), Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text("Document Compliance"),
            subtitle: Text("${data['documents']?.length ?? 0} Documents"),
            trailing: const Text("✓ Good", style: TextStyle(color: Colors.green)),
          ),
        ),
      ],
    );
  }

  Widget _complianceItem(String title, String days, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(title),
      trailing: Text(days, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  // ==================== Documents Section ====================
  Widget _buildDocumentsSection(dynamic data, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Documents & Validity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isTablet ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isTablet ? 1.05 : 0.75,
          children: [
            _documentCard("RC Certificate", _formatDate(data['rc_validity_from_date']), _formatDate(data['rc_validity_date']), _getDaysLeft(data['rc_validity_date']),""),
            _documentCard("Fitness Certificate", _formatDate(data['fitness_validity_from_date']), _formatDate(data['fitness_validity_date']), _getDaysLeft(data['fitness_validity_date']),""),
            _documentCard("Permit Document", _formatDate(data['permit_from_date']), _formatDate(data['permit_to_date']), _getDaysLeft(data['permit_to_date']), data['permit_type']),
            _documentCard("Insurance", _formatDate(data['insurance_from_date']), _formatDate(data['insurance_upto']), _getDaysLeft(data['insurance_upto']),""),
            _documentCard("Pollution Cert.", "-", _formatDate(data['pollution_validity_date']), _getDaysLeft(data['pollution_validity_date']),""),
          ],
        ),
      ],
    );
  }

  Widget _documentCard(String title, String from, String to, String daysLeft, String permit) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ],
            ),
            const SizedBox(height: 12),
            const Text("FROM", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(from, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            const Text("TO", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(to, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 5,),
            Text(permit, style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w500)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Renew"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.amber.shade800,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}