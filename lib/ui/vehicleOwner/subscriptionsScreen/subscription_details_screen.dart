import 'package:flutter/material.dart';
import '../../../resource/app_colors.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const SubscriptionDetailsScreen(this.data, {super.key});

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreen();
}

class _SubscriptionDetailsScreen
    extends State<SubscriptionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final vehicle = widget.data;

    final activeSub = vehicle['active_subscription'];
    final plan = activeSub?['SubscriptionPlan'];

    final history = vehicle['subscription_history'] ?? [];
    final wallet = vehicle['wallet'];
    final transactions = wallet?['transactions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscriptions Details',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            // 🔹 ACTIVE SUBSCRIPTION
            buildCard(
              title: "Active Subscription",
              child: Column(
                children: [
                  buildRow("Plan", plan?['name'] ?? '--'),
                  buildRow(
                      "Weight",
                      "${plan?['weight_category'] ?? '--'} T"),
                  buildRow("Duration",
                      activeSub?['duration_type'] ?? '--'),
                  buildRow("Start",
                      formatDate(activeSub?['start_date'])),
                  buildRow(
                      "End", formatDate(activeSub?['end_date'])),
                  buildStatus(activeSub?['is_active'] == true
                      ? "Active"
                      : "Inactive"),

                  const Divider(),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Amount Paid: ₹${activeSub?['payment_amount'] ?? '0'}"),
                      Text(
                        "${plan?['credit_multiplier'] ?? '--'}x",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 SUBSCRIPTION HISTORY
            buildCard(
              title: "Subscription History",
              child: Column(
                children: history.map<Widget>((item) {
                  final hPlan = item['SubscriptionPlan'];

                  return buildHistoryItem(
                    hPlan?['name'] ?? '--',
                    item['duration_type'] ?? '--',
                    formatDate(item['start_date']),
                    formatDate(item['end_date']),
                    "₹${item['payment_amount']}",
                    item['is_active'] == true,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 WALLET BALANCE
            buildCard(
              title: "Wallet Balance",
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Credits",
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    wallet?['balance_credits'] ?? '0',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("₹${wallet?['balance_amount'] ?? '0'}"),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          color: Colors.green, size: 10),
                      const SizedBox(width: 4),
                      Text(wallet?['status'] ?? '--'),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 TRANSACTION HISTORY
            buildCard(
              title: "Transaction History",
              child: Column(
                children: transactions.map<Widget>((txn) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(txn['type'] ?? '--'),
                            backgroundColor:
                            txn['type'] == 'credit'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                          ),
                          Text(
                            "+${txn['credits']}",
                            style: const TextStyle(
                                color: Colors.green),
                          ),
                          Text("₹${txn['amount_paid']}"),
                          Text(txn['balance_after'] ?? '--'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          txn['description'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 DATE FORMATTER
  String formatDate(String? date) {
    if (date == null) return '--';
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    return "${d.day} ${monthName(d.month)} ${d.year}";
  }

  String monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  // 🔹 CARD
  Widget buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          child
        ],
      ),
    );
  }

  // 🔹 ROW
  Widget buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 🔹 STATUS
  Widget buildStatus(String status) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: status == "Active"
              ? Colors.green.shade100
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: status == "Active"
                ? Colors.green
                : Colors.black54,
          ),
        ),
      ),
    );
  }

  // 🔹 HISTORY ITEM
  Widget buildHistoryItem(String plan, String duration,
      String start, String end, String amount, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(plan,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              Text(duration),
              Text(amount),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? "Active" : "Expired",
                  style: TextStyle(
                    color: isActive
                        ? Colors.green
                        : Colors.black54,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(start,
                  style:
                  const TextStyle(color: Colors.grey)),
              Text(end,
                  style:
                  const TextStyle(color: Colors.grey)),
            ],
          ),
          const Divider()
        ],
      ),
    );
  }
}