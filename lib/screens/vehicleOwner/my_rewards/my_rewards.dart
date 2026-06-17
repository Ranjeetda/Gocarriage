import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/profile_provider.dart';
import '../../../provider_service/reward_wallet_provider.dart';
import '../../../resource/Utils.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  String balance = "--";
  String lifetimeEarned = "--";
  String burned = "--";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<RewardWalletProvider>(
        context,
        listen: false,
      );
      await provider.fetchRewardsWallet();
      if (provider.rewardWallet!.isNotEmpty) {
        setState(() {
          print(
            "RanjeetTESt====================================${provider.rewardWallet!['balance'].toString()}",
          );
          balance = provider.rewardWallet!['balance'].toString();
          lifetimeEarned = provider.rewardWallet!['lifetime_earned'].toString();
          burned = provider.rewardWallet!['lifetime_burned'].toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // 👈 makes back button white
        title: const Text("My Rewards", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),

            _sectionTitle("Reward Progress"),

            Consumer<ProfileProvider>(
              builder: (context, mProfileData, child) {
                if (mProfileData.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mProfileData.rewardsProgress.length,
                  itemBuilder: (context, index) {
                    final item = mProfileData.rewardsProgress[index];
                    return _milestoneCard(
                      title: item['label'],
                      amount: item['points'].toString(),
                      date: Utils.formatToDDMMYYYY(
                        item['last_earned_at'] ?? '2026-05-27T13:20:34.000Z',
                      ),
                      completed: item['earned'],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rewards",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            "Track your reward amount, milestones & lifetime progress",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow),
                  const SizedBox(width: 6),
                  Text(
                    "₹$balance",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "available",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹$lifetimeEarned",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Text(
                    "Lifetime",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹$burned", style: const TextStyle(color: Colors.white)),
                  const Text(
                    "Balance",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  // ================= CARD =================

  Widget _milestoneCard({
    required String title,
    required String amount,
    bool completed = false,
    String? date,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                completed ? Colors.green.shade100 : Colors.grey.shade300,
            child: Icon(
              completed ? Icons.card_giftcard : Icons.lock,
              color: completed ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      "+₹$amount",
                      style: TextStyle(
                        color: completed ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        "• $date",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (completed) const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}
