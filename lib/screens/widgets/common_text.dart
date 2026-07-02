import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  final String textKey;
  final double? fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int maxLine;

  const CustomText({
    super.key,
    required this.textKey,
    this.fontSize,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLine = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      maxLines: maxLine,
      textKey.tr,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? 16,
        color: color ?? Colors.black,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );
  }
}


class GrayTextView extends StatelessWidget {
  final String textKey;
  final double? fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int maxLine;

  const GrayTextView({
    super.key,
    required this.textKey,
    this.fontSize,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLine = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 295, // Match your image width
        height: 45, // Match your image height
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light gray background
          borderRadius: BorderRadius.circular(22.5), // Half of height for pill shape
        ),
        child: Text(
          textKey,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class CustomTitleText extends StatelessWidget {
  final String textKey;
  final double? fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const CustomTitleText({
    super.key,
    required this.textKey,
    this.fontSize,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      textKey.tr, // Localization support
      style: GoogleFonts.poppins( // Apply Google Fonts
        fontSize: fontSize ?? 20,
        color: color ?? Colors.black,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );
  }
}

class CustomDynamicText extends StatelessWidget {
  final String textKey;
  final double? fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int maxLine;

  const CustomDynamicText({
    super.key,
    required this.textKey,
    this.fontSize,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLine = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      maxLines: maxLine,
      textKey.capitalizeFirst ?? '', // Capitalize the first letter
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins( // Apply Google Fonts
        fontSize: fontSize ?? 16,
        color: color ?? Colors.black,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );
  }
}
