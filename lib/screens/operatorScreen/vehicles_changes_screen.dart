import 'package:flutter/material.dart';

import '../../resource/app_colors.dart';

class VehiclesChangesScreen extends StatefulWidget {
  const VehiclesChangesScreen({Key? key}) : super(key: key);

  @override
  State<VehiclesChangesScreen> createState() => _VehiclesChangesScreenState();
}

class _VehiclesChangesScreenState extends State<VehiclesChangesScreen> {
  /// MULTI SELECTION
  Set<int> selectedVehicles = {};

  /// SEARCH CONTROLLER
  TextEditingController searchController = TextEditingController();

  /// ORIGINAL VEHICLE LIST
  List vehicles = [
    {"name": "Tata 407", "number": "DL01AB1234"},
    {"name": "Eicher Pro 2049", "number": "DL02CD5678"},
    {"name": "Tata 709", "number": "HR26EF9012"},
    {"name": "Tata Ace", "number": "UP14GH3456"},
  ];

  /// FILTERED LIST
  List filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    filteredVehicles = vehicles;
  }

  /// SEARCH FUNCTION
  void filterVehicles(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredVehicles = vehicles;
      });
      return;
    }

    setState(() {
      filteredVehicles =
          vehicles.where((vehicle) {
            final name = vehicle['name'].toLowerCase();
            final number = vehicle['number'].toLowerCase();
            final search = query.toLowerCase();

            return name.contains(search) || number.contains(search);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F8),

      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          children: [
            const SizedBox(height: 10),

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  filterVehicles(value);
                },
                decoration: InputDecoration(
                  hintText: "Search by vehicle name or number...",
                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      filterVehicles("");
                    },
                  ),

                  filled: true,
                  fillColor: const Color(0xffF1F3F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// SELECTED INFO BAR
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xffE5F4EC),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    selectedVehicles.isNotEmpty
                        ? "${selectedVehicles.length} vehicle selected"
                        : "Select vehicle",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// VEHICLE LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredVehicles.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedVehicles.contains(index);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedVehicles.contains(index)) {
                          selectedVehicles.remove(index);
                        } else {
                          selectedVehicles.add(index);
                        }
                      });
                    },

                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),

                      child: Row(
                        children: [
                          /// VEHICLE ICON
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xffF1F3F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              size: 32,
                            ),
                          ),

                          const SizedBox(width: 14),

                          /// DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                /// NAME + STATUS
                                Row(
                                  children: [
                                    Text(
                                      filteredVehicles[index]['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Available",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// VEHICLE NUMBER
                                Text(
                                  filteredVehicles[index]['number'],
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                /// PHONE + RATING
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 6),
                                    Text("+91 98765 00001"),

                                    SizedBox(width: 16),

                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 4),
                                    Text("4.8"),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// LOCATION + PRICE
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text("Delhi - Karol Bagh"),

                                    SizedBox(width: 14),

                                    Text("₹18/km"),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                const Text("4500 kg"),
                              ],
                            ),
                          ),

                          /// SELECTION BOX
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.blue,
                                    )
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondarycolor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {

              },
              child: const Text(
                "Vehicle change",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
