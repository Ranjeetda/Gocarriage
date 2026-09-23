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

    bool selected = selectedPermissions[requestId]!.contains(permissionId);

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
          color: selected ? AppColors.primaryColor : Colors.grey.shade400,
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<OwnerReqestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.listData.isEmpty) {
            return const Center(child: Text('No vehicle request available'));
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

  /// CARD UI – matches the provided screenshot for rejected / pending / approved
  Widget cardView(dynamic data) {
    final fleet = data["Fleet"] ?? {};
    final operator = data["Operator"] ?? {};
    final permissions = data["requested_permissions"] ?? [];
    final String status = (data["status"] ?? "").toString().toLowerCase();
    final bool isApproved = status == "approved";
    final bool isRejected = status == "rejected";

    // Format createdAt → "10 Jul 2026"
    String requestedOn = "";
    if (data["createdAt"] != null) {
      try {
        final dt = DateTime.parse(data["createdAt"]).toLocal();
        const months = [
          "Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ];
        requestedOn = "${dt.day} ${months[dt.month - 1]} ${dt.year}";
      } catch (_) {
        requestedOn = data["createdAt"].toString();
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // truck icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFF00BFA5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // vehicle number + color · permit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fleet["vehicle_number"] ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${fleet["color"] ?? ""} · ${fleet["permit_type"] ?? ""}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // status badge
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 16),

            // ── REQUESTED ON ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    "Requested on $requestedOn",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── OPERATOR DETAILS ────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "OPERATOR DETAILS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Name
                Expanded(
                  child: _infoTile(
                    icon: Icons.person_outline,
                    label: "Name",
                    value: operator["ownerName"] ?? "—",
                  ),
                ),
                const SizedBox(width: 10),
                // Email
                Expanded(
                  child: _infoTile(
                    icon: Icons.email_outlined,
                    label: "Email",
                    value: (operator["email"] == null ||
                        operator["email"].toString().isEmpty)
                        ? "—"
                        : operator["email"],
                  ),
                ),
                const SizedBox(width: 10),
                // City
                Expanded(
                  child: _infoTile(
                    icon: Icons.location_city_outlined,
                    label: "City",
                    value: (operator["city"] == null ||
                        operator["city"].toString().isEmpty)
                        ? "N/A"
                        : operator["city"],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── PERMISSIONS / REJECTION MESSAGE ─────────────────────
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "PERMISSIONS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isRejected)
            // Red rejection banner (matches screenshot)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        color: Color(0xFFE53935), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Request was rejected",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "The operator was not granted access to this vehicle",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Permission chips (only for pending / approved)
              const Text(
                "Select Permissions to Approve",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: permissions.map<Widget>((perm) {
                  final int id = perm["id"];
                  final String name = perm["name"] ?? "";
                  return permissionChip(
                    data["id"],
                    id,
                    name,
                    enabled: !isApproved,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Approve / Reject buttons (only when not yet decided)
              if (!isApproved)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () => _acceptRequest(
                        data["id"].toString(),
                        "rejected",
                        "",
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Reject"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                        final List<int> ids =
                            selectedPermissions[data["id"]]?.toList() ??
                                [];
                        _acceptRequest(
                          data["id"].toString(),
                          "approved",
                          ids.join(","),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Approve"),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Status badge that matches the screenshot style
  Widget _statusBadge(String status) {
    Color bg;
    Color text;
    Color dot;

    switch (status) {
      case "approved":
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        dot = const Color(0xFF43A047);
        break;
      case "rejected":
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        dot = const Color(0xFFE53935);
        break;
      default: // pending / requested
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF57C00);
        dot = const Color(0xFFFB8C00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.isNotEmpty
                ? status[0].toUpperCase() + status.substring(1)
                : "Pending",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  /// Small info tile used in Operator Details row
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// API CALL
  Future<void> _acceptRequest(
      String mRequestId,
      String mStatus,
      String approvedPermissionIds,
      ) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );

      // Refresh list after approve/reject
      final provider =
      Provider.of<OwnerReqestProvider>(context, listen: false);
      await provider.fetchList();
    } else {
      String errorMessage =
          responseData['message'] ?? 'Request failed';
      Utils.showErrorMessage(context, errorMessage);
    }
  }
}