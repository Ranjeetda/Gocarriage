class VehicleType {
  final int id;
  final String name;

  VehicleType({
    required this.id,
    required this.name,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      name: json['name'],
    );
  }
}