import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../provider_service/fleet_vehicle_list_provider.dart';

class RespondToBookingSheet extends StatefulWidget {
  final String bookingCode;
  final String customerOffer;           // e.g. "120795"
  final String customerWantedDate;      // e.g. "24 Sept, 6:00 am"
  final String reachByTime;             // e.g. "Reach by 5:45 am"
  final String vehiclesId;
  final Function(String vehicleNumber) onAccept;
  final Function(String vehicleNumber, int counterPrice) onCounterOffer;

  const RespondToBookingSheet({
    super.key,
    required this.bookingCode,
    required this.customerOffer,
    required this.customerWantedDate,
    required this.reachByTime,
    required this.vehiclesId,
    required this.onAccept,
    required this.onCounterOffer,
  });

  @override
  State<RespondToBookingSheet> createState() => _RespondToBookingSheetState();
}

class _RespondToBookingSheetState extends State<RespondToBookingSheet> {
  String? selectedVehicle;
  int? selectedIndex;
  final TextEditingController _counterController = TextEditingController();
  int? counterPrice;

  @override
  void initState() {
    super.initState();
    // Pre-fill with a slightly higher value (optional)
    final offer = int.tryParse(widget.customerOffer.replaceAll(',', '')) ?? 0;
    _counterController.text = (offer + 5000).toString();
    counterPrice = offer + 5000;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FleetVehicleListProvider>(
        context,
        listen: false,
      ).fetchList(widget.vehiclesId);
    });
  }


  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    final number = int.tryParse(value.replaceAll(',', '')) ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedIndex != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Respond to Booking',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.bookingCode,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 22),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Wants It
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Text(
                          'CUSTOMER WANTS IT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.customerWantedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.reachByTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Customer's Offer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOMER\'S OFFER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${_formatCurrency(widget.customerOffer)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00A651),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fixed price — first owner to accept gets the trip.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Vehicle Title
                  const Text(
                    'VEHICLE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle List
                  Expanded(
                    child: Consumer<FleetVehicleListProvider>(
                      builder: (context, service, _) {
                        // Loading
                        if (service.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // Empty
                        if (service.listData.isEmpty) {
                          return const Center(
                            child: Text(
                              "No vehicles available",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // List
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: service.listData.length,
                          itemBuilder: (context, index) {
                            final vehicle = service.listData[index];
                            final isSelected = selectedIndex == index;

                            final plate = vehicle["vehicle_number"] ?? "N/A";

                            final type =
                                vehicle["vehicleType"] ??
                                    vehicle["type"] ??
                                    widget.vehiclesId;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                  isSelected
                                      ? const Color(0xFFE8F7F2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                    isSelected
                                        ? const Color(0xFF0D7A5F)
                                        : const Color(0xFFE0E5EF),
                                    width: isSelected ? 1.8 : 1.2,
                                  ),
                                  boxShadow:
                                  isSelected
                                      ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0D7A5F,
                                      ).withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color:
                                        isSelected
                                            ? const Color(
                                          0xFF0D7A5F,
                                        ).withOpacity(0.12)
                                            : const Color(0xFFF4F6F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.local_shipping_outlined,
                                        color:
                                        isSelected
                                            ? const Color(0xFF0D7A5F)
                                            : Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plate.toString().toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color:
                                              isSelected
                                                  ? const Color(0xFF0D7A5F)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            type.toString(),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF0D7A5F),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ========== ACCEPT + COUNTER SECTION (only after vehicle selected) ==========
                  if (hasSelection) ...[
                    const SizedBox(height: 8),

                    // Accept Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAccept(selectedVehicle!);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7CB9A8), // soft green like screenshot
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          '✓  Accept  ·  ₹${_formatCurrency(widget.customerOffer)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // OR COUNTER
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR COUNTER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // YOUR COUNTER PRICE
                    Text(
                      'YOUR COUNTER PRICE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Counter Input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00A651), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _counterController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  counterPrice = int.tryParse(value);
                                });
                              },
                            ),
                          ),
                          // Up/Down buttons (optional)
                          Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  final current = int.tryParse(_counterController.text) ?? 0;
                                  _counterController.text = (current + 1000).toString();
                                  setState(() => counterPrice = current + 1000);
                                },
                                child: const Icon(Icons.keyboard_arrow_up, size: 20),
                              ),
                              InkWell(
                                onTap: () {
                                  final current = int.tryParse(_counterController.text) ?? 0;
                                  if (current > 1000) {
                                    _counterController.text = (current - 1000).toString();
                                    setState(() => counterPrice = current - 1000);
                                  }
                                },
                                child: const Icon(Icons.keyboard_arrow_down, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Counter Offer Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: counterPrice == null || counterPrice! <= 0
                            ? null
                            : () {
                          widget.onCounterOffer(selectedVehicle!, counterPrice!);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7CB9A8),
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          counterPrice != null
                              ? '₹  Counter Offer  ·  ₹${_formatCurrency(counterPrice.toString())}'
                              : '₹  Counter Offer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}