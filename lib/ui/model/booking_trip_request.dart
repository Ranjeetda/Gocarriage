import 'location_modal.dart';

class BookingTripRequest {
  final String bookingMode;
  final String tripType;
  final String vehicleType;
  final LocationModal fromLocation;
  final LocationModal toLocation;
  final String materialName;
  final double weight;

  BookingTripRequest({
    required this.bookingMode,
    required this.tripType,
    required this.vehicleType,
    required this.fromLocation,
    required this.toLocation,
    required this.materialName,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      "bookingMode": bookingMode,
      "tripType": tripType,
      "vehicleType": vehicleType,
      "fromLocation": fromLocation.toJson(),
      "toLocation": toLocation.toJson(),
      "materialName": materialName,
      "weight": weight,
    };
  }

  factory BookingTripRequest.fromJson(Map<String, dynamic> json) {
    return BookingTripRequest(
      bookingMode: json["bookingMode"],
      tripType: json["tripType"],
      vehicleType: json["vehicleType"],
      fromLocation: LocationModal.fromJson(json["fromLocation"]),
      toLocation: LocationModal.fromJson(json["toLocation"]),
      materialName: json["materialName"],
      weight: (json["weight"] as num).toDouble(),
    );
  }
}
