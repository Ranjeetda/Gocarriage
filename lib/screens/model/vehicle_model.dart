class VehicleModel {
  final String name;
  final String time;
  final String capacity;
  final String size;
  final int price;
  final bool recommended;

  VehicleModel({
    required this.name,
    required this.time,
    required this.capacity,
    required this.size,
    required this.price,
    this.recommended = false,
  });
}
