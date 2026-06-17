class VehicleOption {
  final int id;
  final String name;

  VehicleOption({
    required this.id,
    required this.name,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      id: json['id'],
      name: json['name'],
    );
  }
}