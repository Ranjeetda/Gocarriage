import 'package:flutter/material.dart';
import 'package:gocarriage_universal/ui/vehicleOwner/subscriptionsScreen/subscription_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../provider_service/subscriptions_owner_list_provider.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/pref_utils.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreen();
}

class _SubscriptionsScreen extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<SubscriptionsOwnerListProvider>(
        context,
        listen: false,
      );
      await provider.fetchList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscriptions & Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<SubscriptionsOwnerListProvider>(
        builder: (context, provider, _) {
          // 🔄 Loading
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Empty
          if (provider.listData.isEmpty) {
            return const Center(child: Text("No Subscriptions & Wallet found"));
          }

          // ✅ Data
          return ListView.builder(
            itemCount: provider.listData.length,
            itemBuilder: (context, index) {
              return buildVehicleItem(provider.listData[index]);
            },
          );
        },
      ),
    );
  }

  // 🔥 Expandable Item
  Widget buildVehicleItem(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        // 🔹 HEADER
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "${data['vehicle_number']}\n${data['VehicleType']?['name']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['active_subscription']?['SubscriptionPlan']?['name'] ??
                    'No Plan',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),

        // 🔽 DETAILS
        children: [
          buildRow("Weight", data['payload']),
          buildRow(
            "Duration",
            data['active_subscription']?['duration_type'] ?? '--',
          ),
          buildRow("Start", data['active_subscription']?['start_date'] ?? '--'),
          buildRow("End", data['active_subscription']?['end_date'] ?? '--'),
          buildStatusRow("Status", data['status'] ?? 'Unknown'),
          buildRow(
            "Commission",
            data['active_subscription']?['SubscriptionPlan']?['commission_percentage'] ??
                'N--',
          ),
          buildRow("Credits", data['wallet']['balance_credits'] ?? '--'),
          buildRow("Wallet", data['wallet']['balance_amount'] ?? '--'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarycolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _navigateTo(SubscriptionDetailsScreen(data));
                  },
                  child: const Text(
                    "View",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarycolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    String  url =
                        "https://vehicleowner.gocarriage.com/plans?"
                        "fleet_id=${PrefUtils.getUserId()}"
                        "&vnum=${data['vehicle_number']}";
                    openRechargeUrl(url);
                  },
                  child: const Text(
                    "Upgrade",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarycolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showRechargeDialog(
                      context,
                      data['vehicle_number'] ?? '',
                      data['VehicleType']['name'],
                    );
                  },
                  child: const Text(
                    "Recharge",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

      ),
    );
  }

  // 🔹 Normal Row
  Widget buildRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 🟢 Status Row
  Widget buildStatusRow(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void showRechargeDialog(
    BuildContext context,
    String vechilNumber,
    String VehicleType,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🟧 HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF8A00), Color(0xFFFF6A00)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "WALLET • $vechilNumber",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Recharge Credits",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ❌ Close Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // ⚪ BODY
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 🔶 Icon Box
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE4D3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: Color(0xFFB98B2E),
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        "Recharge on GoCarriage",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description
                      const Text.rich(
                        TextSpan(
                          text: "Wallet recharge is done on the ",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: "GoCarriage main website",
                              style: TextStyle(
                                color: Color(0xFFFF6A00),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ". You'll be redirected there to complete your recharge securely.",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // 📦 Beige Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E9D7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Recharging wallet for",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  vechilNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  VehicleType,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 🔘 Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6A00),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  String  url =
                                  "https://gocarriage.com/wallet/recharge?"
                                      "fleet_id=${PrefUtils.getUserId()}"
                                      "&vnum=${vechilNumber}";
                                  openRechargeUrl(url);
                                },
                                icon: const Icon(
                                  Icons.bolt,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Go to Recharge",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Footer
                      const Text(
                        "You will be redirected to https://gocarriage.com",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> openRechargeUrl(String mUrl) async {
    final uri = Uri.parse(mUrl);
    print("openRechargeUrl ============${uri}");

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $mUrl');
    }
  }
}
