import 'package:flutter/material.dart';
import 'package:gocarriage_universal/screens/vehicleOwner/freightCalculatorScreen/vehicle_card.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/freight_vehicle_provider.dart';
import '../../../provider_service/vehicle_class_provider.dart';
import '../../../resource/app_colors.dart';

class FreightCalculatorScreen extends StatefulWidget {
  const FreightCalculatorScreen({super.key});

  @override
  State<FreightCalculatorScreen> createState() => _FreightCalculatorScreenState();
}

class _FreightCalculatorScreenState extends State<FreightCalculatorScreen> {
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FreightVehicleProvider>(context, listen: false)
          .fetchFreightVehicleList();
      Provider.of<VehicleClassProvider>(context, listen: false).fetchClasses();
    });

    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredList(
      List vehicleList,
      String? selectedClass,
      ) {
    return vehicleList.where((item) {
      final model = (item['model_name'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      final category = (item['v_cat'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          model.contains(_searchQuery) ||
          brand.contains(_searchQuery) ||
          category.contains(_searchQuery);

      final matchesClass = selectedClass == null ||
          selectedClass.isEmpty ||
          category == selectedClass.toLowerCase();

      return matchesSearch && matchesClass;
    }).cast<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vehicle Freight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // SEARCH
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by model or vehicle type...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => searchController.clear(),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // VEHICLE CLASS DROPDOWN
              Consumer<VehicleClassProvider>(
                builder: (context, classProvider, _) {
                  final String? safeValue = classProvider.classes
                      .any((e) => e.vCat == classProvider.selectedClass)
                      ? classProvider.selectedClass
                      : null;

                  return DropdownButtonFormField<String>(
                    value: safeValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Class',
                      hintText: 'Select Vehicle Class',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.8,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.directions_car_outlined,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    selectedItemBuilder: (context) {
                      return [
                        const Text(
                          'All Classes',
                          overflow: TextOverflow.ellipsis,
                        ),
                        ...classProvider.classes.map((item) {
                          return Text(
                            item.vCat ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }),
                      ];
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classProvider.classes.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.vCat,
                          child: Text(
                            item.vCat ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 15),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      classProvider.setSelectedClass(value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // VEHICLE LIST
              Consumer2<FreightVehicleProvider, VehicleClassProvider>(
                builder: (context, freightProvider, classProvider, _) {
                  if (freightProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final filteredList = _getFilteredList(
                    freightProvider.vehicleList,
                    classProvider.selectedClass,
                  );

                  if (filteredList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          "No vehicles found",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      return VehicleCard(
                        item: item,
                        model: item['model_name']?.toString() ?? '—',
                        brand: item['brand']?.toString() ?? '—',
                        emi: item['emi_per_day']?.toString() ?? '0',
                        baseFixed: item['base_fixed_per_day']?.toString() ??
                            item['emi_per_day']?.toString() ??
                            '0',
                        perKm: item['base_per_km']?.toString() ?? '0',
                        isDefault: item['is_customized'] != true,
                        category: item['v_cat']?.toString(),
                        basePerTon: item['base_per_ton']?.toString(),
                        baseFlat: item['base_flat_per_trip']?.toString(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}