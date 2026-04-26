import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/Utils.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/fleet_subscriptions_provider.dart';
import '../../../provider_service/transactions_history_provider.dart';
import '../../../provider_service/vehicle_details_provider.dart';
import '../../../resource/app_colors.dart';
import '../../dialogBox/document_upload_dialog.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen(this.vehicleId, {super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final DateFormat _dateFormat = DateFormat("dd MMM yyyy");
  bool isLoading = false;

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
      Provider.of<VehicleDetailsProvider>(
        context,
        listen: false,
      ).fetchBooking(widget.vehicleId);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FleetSubscriptionsProvider>(
        context,
        listen: false,
      ).fetchSubscriptions(widget.vehicleId, 'class');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionsHistoryProvider>(
        context,
        listen: false,
      ).fetchSubscriptions(widget.vehicleId);
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
              return const SizedBox(
                height: 500,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (provider.vehicleDetailsData == null) {
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
                            Expanded(
                              child: _buildVehicleDetailsCard(
                                provider.vehicleDetailsData,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildComplianceAndSummary(
                                provider.vehicleDetailsData,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildVehicleDetailsCard(
                              provider.vehicleDetailsData,
                            ),
                            const SizedBox(height: 16),
                            _buildRoadTax(provider.vehicleDetailsData),
                            const SizedBox(height: 16),
                            _buildRoadTax(provider.vehicleDetailsData),
                            const SizedBox(height: 16),
                            _ownerDetails(provider.vehicleDetailsData),
                            const SizedBox(height: 16),
                            _locationTrip(provider.vehicleDetailsData),
                            const SizedBox(height: 16),
                            Consumer<FleetSubscriptionsProvider>(
                              builder: (context, provider, _) {
                                if (provider.isLoading) {
                                  return const SizedBox(
                                    height: 500,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (provider.subscriptions.isEmpty) {
                                  return Center(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6E9D8),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// HEADER
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: const Icon(
                                                  Icons.local_shipping,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: const [
                                                    Text(
                                                      "Your vehicle is ready!",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "Subscribe to a plan and start earning money with credits.",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),

                                          /// FEATURES
                                          Column(
                                            children: [
                                              _featureTile(
                                                "Earn credits on every recharge",
                                              ),
                                              _featureTile(
                                                "Lower commission rates on premium plans",
                                              ),
                                              _featureTile(
                                                "Flexible monthly, 3-month, 6-month & yearly plans",
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 18),

                                          /// BUTTON
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                String url =
                                                    "https://vehicleowner.gocarriage.com/plans?"
                                                    "fleet_id=${PrefUtils.getUserId()}"
                                                    "&vnum=${widget.vehicleId}";
                                                openRechargeUrl(url);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                elevation: 2,
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Choose a Plan",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Icon(
                                                    Icons.open_in_new,
                                                    size: 18,
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

                                return Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: provider.subscriptions.length,
                                      itemBuilder: (context, index) {
                                        return _subscriptionWallet(
                                          provider.subscriptions[index],
                                        );
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: provider.subscriptions.length,
                                      itemBuilder: (context, index) {
                                        return _subscriptionHistory(
                                          provider.subscriptions[index],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),

                            Consumer<TransactionsHistoryProvider>(
                              builder: (context, provider, _) {
                                if (provider.isLoading) {
                                  return const SizedBox(
                                    height: 500,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (provider.transactionsHistory.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No Transactions History available',
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount:
                                      provider.transactionsHistory.length,
                                  itemBuilder: (context, index) {
                                    return _subscriptionHistory(
                                      provider.transactionsHistory[index],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildComplianceAndSummary(
                              provider.vehicleDetailsData,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDocumentsSection(
                    provider.vehicleDetailsData!['documents'],
                    isTablet,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _featureTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ==================== Top Banner ====================
  Widget _buildTopBanner(dynamic data, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF009688)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 48,
                  color: Color(0xFF00695C),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['vehicle_number'] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (data['status'] ?? "active")
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${data['VehicleType']?['brand'] ?? ''} ${data['VehicleType']?['model'] ?? ''} • Within City",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip(
                "Vehicle Age",
                "<1 mo",
                "Since ${_formatDate(data['registered_date'])}",
              ),
              _infoChip("Payload", "${data['payload'] ?? '0'} kg", "Capacity"),
              _infoChip(
                "Fuel",
                data['fuel_type'] ?? "Diesel",
                data['color'] ?? "Red",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String title, String value, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  // ==================== Vehicle Details Card ====================
  Widget _buildVehicleDetailsCard(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vehicle Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _detailRow("Chassis Number", data['chassis_number']),
            _detailRow("Engine Number", data['engine_number']),
            _detailRow("Fuel Type", data['fuel_type']),
            _detailRow("Color", data['color']),
            _detailRow("RTO", data['rto']),
            _detailRow(
              "Brand / Model",
              "${data['VehicleType']?['brand'] ?? ''} • ${data['VehicleType']?['model'] ?? ''}",
            ),
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
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(" : ", style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Compliance & Summary ====================
  Widget _buildComplianceAndSummary(dynamic data) {
    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Compliance Status",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _complianceItem(
                  "RC Certificate",
                  _getDaysLeft(data['rc_validity_date']),
                  Colors.orange,
                ),
                _complianceItem(
                  "Fitness Certificate",
                  _getDaysLeft(data['fitness_validity_date']),
                  Colors.orange,
                ),
                _complianceItem(
                  "Permit Document",
                  _getDaysLeft(data['permit_to_date']),
                  Colors.orange,
                ),
                _complianceItem(
                  "Insurance",
                  _getDaysLeft(data['insurance_upto']),
                  Colors.redAccent,
                ),
                _complianceItem(
                  "Pollution Cert.",
                  _getDaysLeft(data['pollution_validity_date']),
                  Colors.orange,
                ),
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
            trailing: const Text(
              "✓ Good",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadTax(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rod Tax Status",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _complianceItem(
              "Road Tax Paid",
              data['road_tax_paid'] == true ? 'Yes' : 'No',
              Colors.orange,
            ),
            _complianceItem(
              "Tax Period",
              data['road_tax_paid_period'] ?? '',
              Colors.orange,
            ),
            _complianceItem("Permit Type", data['permit_type'], Colors.orange),
            _complianceItem(
              "Permit From",
              data['permit_from_date'] ?? '',
              Colors.redAccent,
            ),
            _complianceItem(
              "Permit Upto",
              data['pollution_validity_date'] ?? '',
              Colors.orange,
            ),
            _complianceItem(
              "Permit Upto",
              data['pollution_validity_date'] ?? '',
              Colors.orange,
            ),
            Utils.getPermitStates(data['permit_states']).isNotEmpty
                ? Wrap(
              spacing: 8,
              children: Utils.getPermitStates(data['permit_states']).map<Widget>((state) {
                return Chip(label: Text(state));
              }).toList(),
            )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  Widget _ownerDetails(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Owner Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _complianceItem(
              "Owner Name",
              data['Owner']['ownerName'],
              Colors.orange,
            ),
            _complianceItem("Email", data['Owner']['email'], Colors.orange),
            _complianceItem("Address", data['Owner']['address'], Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _locationTrip(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Location & Trip",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _complianceItem(
              "Current City",
              data['location']['current_city'],
              Colors.orange,
            ),
            _complianceItem(
              "Trip Status",
              data['location']['trip_status'],
              Colors.orange,
            ),
            _complianceItem(
              "Last Updated",
              Utils.formatToDDMMYYYY(data['location']['last_updated']),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionWallet(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Subscription & Wallet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _complianceItem(
              "Plan Name",
              data['SubscriptionPlan']['name'],
              Colors.orange,
            ),
            _complianceItem(
              "Weight Category",
              data['SubscriptionPlan']['weight_category'],
              Colors.orange,
            ),
            _complianceItem("Duration", data['duration_type'], Colors.orange),
            _complianceItem("Start Date", data['start_date'], Colors.orange),
            _complianceItem("End Date", data['end_date'], Colors.orange),
            _complianceItem(
              "Commission",
              data['SubscriptionPlan']['commission_percentage'],
              Colors.orange,
            ),
            _complianceItem(
              "Amount Paid ",
              data['payment_amount'],
              Colors.orange,
            ),
            _complianceItem(
              "Credit Multiplier ",
              data['SubscriptionPlan']['credit_multiplier'],
              Colors.orange,
            ),
            _complianceItem(
              "Status",
              data['is_active'] == true ? 'Active' : 'No-Active',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionHistory(dynamic data) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Subscription History",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _complianceItem(
              "Plan",
              data['SubscriptionPlan']['name'],
              Colors.orange,
            ),
            _complianceItem("Duration", data['duration_type'], Colors.orange),
            _complianceItem("Start Date", data['start_date'], Colors.orange),
            _complianceItem("End Date", data['end_date'], Colors.orange),

            _complianceItem(
              "Amount Paid ",
              data['payment_amount'],
              Colors.orange,
            ),
            _complianceItem(
              "Status",
              data['is_active'] == true ? 'Active' : 'No-Active',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceItem(String title, String days, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(title),
      trailing: Text(
        days,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==================== Documents Section ====================
  String getTitle(String type) {
    switch (type) {
      case "rc_document":
        return "RC Certificate";
      case "fitness_certificate":
        return "Fitness Certificate";
      case "permit_document":
        return "Permit Document";
      case "insurance":
        return "Insurance";
      case "pollution_certificate":
        return "Pollution Cert.";
      default:
        return type;
    }
  }

  Map<String, dynamic> getLatestDocuments(List docs) {
    Map<String, List> grouped = {};

    /// Group by document_type
    for (var doc in docs) {
      String type = doc['document_type'];
      grouped.putIfAbsent(type, () => []).add(doc);
    }

    Map<String, dynamic> result = {};

    grouped.forEach((type, list) {
      /// Prefer ACTIVE, else latest by date
      list.sort(
        (a, b) => DateTime.parse(
          b['valid_to'],
        ).compareTo(DateTime.parse(a['valid_to'])),
      );

      var activeDoc = list.firstWhere(
        (d) => d['status'] == 'active',
        orElse: () => list.first,
      );

      result[type] = activeDoc;
    });

    return result;
  }

  Widget _buildDocumentsSection(List documents, bool isTablet) {
    final latestDocs = getLatestDocuments(
      documents.isEmpty ? Utils.documents : documents,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Documents & Validity",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestDocs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.0 : 0.6,
          ),
          itemBuilder: (context, index) {
            final key = latestDocs.keys.elementAt(index);
            final doc = latestDocs[key];

            return _documentCard(
              getTitle(key),
              _formatDate(doc['valid_from']),
              _formatDate(doc['valid_to']),
              _getDaysLeft(doc['valid_to']),
              doc['file_path'],
              setLoading: setLoading,
            );
          },
        ),
      ],
    );
  }

  Widget _documentCard(
    String title,
    String from,
    String to,
    String daysLeft,
    String? url, {
    Function(bool)? setLoading,
  }) {
    final safeUrl =
        (url != null && url.isNotEmpty) ? Uri.encodeFull(url) : null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                const Icon(Icons.description, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// FROM
            const Text(
              "FROM",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              from,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),

            const SizedBox(height: 8),

            /// TO
            const Text(
              "TO",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              to,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),

            const SizedBox(height: 10),

            /// DAYS LEFT BADGE
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      daysLeft.contains("Expired")
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysLeft,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        daysLeft.contains("Expired")
                            ? Colors.red
                            : Colors.green,
                  ),
                ),
              ),
            ),

            const Spacer(),

            /// BUTTONS
            Row(
              children: [
                /// RENEW BUTTON
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) =>
                                DocumentUploadDialog(widget.vehicleId, title),
                      );
                    },
                    label: const Text("Renew"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.amber.shade800,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// VIEW BUTTON
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
                  onPressed: () {
                    if (safeUrl != null) {
                      _showImage(safeUrl, setLoading!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No file available")),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImage(String fileName, Function(bool) setLoading) async {
    setLoading(true);
    final response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);
    var responseData = json.decode(response.body);
    setLoading(false);

    if (responseData['success'] == true &&
        responseData['data']?['url'] != null) {
      showImagePreview(context, responseData['data']['url']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData?['message'] ?? 'Failed to load image'),
        ),
      );
    }
  }

  void showImagePreview(BuildContext context, String imageUrl) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.1,
            ),
            child: Container(
              width: size.width * 0.9,
              height: size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.network(imageUrl, fit: BoxFit.contain),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Preview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> openRechargeUrl(String mUrl) async {
    final uri = Uri.parse(mUrl);
    print("openRechargeUrl ============${uri}");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $mUrl');
    }
  }
}
