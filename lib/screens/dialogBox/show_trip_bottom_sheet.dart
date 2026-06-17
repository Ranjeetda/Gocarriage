import 'package:flutter/material.dart';

void showTripBottomSheet(BuildContext context,String mStartLocation,String mEndLocation, String mVechile,String mFare,String mDistance) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),

            // Start & End Location with line loader
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icons & Line
                Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    Container(
                      height: 40,
                      width: 2,
                      color: Colors.grey.shade400,
                    ),
                    Icon(Icons.location_on, color: Colors.red),
                  ],
                ),

                const SizedBox(width: 12),

                // Location Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoRow("Start Location", mStartLocation),
                      const SizedBox(height: 18),
                      infoRow("End Location", mEndLocation),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            infoRow("Vehicle Type", mVechile),
            infoRow("Fare", "\$120"),
            infoRow("Distance", "450 km"),

            const SizedBox(height: 20),

            // Track Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Track action
                },
                child: const Text("Track"),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Reusable row widget
Widget infoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
