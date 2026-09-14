import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaterialDetailsForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;

  const MaterialDetailsForm({
    super.key,
    this.onChanged,
  });

  @override
  State<MaterialDetailsForm> createState() => _MaterialDetailsFormState();
}

class _MaterialDetailsFormState extends State<MaterialDetailsForm> {
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedUnit = "KG";

  /// Multiple selection map
  final Map<String, bool> _selectedRequirements = {
    "container": false,
    "extraLength": false,
    "covered": false,
    "hydraulic": false,
    "extraLarge": false,
  };

  final List<Map<String, dynamic>> _requirements = [
    {
      "title": "Container",
      "key": "container",
      "icon": Icons.local_shipping_outlined,
    },
    {
      "title": "Extra Length",
      "key": "extraLength",
      "icon": Icons.airport_shuttle_outlined,
    },
    {
      "title": "Covered",
      "key": "covered",
      "icon": Icons.security_outlined,
    },
    {
      "title": "Hydraulic",
      "key": "hydraulic",
      "icon": Icons.precision_manufacturing_outlined,
    },
    {
      "title": "Extra Large",
      "key": "extraLarge",
      "icon": Icons.fire_truck_outlined,
    },
  ];

  void _notifyParent() {
    widget.onChanged?.call({
      "material_name": _materialController.text.trim(),
      "weight": _weightController.text.trim(),
      "unit": _selectedUnit,
      "specialRequirements": Map<String, bool>.from(_selectedRequirements),
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void dispose() {
    _materialController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Material Name + Weight
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Material Name"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _materialController,
                      decoration: _inputDecoration().copyWith(
                        hintText: "e.g. Cement, Furniture",
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Weight"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDecoration().copyWith(
                        hintText: "Weight",
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "KG",
                                  child: Text("KG"),
                                ),
                                DropdownMenuItem(
                                  value: "TON",
                                  child: Text("TON"),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUnit = value);
                                  _notifyParent();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        /// Special Requirements
        const Text(
          "Special Requirements",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A237E),
          ),
        ),

        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _requirements.map((item) {
              final String key = item["key"];
              final bool isSelected = _selectedRequirements[key] ?? false;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRequirements[key] = !isSelected;
                    });
                    _notifyParent();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item["icon"],
                          size: 28,
                          color: isSelected
                              ? const Color(0xFFE65100)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item["title"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFE65100)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Label
  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A237E),
        ),
        children: const [
          TextSpan(
            text: " *",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Input Decoration
  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF1565C0),
          width: 1.5,
        ),
      ),
    );
  }
}