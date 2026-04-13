import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/app_colors.dart';

class SpecialInstructionsDialog extends StatefulWidget {
  const SpecialInstructionsDialog({super.key});

  @override
  State<SpecialInstructionsDialog> createState() =>
      _SpecialInstructionsDialogState();
}

class _SpecialInstructionsDialogState
    extends State<SpecialInstructionsDialog> {
  TimeOfDay? noEntryFrom;
  TimeOfDay? noEntryTo;

  int loadingTime = 0;
  int unloadingTime = 0;

  final TextEditingController notesController = TextEditingController();

  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  Future<void> pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          noEntryFrom = picked;
        } else {
          noEntryTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // ✅ FIX
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFEC6A2E),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Special Instructions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Provide additional details for your booking",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),

            // ================= BODY =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("LOADING / UNLOADING TIME"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: hourDropdown(
                            label: "Loading Time (hrs)",
                            value: loadingTime,
                            onChanged: (v) =>
                                setState(() => loadingTime = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: hourDropdown(
                            label: "Unloading Time (hrs)",
                            value: unloadingTime,
                            onChanged: (v) =>
                                setState(() => unloadingTime = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    sectionTitle("NO-ENTRY AREA TIMING"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: timePickerField(
                            label: "No Entry From",
                            value: formatTime(noEntryFrom),
                            onTap: () => pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: timePickerField(
                            label: "No Entry To",
                            value: formatTime(noEntryTo),
                            onTap: () => pickTime(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    sectionTitle("ADDITIONAL NOTES"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Type any special instructions...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= FOOTER =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget timePickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value),
                const Icon(Icons.access_time, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget hourDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: value,
          items: List.generate(
            25,
                (index) => DropdownMenuItem(
              value: index,
              child: Text("$index hrs"),
            ),
          ),
          onChanged: (v) => onChanged(v ?? 0),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
