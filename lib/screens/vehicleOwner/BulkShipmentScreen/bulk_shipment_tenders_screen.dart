
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/screens/vehicleOwner/BulkShipmentScreen/tender_card.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/tender_booking_service.dart';
import '../../../resource/app_colors.dart';



class BulkShipmentTendersScreen extends StatefulWidget {
  const BulkShipmentTendersScreen({super.key});

  @override
  State<BulkShipmentTendersScreen> createState() => _BulkShipmentTendersScreenState();
}

class _BulkShipmentTendersScreenState extends State<BulkShipmentTendersScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TenderBookingService>(context, listen: false).fetchList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bulk Shipment Tenders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<TenderBookingService>(
            builder: (context, service, _) {
              final count = service.listData.length;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$count Open',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<TenderBookingService>(
            builder: (context, service, _) {
              if (service.isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return IconButton(
                onPressed: () {
                  Provider.of<TenderBookingService>(context, listen: false)
                      .fetchList();
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              );
            },
          ),
        ],
      ),
      body: Consumer<TenderBookingService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.listData.isEmpty) {
            return const Center(
              child: Text(
                'No tenders available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: service.listData.length,
            itemBuilder: (context, index) {
              return TenderCard(item: service.listData[index]);
            },
          );
        },
      ),
    );
  }
}

