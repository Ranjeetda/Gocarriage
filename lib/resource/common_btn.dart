
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'common_text.dart';

class CommonBtn extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Color borderColor;
  final Color bgColor;
  final double height;
  final double radius;
  final Color textColor;

  const CommonBtn(
      {super.key,
      required this.text,
      this.onPressed,
      this.borderColor = Colors.red,
      this.radius = 10.0,
      this.textColor = Colors.white,
      this.bgColor = AppColors.primaryColor,
      this.height = 50});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: InkWell(
        splashColor: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // gradient: LinearGradient(
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            //   colors: [
            //     Colors.grey.shade200,
            //     Colors.green.shade400,
            //   ],
            // ),
            color: bgColor
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: CustomText(
                textKey: text,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class CommonBtnBorder extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Color borderColor;
  final Color bgColor;
  final double height;
  final double radius;
  final Color textColor;

  const CommonBtnBorder(
      {super.key,
      required this.text,
      this.onPressed,
      this.borderColor = Colors.red,
      this.radius = 10.0,
      this.textColor = Colors.white,
      this.bgColor = AppColors.primaryColor,
      this.height = 30});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: InkWell(
        splashColor: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: bgColor),
            // gradient: LinearGradient(
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            //   colors: [
            //     Colors.grey.shade200,
            //     Colors.green.shade400,
            //   ],
            // ),
            color: bgColor.withOpacity(0.7)
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0 , vertical: 2),
              child: CustomText(
                textKey: text,
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
