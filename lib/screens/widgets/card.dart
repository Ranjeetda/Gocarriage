
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Cards extends StatelessWidget {
  final Widget child;

  const Cards({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, // Pure White Background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ), // Optional light border
      ),
      child: child,
    );
  }
}