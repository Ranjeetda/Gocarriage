import 'package:flutter/material.dart';

class RideActionButtons extends StatefulWidget {
  final bool isAccepted;
  final Map<String, dynamic> ride;
  final Future<void> Function(String status, String bookingId) onAction;

  const RideActionButtons({
    super.key,
    required this.isAccepted,
    required this.ride,
    required this.onAction,
  });

  @override
  State<RideActionButtons> createState() => _RideActionButtonsState();
}

class _RideActionButtonsState extends State<RideActionButtons> {
  String? _loadingAction; // "Accept" or "Decline"

  Future<void> _handleAction(String action) async {
    setState(() {
      _loadingAction = action;
    });

    try {
      await widget.onAction(action, widget.ride['bookingId']);
    } finally {
      if (mounted) {
        setState(() {
          _loadingAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled =
        !widget.isAccepted || _loadingAction != null;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isAccepted
                    ? Colors.red
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: isDisabled
                  ? null
                  : () => _handleAction("Decline"),
              child: _loadingAction == "Decline"
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Decline",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isAccepted
                    ? Colors.green
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: isDisabled
                  ? null
                  : () => _handleAction("Accept"),
              child: _loadingAction == "Accept"
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Accept",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
