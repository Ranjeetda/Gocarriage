import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../../provider_service/owner_reqest_provider.dart';
import '../../../provider_service/owner_request_approve_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';

class VehicleRequestScreen extends StatefulWidget {
  const VehicleRequestScreen({super.key});

  @override
  State<VehicleRequestScreen> createState() => _VehicleRequestScreenState();
}

class _VehicleRequestScreenState extends State<VehicleRequestScreen> {

  /// store selected permission ids per request
  Map<int, Set<int>> selectedPermissions = {};

  bool isLoading = false;

  /// permission chip
  Widget permissionChip(
      int requestId,
      int permissionId,
      String permission, {
        bool enabled = true,
      }) {

    selectedPermissions.putIfAbsent(requestId, () => {});

    bool selected =
    selectedPermissions[requestId]!.contains(permissionId);

    return FilterChip(
      label: Text(
        permission,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),

      selected: selected,

      selectedColor: AppColors.primaryColor.withOpacity(.15),
      checkmarkColor: AppColors.primaryColor,

      backgroundColor: Colors.grey.shade200,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? AppColors.primaryColor
              : Colors.grey.shade400,
        ),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      onSelected: enabled
          ? (value) {
        setState(() {

          if (value) {
            selectedPermissions[requestId]!.add(permissionId);
          } else {
            selectedPermissions[requestId]!.remove(permissionId);
          }

        });
      }
          : null,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final provider =
      Provider.of<OwnerReqestProvider>(context, listen: false);

      await provider.fetchList();

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade200,

      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Vehicle Request',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ),

      body: Consumer<OwnerReqestProvider>(
        builder: (context, provider, _) {

          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (provider.listData.isEmpty) {
            return const Center(
                child: Text('No vehicle request available'));
          }

          return ListView.builder(
            itemCount: provider.listData.length,
            itemBuilder: (context, index) {

              final data = provider.listData[index];

              return cardView(data);
            },
          );
        },
      ),
    );
  }

  /// CARD UI
  Widget cardView(dynamic data) {

    final fleet = data["Fleet"];
    final operator = data["Operator"];
    final permissions = data["requested_permissions"];

    bool isApproved = data["status"] == "approved";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(12),

      child: Container(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      "${fleet["vehicle_number"]} - ${fleet["color"]}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      fleet["permit_type"] ?? "",
                      style: const TextStyle(
                          color: Colors.grey),
                    ),
                  ],
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6),

                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.shade100
                        : Colors.amber.shade100,

                    borderRadius:
                    BorderRadius.circular(20),
                  ),

                  child: Text(
                    data["status"].toUpperCase(),

                    style: TextStyle(
                      color: isApproved
                          ? Colors.green
                          : Colors.orange,

                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// OPERATOR INFO
            Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Operator",
                        style: TextStyle(
                            color: Colors.grey),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        operator["ownerName"] ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      Text(
                        operator["email"] ?? "",
                        style: const TextStyle(
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "City",
                        style: TextStyle(
                            color: Colors.grey),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        (operator["city"] == null || operator["city"].toString().isEmpty)
                            ? "N/A"
                            : operator["city"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 40),

            const Text(
              "Select Permissions to Approve",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// PERMISSION CHIPS
            Wrap(
              spacing: 14,
              runSpacing: 14,

              children: permissions
                  .map<Widget>((perm) {

                int id = perm["id"];
                String name = perm["name"];

                return permissionChip(
                  data["id"],
                  id,
                  name,
                  enabled: !isApproved,
                );

              }).toList(),
            ),

            const SizedBox(height: 30),

            /// BUTTONS
            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,

              children: [

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),

                  onPressed: isApproved
                      ? null
                      : () {

                    _acceptRequest(
                      data["id"].toString(),
                      "rejected",
                      "",
                    );

                  },

                  icon: const Icon(Icons.close),

                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Reject",
                    style: TextStyle(
                        color: Colors.white),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),

                  onPressed: isApproved
                      ? null
                      : () {

                    List<int> ids =
                        selectedPermissions[data["id"]]
                            ?.toList() ??
                            [];

                    print({
                      "request_id": data["id"],
                      "permissions": ids
                    });

                    _acceptRequest(
                      data["id"].toString(),
                      "approved",
                      ids.join(","),
                    );

                  },

                  icon: const Icon(Icons.check),

                  label:

                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Approve",
                    style: TextStyle(
                        color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// API CALL
  Future<void> _acceptRequest(
      String mRequestId,
      String mStatus,
      String approvedPermissionIds) async {

    setState(() {
      isLoading = true;
    });

    http.Response response =
    await Provider.of<OwnerRequestApproveProvider>(
      context,
      listen: false,
    ).acceptRequest(
      mRequestId,
      mStatus,
      approvedPermissionIds,
    );

    var responseData = json.decode(response.body);

    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
            content: Text(responseData['message'])),
      );

    } else {

      String errorMessage =
          responseData['message'] ??
              'Request failed';

      Utils.showErrorMessage(context, errorMessage);
    }
  }
}