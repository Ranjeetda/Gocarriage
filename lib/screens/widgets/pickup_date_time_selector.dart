import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickupDateTimeSelector extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<TimeOfDay>? onTimeChanged;
  final int minHoursFromNow;

  const PickupDateTimeSelector({
    super.key,
    this.initialDate,
    this.initialTime,
    this.onDateChanged,
    this.onTimeChanged,
    this.minHoursFromNow = 3,
  });

  @override
  State<PickupDateTimeSelector> createState() => _PickupDateTimeSelectorState();
}

class _PickupDateTimeSelectorState extends State<PickupDateTimeSelector> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
  }

  DateTime get _minDateTime =>
      DateTime.now().add(Duration(hours: widget.minHoursFromNow));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = now.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16A34A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;

        // Reset time if it becomes invalid
        if (_selectedTime != null) {
          final candidate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          if (candidate.isBefore(_minDateTime)) {
            _selectedTime = null;
          }
        }
      });

      // Return date separately
      widget.onDateChanged?.call(picked);
    }
  }

  Future<void> _pickTime() async {
    if (_selectedDate == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16A34A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final candidate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        picked.hour,
        picked.minute,
      );

      if (candidate.isBefore(_minDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled pickup must be at least ${widget.minHoursFromNow} hours from now.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _selectedTime = picked);

      // Return time separately
      widget.onTimeChanged?.call(picked);
    }
  }

  String get _dateText {
    if (_selectedDate == null) return 'dd/mm/yyyy';
    return DateFormat('dd/MM/yyyy').format(_selectedDate!);
  }

  String get _timeText {
    if (_selectedDate == null) return 'Pick a date first';
    if (_selectedTime == null) return 'Select time';
    return _selectedTime!.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeEnabled = _selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFF334155)),
                  const SizedBox(width: 6),
                  const Text(
                    'Pickup Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: Color(0xFF334155)),
                  const SizedBox(width: 6),
                  const Text(
                    'Pickup Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Fields
        Row(
          children: [
            // Date
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateText,
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedDate == null
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Time
            Expanded(
              child: GestureDetector(
                onTap: isTimeEnabled ? _pickTime : null,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isTimeEnabled
                        ? Colors.white
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _timeText,
                          style: TextStyle(
                            fontSize: 15,
                            color: !isTimeEnabled
                                ? const Color(0xFFCBD5E1)
                                : _selectedTime == null
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isTimeEnabled
                            ? const Color(0xFF64748B)
                            : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'Scheduled pickup must be at least 3 hours from now.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}