import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/assign_driver_provider.dart';
import '../../../provider_service/search_driver_provider.dart';
import '../../../resource/Utils.dart';
import 'package:http/http.dart' as http;

import '../driver_list_screen/add_driver_screen.dart';

class SelectDriverDialog extends StatefulWidget {
  const SelectDriverDialog({super.key});

  @override
  State<SelectDriverDialog> createState() => _SelectDriverDialogState();
}

class _SelectDriverDialogState extends State<SelectDriverDialog> {
  String? selectedCab;
  bool isLoading = false;
  Map<String, dynamic>? searchedDriver;

  final TextEditingController _phoneController = TextEditingController();

  Future<void> _searchDriver(String phone) async {
    if (phone.length != 10) {
      Utils.showErrorMessage(context, "Mobile number must be 10 digits");
      return;
    }

    final provider =
    Provider.of<SearchDriverProvider>(context, listen: false);

    try {
      await provider.fetchDriver(phone);

      final responseData = provider.driverListData;

      if (responseData['success'] == true) {
        final driverData = responseData['data']['driver'];

        setState(() {
          searchedDriver = driverData;
          selectedCab =
          "${driverData['vehicleNumber']} - ${driverData['fullName']}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        Utils.showErrorMessage(
          context,
          responseData['message'] ?? "Driver not found",
        );
      }
    } catch (e) {
      Utils.showErrorMessage(context, "Something went wrong");
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Driver',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),

              /// 🔎 SEARCH BAR
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: Colors.grey.shade300),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          hintText:
                          'Enter 10 digit mobile number',
                          border: InputBorder.none,
                          counterText: "",
                        ),
                        onChanged: (value) {
                          if (value.length == 10) {
                            _searchDriver(value);
                          }
                        },
                      ),
                    ),

                    Consumer<SearchDriverProvider>(
                      builder: (context, provider, child) {
                        return provider.isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.search,
                            color: Colors.grey);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// 🔥 SHOW SEARCHED DRIVER (FROM API)
              if (searchedDriver != null)
                _buildCabTile(
                  plate: searchedDriver!['vehicleNumber'] ?? '',
                  driver: searchedDriver!['fullName'] ?? '',
                  isSelected: true,
                  onTap: () {},
                ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddDriverScreen()),
                  );
                },
                child: const Text('+ Register New Driver'),
              ),
              const SizedBox(height: 16),

              /// BUTTONS
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: searchedDriver == null
                        ? null
                        : () {
                      _assignDriver(searchedDriver!['id'].toString());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'CONFIRM',
                      style:
                      TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCabTile({
    required String plate,
    required String driver,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
        const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black12.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car,
                color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    plate,
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.bold),
                  ),
                  Text(
                    driver,
                    style:
                    const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color:
              isSelected ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriver(String? driverId) async {
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return;
    }
    setState(() {
      isLoading = true;
    });
    http.Response response = await Provider.of<AssignDriverProvider>(
      context,
      listen: false,
    ).assignDriver(driverId);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() {
        isLoading = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Assign Driver failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

}