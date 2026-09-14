import 'package:flutter/material.dart';

enum BookingMode { now, schedule }

class BookingModeSelector extends StatefulWidget {
  final BookingMode initialMode;
  final ValueChanged<BookingMode>? onChanged;

  const BookingModeSelector({
    super.key,
    this.initialMode = BookingMode.now,
    this.onChanged,
  });

  @override
  State<BookingModeSelector> createState() => _BookingModeSelectorState();
}

class _BookingModeSelectorState extends State<BookingModeSelector> {
  late BookingMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  void didUpdateWidget(covariant BookingModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != oldWidget.initialMode) {
      setState(() => _selectedMode = widget.initialMode);
    }
  }

  void _select(BookingMode mode) {
    if (_selectedMode == mode) return;
    setState(() => _selectedMode = mode);
    widget.onChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ModeButton(
                label: 'Now',
                icon: Icons.bolt_rounded,
                isSelected: _selectedMode == BookingMode.now,
                onTap: () => _select(BookingMode.now),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModeButton(
                label: 'Schedule',
                icon: Icons.access_time_rounded,
                isSelected: _selectedMode == BookingMode.schedule,
                onTap: () => _select(BookingMode.schedule),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [
              Color(0xFF22C55E),
              Color(0xFF16A34A),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: isSelected ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF22C55E).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}