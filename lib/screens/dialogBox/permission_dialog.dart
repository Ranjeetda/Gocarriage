import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../provider_service/operator_vehicle_post_request_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';

class PermissionDialog extends StatefulWidget {
  final List permissions;
  final String vehicleId;

  const PermissionDialog({
    super.key,
    required this.permissions,
    required this.vehicleId,
  });

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  List selectedPermissions = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Operator Permissions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              /// Close Button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Permission List
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: widget.permissions.length,
              itemBuilder: (context, index) {
                final permission = widget.permissions[index];

                return CheckboxListTile(
                  value: selectedPermissions.contains(permission['id']),
                  title: Text(permission['name']),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedPermissions.add(permission['id']);
                      } else {
                        selectedPermissions.remove(permission['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// Submit Button
          SizedBox(
            width: double.infinity,
            child:
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondarycolor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        print(selectedPermissions);
                        _postVehicleRequest(
                          widget.vehicleId,
                          selectedPermissions,
                        );
                      },
                      child: const Text("Submit",style: TextStyle(color: Colors.white),),
                    ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _postVehicleRequest(
    String vehicleId,
    List requestedPermissionIds,
  ) async {
    setState(() {
      isLoading = true;
    });

    http.Response response =
        await Provider.of<OperatorVehiclePostRequestProvider>(
          context,
          listen: false,
        ).postVehicleRequest(vehicleId, requestedPermissionIds);
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
      String errorMessage =
          responseData['message'] ??
          'Permission request in failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }
}
