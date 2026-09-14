import 'package:flutter/material.dart';

enum ServiceMode { incity, outcity, rental, international }

class ServiceModeSelector extends StatefulWidget {
  const ServiceModeSelector({
    super.key,
    this.onChanged,
    this.selectedMode,
  });

  final ValueChanged<ServiceMode>? onChanged;
  final ServiceMode? selectedMode;

  @override
  State<ServiceModeSelector> createState() => _ServiceModeSelectorState();
}

class _ServiceModeSelectorState extends State<ServiceModeSelector> {
  ServiceMode? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMode;
  }

  @override
  void didUpdateWidget(covariant ServiceModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMode != oldWidget.selectedMode) {
      setState(() => _selected = widget.selectedMode);
    }
  }

  static const _blue = Color(0xFF2D5BE8);
  static const _navy = Color(0xFF16235F);
  static const _track = Color(0xFFF1F4FA);
  static const _idle = Color(0xFF5A6378);
  static const _border = Color(0xFFE0E5EF);

  void _select(ServiceMode m) {
    setState(() => _selected = m);
    widget.onChanged?.call(m);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _track,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _segment(ServiceMode.incity, 'Incity', Icons.location_city_rounded),
                const SizedBox(width: 4),
                _segment(ServiceMode.outcity, 'Outcity', Icons.alt_route_rounded),
                const SizedBox(width: 4),
                _segment(ServiceMode.rental, 'Rental', Icons.vpn_key_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _intlTab(),
      ],
    );
  }

  Widget _segment(ServiceMode mode, String label, IconData icon) {
    final active = _selected == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => _select(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
              BoxShadow(
                color: _blue.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? Colors.white : _idle,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _idle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intlTab() {
    final active = _selected == ServiceMode.international;

    return GestureDetector(
      onTap: () => _select(ServiceMode.international),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _navy : _border,
            width: 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_rounded,
                size: 16,
                color: active ? Colors.white : _idle,
              ),
              const SizedBox(width: 4),
              Text(
                'International',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _idle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}