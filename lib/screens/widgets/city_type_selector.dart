import 'package:flutter/material.dart';

class CityTypeSelector extends StatefulWidget {
  final bool isInCity;
  final ValueChanged<bool>? onChanged;
  final bool isServiceAvailable;

  const CityTypeSelector({
    super.key,
    this.isInCity = true,
    this.onChanged,
    this.isServiceAvailable = true,
  });

  @override
  State<CityTypeSelector> createState() => _CityTypeSelectorState();
}

class _CityTypeSelectorState extends State<CityTypeSelector> {
  late bool _isInCity;

  @override
  void initState() {
    super.initState();
    _isInCity = widget.isInCity;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Segmented Control
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // In City
              GestureDetector(
                onTap: () {
                  setState(() => _isInCity = true);
                  widget.onChanged?.call(true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isInCity ? const Color(0xFFE67E22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apartment, // or Icons.location_city
                        size: 18,
                        color: _isInCity ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'In City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isInCity ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Out City
              GestureDetector(
                onTap: () {
                  setState(() => _isInCity = false);
                  widget.onChanged?.call(false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isInCity ? const Color(0xFFE67E22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alt_route, // or Icons.route
                        size: 18,
                        color: !_isInCity ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Out City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !_isInCity ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Service Available
        if (widget.isServiceAvailable)
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xFF2ECC71),
              ),
              const SizedBox(width: 6),
              Text(
                'Service available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
      ],
    );
  }
}