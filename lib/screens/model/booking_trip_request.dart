
import 'package:gocarriage_universal/screens/model/special_requirements.dart';

import 'location_modal.dart';

class BookingTripRequest {
  final String bookingMode;
  final String tripType;
  final String vehicleType;
  final LocationModal fromLocation;
  final LocationModal toLocation;
  final String materialName;
  final double weight;

  final String weightUnit;
  final SpecialRequirements specialRequirements;
  final int customerId;

  BookingTripRequest({
    required this.bookingMode,
    required this.tripType,
    required this.vehicleType,
    required this.fromLocation,
    required this.toLocation,
    required this.materialName,
    required this.weight,
    required this.weightUnit,
    required this.specialRequirements,
    required this.customerId,
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
      "weightUnit": weightUnit,
      "specialRequirements": specialRequirements.toJson(),
      "customerId": customerId,
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
      weightUnit: json["weightUnit"] ?? "KG",
      specialRequirements: SpecialRequirements.fromJson(
        json["specialRequirements"] ?? {},
      ),
      customerId: json["customerId"],
    );
  }
}