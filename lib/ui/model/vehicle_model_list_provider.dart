class VehicleModelListProvider {
  final int id;
  final String model;
  final int payload;

  VehicleModelListProvider({
    required this.id,
    required this.model,
    required this.payload,
  });

  factory VehicleModelListProvider.fromJson(Map<String, dynamic> json) {
    return VehicleModelListProvider(
      id: json['id'],
      model: json['model'],
      payload: json['payload_capacity_kg'],
    );
  }
}