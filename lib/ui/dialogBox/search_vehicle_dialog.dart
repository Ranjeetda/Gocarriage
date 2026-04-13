import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';
import 'package:gocarriage_universal/ui/dialogBox/permission_dialog.dart';
import 'package:provider/provider.dart';

import '../../provider_service/operator_permission_list_provider.dart';
import '../../provider_service/oprator_search_registration_number.dart';
import '../../resource/Utils.dart';

class SearchVehicleDialog extends StatefulWidget {
  const SearchVehicleDialog({Key? key}) : super(key: key);

  @override
  State<SearchVehicleDialog> createState() => _SearchVehicleDialogState();
}

class _SearchVehicleDialogState extends State<SearchVehicleDialog> {
  final TextEditingController registrationController = TextEditingController();

  bool isLoading = false;
  bool isPermissionLoading = false;
  String vehicleId='';
  /// SEARCH VEHICLE
  Future<void> _searchRegistrationNumber() async {

    String registrationNumber = registrationController.text.trim();

    if (registrationNumber.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your vehicle number');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final provider = Provider.of<OpratorSearchRegistrationNumber>(
      context,
      listen: false,
    );

    await provider.fetchSearchRegistration(registrationNumber);

    setState(() {
      isLoading = false;
    });

    var responseData = provider.vehicleNumberData;

    if (responseData?['success'] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData?['message'])),
      );

    } else {

      String errorMessage =
          responseData?['message'] ?? 'Search failed. Please try again.';

      Utils.showErrorMessage(context, errorMessage);

    }
  }

  /// REQUEST PERMISSION
  Future<void> requestPermission() async {

    setState(() {
      isPermissionLoading = true;
    });

    final permissionProvider =
    Provider.of<OperatorPermissionListProvider>(context, listen: false);

    await permissionProvider.fetchVehicleTypes();

    final permissions = permissionProvider.permissionList;

    setState(() {
      isPermissionLoading = false;
    });

    /// Close search dialog
    Navigator.pop(context);

    /// Open permission bottom sheet
    showPermissionDialog(context, permissions,vehicleId);
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Search Vehicle",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const Divider(),
              const SizedBox(height: 20),

              /// SEARCH FIELD
              TextField(
                controller: registrationController,
                decoration: InputDecoration(
                  hintText: "DL01AB1234",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SEARCH BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(

                  icon: isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.search),

                  label: const Text(
                    "Search",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: isLoading ? null : _searchRegistrationNumber,
                ),
              ),

              const SizedBox(height: 24),

              /// VEHICLE DATA
              Consumer<OpratorSearchRegistrationNumber>(
                builder: (context, providerData, child) {

                  if (providerData.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (providerData.vehicleNumberData == null) {
                    return const SizedBox();
                  }

                  if (providerData.vehicleNumberData?['data'] == null) {
                    return const Text("No vehicle found");
                  }

                  var data = providerData.vehicleNumberData?['data'];
                  vehicleId=data['id'].toString();
                  return Column(
                    children: [

                      /// VEHICLE DETAILS BOX
                      Container(
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: const Color(0xffEEF2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Vehicle Details",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text('REGISTRATION : ${data['vehicle_number'] ?? ''}'),
                                  const SizedBox(height: 10),

                                  Text('OWNER : ${data['owner_name'] ?? ''}'),
                                  const SizedBox(height: 10),

                                  Text('EMAIL : ${data['owner_email'] ?? ''}'),
                                  const SizedBox(height: 10),

                                  Text('CITY : ${data['owner_city'] ?? ''}'),
                                  const SizedBox(height: 10),

                                  Text('PERMIT : ${data['permit_type'] ?? ''}'),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// REQUEST PERMISSION BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,

                        child: ElevatedButton(

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onPressed:
                          isPermissionLoading ? null : requestPermission,

                          child: isPermissionLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Request Permission",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PERMISSION BOTTOM SHEET
  void showPermissionDialog(BuildContext context, List permissions,String vehicleId) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {
        return PermissionDialog(permissions: permissions,vehicleId: vehicleId);
      },
    );
  }
}