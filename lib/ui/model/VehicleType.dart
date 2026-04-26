import 'package:gocarriage_universal/ui/model/vehicle_option.dart';

class VehicleType {
  final String group;
  final List<VehicleOption> options;

  VehicleType({
    required this.group,
    required this.options,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      group: json['group'],
      options: (json['options'] as List)
          .map((e) => VehicleOption.fromJson(e))
          .toList(),
    );
  }
}