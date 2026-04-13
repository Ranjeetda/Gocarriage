
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/step_item.dart';

class StepProgressHeader extends StatelessWidget {

  final int currentStep;

  const StepProgressHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        StepItem(
          number: "1",
          title: "Booking Details \n Route & requirements",
          isActive: currentStep >= 1,
        ),

        Expanded(
          child: Divider(
            thickness: 2,
            color: currentStep >= 2 ? Colors.green : Colors.grey,
          ),
        ),

        StepItem(
          number: "2",
          title: "Negotiate \n Price negotiation",
          isActive: currentStep >= 2,
        ),

        Expanded(
          child: Divider(
            thickness: 2,
            color: currentStep >= 3 ? Colors.green : Colors.grey,
          ),
        ),

        StepItem(
          number: "3",
          title: "Done \n Booking confirmed",
          isActive: currentStep >= 3,
        ),
      ],
    );
  }
}
