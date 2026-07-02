
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StepItem extends StatelessWidget {

  final String number;
  final String title;
  final bool isActive;

  const StepItem({
    super.key,
    required this.number,
    required this.title,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        CircleAvatar(
          radius: 18,
          backgroundColor:
          isActive ? Colors.green : Colors.grey.shade300,
          child: Text(
            number,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: 90,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        )
      ],
    );
  }
}
