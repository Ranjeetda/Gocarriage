import 'package:flutter/material.dart';
import 'package:gocarriage_universal/screens/dashboardScreen/corporateScreen/widget/live_shipment_empty_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../provider_service/corprote_booking_activity.dart';
import '../../provider_service/corprote_booking_dashboard.dart';
import '../../provider_service/corprote_me_service.dart';
import '../../provider_service/corprote_offer.dart';
import '../dialogBox/corporate_benefits_dialog.dart';


class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorproteBookingDashboard>().fetchBooking();
      context.read<CorproteBookingActivity>().fetchBookingActivity();
      context.read<CorproteOffer>().fetchBookingActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Consumer<CorproteBookingDashboard>(
          builder: (context, dashboard, _) {
            if (dashboard.isLoading && dashboard.bookingData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = dashboard.bookingData ?? {};
            final stats = data['stats'] as Map<String, dynamic>? ?? {};
            final liveShipment = data['liveShipment'];
            final statusOverview = data['statusOverview'] as List? ?? [];
            final recentShipments = data['recentShipments'] as List? ?? [];
            final topRoutes = data['topRoutes'] as List? ?? [];
            final shipmentsTrend = data['shipmentsTrend'] as Map<String, dynamic>? ?? {};
            final trendPoints = shipmentsTrend['points'] as List? ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Exclusive Offers ──
                  _sectionHeader(
                    icon: Icons.local_fire_department,
                    title: 'Exclusive Offers for You',
                    action: 'View All',
                    onTap: () {

                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer<CorproteOffer>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                      }
                      final offers = provider.offerListData;
                      if (offers.isEmpty) {
                        return const SizedBox(height: 80, child: Center(child: Text('No offers available')));
                      }
                      return SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: offers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            return SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              child: _offerCard(
                                badge: offer['badgeText']?.toString() ?? 'Exclusive',
                                title: offer['title']?.toString() ?? '',
                                subtitle: offer['description']?.toString() ?? '',
                                code: offer['code']?.toString() ?? '',
                                validTill: offer['valid_to']?.toString() ?? '',
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Stats Grid ──
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      _statCard(
                        icon: Icons.local_shipping_outlined,
                        bg: const Color(0xFFE3F2FD),
                        color: Colors.blue,
                        value: '${stats['activeShipments'] ?? 0}',
                        label: 'Active Shipments',
                        sub: '${stats['inTransit'] ?? 0} In Transit',
                      ),
                      _statCard(
                        icon: Icons.calendar_today_outlined,
                        bg: const Color(0xFFFFF3E0),
                        color: Colors.orange,
                        value: '${stats['upcomingPickups'] ?? 0}',
                        label: 'Upcoming Pickups',
                        sub: 'Next 7 days',
                      ),
                      _statCard(
                        icon: Icons.check_circle_outline,
                        bg: const Color(0xFFE8F5E9),
                        color: Colors.green,
                        value: '${stats['completedTrips'] ?? 0}',
                        label: 'Completed Trips',
                        sub: 'This Month',
                      ),
                      _statCard(
                        icon: Icons.account_balance_wallet_outlined,
                        bg: const Color(0xFFF3E5F5),
                        color: Colors.purple,
                        value: '₹${stats['totalSpent'] ?? 0}',
                        label: 'Total Spent',
                        sub: 'This Month',
                      ),
                      _statCard(
                        icon: Icons.local_offer_outlined,
                        bg: const Color(0xFFFFEBEE),
                        color: Colors.pink,
                        value: '₹${stats['totalSavings'] ?? 0}',
                        label: 'Total Savings',
                        sub: 'This Year',
                      ),
                      _statCard(
                        icon: Icons.bar_chart_outlined,
                        bg: const Color(0xFFE3F2FD),
                        color: Colors.blue,
                        value: '${stats['totalBookings'] ?? 0}',
                        label: 'Total Bookings',
                        sub: 'All Time',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Premium Plan ──
                  _premiumPlanCard(),

                  const SizedBox(height: 20),

                  // ── Relationship Manager ──
                  _relationshipManagerCard(),

                  const SizedBox(height: 20),

                  // ── Corporate Benefits ──
                  _corporateBenefitsCard(),

                  const SizedBox(height: 20),

                  // ── Live Shipment ──
                  if (liveShipment == null)
                    LiveShipmentEmptyState(onBookVehicle: () {})
                  else
                    _liveShipmentCard(liveShipment),

                  const SizedBox(height: 20),

                  // ── Shipment Overview ──
                  _shipmentOverviewCard(statusOverview, stats['totalBookings'] ?? 21),

                  const SizedBox(height: 20),

                  // ── Shipments Trend ──
                  _shipmentsTrendCard(trendPoints),

                  const SizedBox(height: 20),

                  // ── Recent Shipments ──
                  _recentShipmentsCard(recentShipments),

                  const SizedBox(height: 20),

                  // ── Plan Savings ──
                  _planSavingsCard(stats),

                  const SizedBox(height: 20),

                  // ── Top Lanes ──
                  _topLanesCard(topRoutes),

                  const SizedBox(height: 20),

                  // ── Quick Actions ──
                  _quickActionsCard(),

                  const SizedBox(height: 20),

                  // ── Team Overview ──
                  _teamOverviewCard(),

                  const SizedBox(height: 20),

                  // ── Recent Activity ──
                  _recentActivityCard(),

                  const SizedBox(height: 20),

                  // ── Upcoming Pickups ──
                  _upcomingPickupsCard(data['upcomingPickups'] as List? ?? []),

                  const SizedBox(height: 20),

                  // ── Wallet Balance ──
                  _walletBalanceCard(),

                  const SizedBox(height: 20),

                  // ── Billing & Credit ──
                  _billingCreditCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────────── Helpers ─────────────────────

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text(action, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }

  // ───────────────────── Offer Card ─────────────────────

  Widget _offerCard({
    required String badge,
    required String title,
    required String subtitle,
    required String code,
    required String validTill,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade50),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.percent, color: Colors.red, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text('Use Code: $code', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(height: 4),
          Text('Valid till $validTill', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ───────────────────── Stat Card ─────────────────────

  Widget _statCard({
    required IconData icon,
    required Color bg,
    required Color color,
    required String value,
    required String label,
    required String sub,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ───────────────────── Premium Plan ─────────────────────

  Widget _premiumPlanCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "You're on Premium Corporate Plan",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          ...['35% Better Rates', 'Priority Support', 'Dedicated RM', 'Credit Facility', 'Advanced Analytics', 'Bulk Booking']
              .map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CorporateBenefitsDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View All Benefits', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Relationship Manager ─────────────────────

  Widget _relationshipManagerCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_outline, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relationship Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Premium corporate support', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Icon(Icons.person_off_outlined, size: 42, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('No relationship manager assigned yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ───────────────────── Corporate Benefits ─────────────────────

  Widget _corporateBenefitsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Corporate Benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Real impact from your premium plan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Text('Updated today', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _benefitMini(Icons.percent, Colors.green, 'Maximum Discount', '₹0', 'Saved this year'),
              _benefitMini(Icons.inventory_2_outlined, Colors.blue, 'Bulk Booking', '0', 'Bulk orders placed'),
              _benefitMini(Icons.search, Colors.purple, 'Vehicle Search', '0', 'Vehicles compared'),
              _benefitMini(Icons.smart_toy_outlined, Colors.blue, 'AI-Assisted Booking', '0%', 'Bookings AI-assisted'),
              _benefitMini(Icons.location_on_outlined, Colors.teal, 'Live Tracking', '0%', 'GPS uptime'),
              _benefitMini(Icons.trending_down, Colors.orange, 'Freight Cost', '0%', 'Below market rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefitMini(IconData icon, Color color, String title, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ───────────────────── Live Shipment (fixed structure) ─────────────────────

  Widget _liveShipmentCard(Map<String, dynamic> live) {
    final ref = live['ref']?.toString() ?? '—';
    final status = live['status']?.toString() ?? live['vehicleStatus']?.toString() ?? 'TENDERING';
    final pickupLoc = live['pickup']?['location']?.toString() ?? 'Pickup Address';
    final deliveryLoc = live['delivery']?['location']?.toString() ?? 'Delivery Address';
    final pickupDate = live['pickup']?['date'];
    String dateStr = '';
    if (pickupDate != null) {
      try {
        final dt = DateTime.parse(pickupDate.toString());
        dateStr = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {}
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Live Shipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(status, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ref, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(pickupLoc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (dateStr.isNotEmpty) Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Delivery', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(deliveryLoc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress steps – TENDERING is step 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final labels = ['ACCEPTED', 'LOADING', 'IN TRANSIT', 'UNLOADING', 'COMPLETED'];
              final active = i == 0; // TENDERING ≈ ACCEPTED stage
              return Column(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: active ? Colors.blue : Colors.grey.shade300,
                    child: Text('${i + 1}', style: TextStyle(fontSize: 9, color: active ? Colors.white : Colors.grey.shade600)),
                  ),
                  const SizedBox(height: 3),
                  Text(labels[i], style: TextStyle(fontSize: 8, color: active ? Colors.blue : Colors.grey)),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Shipment Details'),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Shipment Overview ─────────────────────

  Widget _shipmentOverviewCard(List statusOverview, dynamic totalBookings) {
    int total = totalBookings is int ? totalBookings : 21;
    int tendering = 0;
    int cancelled = 0;
    double tenderingPct = 0;
    double cancelledPct = 0;

    for (final item in statusOverview) {
      if (item is Map) {
        if (item['status'] == 'TENDERING') {
          tendering = item['count'] ?? 0;
          tenderingPct = (item['pct'] ?? 0).toDouble();
        } else if (item['status'] == 'CANCELLED') {
          cancelled = item['count'] ?? 0;
          cancelledPct = (item['pct'] ?? 0).toDouble();
        }
      }
    }

    return _card(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Shipment Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : cancelled / total,
                    strokeWidth: 12,
                    backgroundColor: Colors.blue.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Total Shipments', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(Colors.blue.shade300, 'TENDERING', '$tendering (${tenderingPct.toStringAsFixed(1)}%)'),
              const SizedBox(width: 20),
              _legend(Colors.redAccent, 'CANCELLED', '$cancelled (${cancelledPct.toStringAsFixed(1)}%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ───────────────────── Shipments Trend ─────────────────────

  Widget _shipmentsTrendCard(List points) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipments Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('This Month', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: points.isEmpty
                ? const Center(child: Text('No trend data', style: TextStyle(color: Colors.grey)))
                : CustomPaint(painter: _TrendLinePainter(points)),
          ),
          const SizedBox(height: 6),
          if (points.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points.map((p) {
                final bucket = p['bucket']?.toString() ?? '';
                String label = bucket;
                try {
                  final dt = DateTime.parse(bucket);
                  label = DateFormat('dd MMM').format(dt);
                } catch (_) {}
                return Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600));
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ───────────────────── Recent Shipments ─────────────────────

  Widget _recentShipmentsCard(List list) {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Shipments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No recent shipments', style: TextStyle(color: Colors.grey)),
            )
          else
            ...list.take(5).map((s) {
              final status = s['status']?.toString() ?? '';
              final cancelled = status == 'CANCELLED';
              final amount = s['amount'];
              final amountStr = amount != null ? '₹${NumberFormat('#,##0').format(amount)}' : '—';
              final from = s['from']?.toString() ?? '';
              final to = s['to']?.toString() ?? '';
              final shortFrom = from.split(',').first;
              final shortTo = to.split(',').first;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s['ref']?.toString() ?? '—',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cancelled ? Colors.red.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cancelled ? Colors.red : Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$shortFrom → $shortTo',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(amountStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────────────── Plan Savings ─────────────────────

  Widget _planSavingsCard(Map stats) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plan Savings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('This Year', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Total Savings', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('₹${stats['totalSavings'] ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text('+0% vs last year', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
          const Divider(height: 24),
          _row('Better Rates', '0%'),
          _row('Bulk Discounts', '₹0'),
          _row('Operational Efficiency', '0%'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ───────────────────── Top Lanes ─────────────────────

  Widget _topLanesCard(List routes) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Lanes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('By trips', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          if (routes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No route data', style: TextStyle(color: Colors.grey)),
            )
          else
            ...routes.take(5).map((r) {
              final from = (r['from']?.toString() ?? '').split(',').first;
              final to = (r['to']?.toString() ?? '').split(',').first;
              final trips = r['trips'] ?? 0;
              final maxTrips = routes.map((e) => e['trips'] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
              final progress = maxTrips == 0 ? 0.0 : trips / maxTrips;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$from → $to',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('$trips', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────────────── Quick Actions ─────────────────────

  Widget _quickActionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickBtn(Icons.inventory_2_outlined, 'Book Bulk\nVehicles'),
              const SizedBox(width: 10),
              _quickBtn(Icons.person_add_outlined, 'Add Team\nMember'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickBtn(Icons.description_outlined, 'Download\nReports'),
              const SizedBox(width: 10),
              _quickBtn(Icons.flash_on_outlined, 'Get Instant\nQuote'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.blue),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Team Overview ─────────────────────

  Widget _teamOverviewCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Team Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _teamRow(Icons.people_outline, 'Total Members', '0'),
          _teamRow(Icons.check_circle_outline, 'Active Members', '0'),
          _teamRow(Icons.security_outlined, 'Roles', '0'),
          _teamRow(Icons.groups_outlined, 'Teams', '0'),
        ],
      ),
    );
  }

  Widget _teamRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ───────────────────── Recent Activity ─────────────────────

  Widget _recentActivityCard() {
    // You can later wire this from CorproteBookingActivity provider
    final items = [
      {'type': 'booked', 'title': 'Shipment Booked', 'id': 'BK_281404dc-...', 'time': '21h ago'},
      {'type': 'cancelled', 'title': 'Shipment Cancelled', 'id': 'BK_1da5b5f4-...', 'time': '23h ago'},
      {'type': 'booked', 'title': 'Shipment Booked', 'id': 'BK_1da5b5f4-...', 'time': '23h ago'},
      {'type': 'cancelled', 'title': 'Shipment Cancelled', 'id': 'BK_27fcd365-...', 'time': '1d ago'},
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((a) {
            final cancelled = a['type'] == 'cancelled';
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(color: cancelled ? Colors.red : Colors.blue, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(a['id']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(a['time']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────────────── Upcoming Pickups ─────────────────────

  Widget _upcomingPickupsCard(List pickups) {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Pickups', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          if (pickups.isEmpty) ...[
            const SizedBox(height: 30),
            Icon(Icons.calendar_today_outlined, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No upcoming pickups', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 16),
          ] else
          // render list if available
            ...pickups.map((p) => ListTile(title: Text(p.toString()))),
        ],
      ),
    );
  }

  // ───────────────────── Wallet & Billing (still static – no data yet) ─────────────────────

  Widget _walletBalanceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('₹0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('+ Add Money', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _billingCreditCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Billing & Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Balance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('₹0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Pay Now'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Credit Limit: ₹0', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text('Available: ₹0', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('0% of credit limit used', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ───────────────────── Trend Painter (real data) ─────────────────────

class _TrendLinePainter extends CustomPainter {
  final List points;
  _TrendLinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final counts = points.map((p) => (p['count'] as num?)?.toDouble() ?? 0.0).toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < counts.length; i++) {
      final x = counts.length == 1 ? size.width / 2 : (i / (counts.length - 1)) * size.width;
      final y = size.height - (counts[i] / maxCount) * size.height * 0.85;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.withOpacity(0.25), Colors.blue.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}