import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../provider_service/fleet_subscriptions_provider.dart';
import '../../resource/pref_utils.dart';

class WalletDialog extends StatefulWidget {
  final String vehicleId;
  final String vehicleNumber;

  WalletDialog(this.vehicleId, this.vehicleNumber);

  @override
  State<WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<WalletDialog> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FleetSubscriptionsProvider>(
        context,
        listen: false,
      ).fetchSubscriptions(widget.vehicleId, 'dialog');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
        ),
        child: Consumer<FleetSubscriptionsProvider>(
          builder: (context, provider, _) {
            /// LOADING
            if (provider.isLoading) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            /// EMPTY
            if (provider.subscriptionsmap.isEmpty) {
              return Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E9D8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text('No subscription available'),
                ),
              );
            }

            /// MAIN CONTENT (SCROLL FIX APPLIED HERE)
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HEADER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F7C6B),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "WALLET & SUBSCRIPTION",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.vehicleNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// BODY
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          /// PLAN CARD
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(16),
                              border:
                              Border.all(color: Colors.teal.shade100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Normal Plan — Active",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Valid till ${provider.subscriptionsmap['end_date']} · ${provider.subscriptionsmap['SubscriptionPlan']['commission_percentage']}% commission",
                                        style:
                                        const TextStyle(color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    String url =
                                        "https://vehicleowner.gocarriage.com/plans?"
                                        "fleet_id=${PrefUtils.getUserId()}"
                                        "&vnum=${widget.vehicleId}";
                                    openRechargeUrl(url);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF0F8A7B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Upgrade →",
                                    style:
                                    TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// WALLET CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F7C6B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "WALLET BALANCE",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "${provider.subscriptionsmap['payment_amount']} credits",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "≈ ₹${provider.subscriptionsmap['payment_amount']}",
                                  style: const TextStyle(
                                      color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    provider.subscriptionsmap[
                                    'is_active'] ==
                                        true
                                        ? 'Active'
                                        : 'In-Active',
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// RECHARGE BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                String url =
                                    "https://gocarriage.com/wallet/recharge?"
                                    "fleet_id=${PrefUtils.getUserId()}"
                                    "&vehicle=${widget.vehicleId}";
                                openRechargeUrl(url);
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(
                                    vertical: 16),
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "⚡ Recharge Wallet  ↗ GoCarriage website",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// TRANSACTION HEADER
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Transaction History",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.refresh, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    "Refresh",
                                    style:
                                    TextStyle(color: Colors.teal),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          /// EMPTY STATE
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.inbox,
                                    size: 40,
                                    color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  "No transactions yet",
                                  style:
                                  TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> openRechargeUrl(String mUrl) async {
    final uri = Uri.parse(mUrl);

    if (!await launchUrl(uri,
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $mUrl');
    }
  }
}