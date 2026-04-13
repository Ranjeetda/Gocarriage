import 'package:flutter/material.dart';

class ClickableDiagonalPill extends StatefulWidget {
  final List<String> options;
  final ValueChanged<int>? onChanged;
  final int initialIndex;

  const ClickableDiagonalPill({
    super.key,
    required this.options,
    this.onChanged,
    this.initialIndex = 0,
  });

  @override
  State<ClickableDiagonalPill> createState() => _ClickableDiagonalPillState();
}

class _ClickableDiagonalPillState extends State<ClickableDiagonalPill> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _changeTab(int index) {
    setState(() => selectedIndex = index);
    widget.onChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final double height = 40;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          color: Colors.white,
          child: Stack(
            children: [
              // Left background
              Positioned.fill(
                child: ClipPath(
                  clipper: _LeftSlantedClipper(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: selectedIndex == 0
                        ? const Color(0xFF1E88E5) // Blue
                        : Colors.white,
                  ),
                ),
              ),

              // Right background
              Positioned.fill(
                child: ClipPath(
                  clipper: _RightSlantedClipper(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: selectedIndex == 1
                        ? const Color(0xFF2DAF9F) // Teal/Green
                        : Colors.white,
                  ),
                ),
              ),

              // Text
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeTab(0),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: selectedIndex == 0
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          child: Text(widget.options[0]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeTab(1),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: selectedIndex == 1
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          child: Text(widget.options[1]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Left diagonal shape
class _LeftSlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    final double topX = w * 0.62;
    final double bottomX = w * 0.52;

    path.moveTo(0, 0);
    path.lineTo(topX, 0);
    path.lineTo(bottomX, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Right diagonal shape
class _RightSlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    final double topX = w * 0.62;
    final double bottomX = w * 0.52;

    path.moveTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(bottomX, h);
    path.lineTo(topX, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
