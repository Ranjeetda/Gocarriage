
class VehicleClass {
  final String vCat;
  final int count;

  VehicleClass({required this.vCat, required this.count});

  factory VehicleClass.fromJson(Map<String, dynamic> json) {
    return VehicleClass(
      vCat: json['v_cat'],
      count: json['count'],
    );
  }
}