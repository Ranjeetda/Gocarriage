import 'package:gocarriage_universal/screens/model/location_modal.dart';
import 'package:gocarriage_universal/screens/model/special_requirements.dart';

class BookingTripRequest {
  final String bookingMode;
  final String tripType;
  final String vehicleType;
  final String serviceType;

  // Required
  final LocationModal fromLocation;
  final LocationModal toLocation;
  final SpecialRequirements specialRequirements;
  final int customerId;

  // Optional
  final String? vehicleTypeId;
  final String? pricingMode;
  final DateTime? pickupDate;
  final String? pickupTime;

  final String? materialName;
  final double? weight;
  final String? weightUnit;

  BookingTripRequest({
    required this.bookingMode,
    required this.tripType,
    required this.vehicleType,
    required this.serviceType,
    required this.fromLocation,
    required this.toLocation,
    required this.specialRequirements,
    required this.customerId,
    this.vehicleTypeId,
    this.pricingMode,
    this.pickupDate,
    this.pickupTime,
    this.materialName,
    this.weight,
    this.weightUnit,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "bookingMode": bookingMode,
      "tripType": tripType,
      "vehicleType": vehicleType,
      "service_type": serviceType,
      "fromLocation": fromLocation.toJson(),
      "toLocation": toLocation.toJson(),
      "specialRequirements": specialRequirements.toJson(),
      "customerId": customerId,
    };

    if (vehicleTypeId != null && vehicleTypeId!.isNotEmpty) {
      data["vehicle_type_id"] = vehicleTypeId;
    }

    if (pricingMode != null && pricingMode!.isNotEmpty) {
      data["pricingMode"] = pricingMode;
    }

    if (pickupDate != null) {
      data["pickupDate"] = pickupDate!.toUtc().toIso8601String();
    }

    if (pickupTime != null && pickupTime!.isNotEmpty) {
      data["pickupTime"] = pickupTime;
    }

    if (materialName != null && materialName!.isNotEmpty) {
      data["materialName"] = materialName;
    }

    if (weight != null) {
      data["weight"] = weight;
    }

    if (weightUnit != null && weightUnit!.isNotEmpty) {
      data["weightUnit"] = weightUnit;
    }

    return data;
  }

  factory BookingTripRequest.fromJson(Map<String, dynamic> json) {
    return BookingTripRequest(
      bookingMode: json["bookingMode"] ?? "",
      tripType: json["tripType"] ?? "",
      vehicleType: json["vehicleType"] ?? "",
      serviceType: json["service_type"] ?? "",
      vehicleTypeId: json["vehicle_type_id"]?.toString(),
      pricingMode: json["pricingMode"],
      pickupDate: json["pickupDate"] != null
          ? DateTime.parse(json["pickupDate"])
          : null,
      pickupTime: json["pickupTime"],
      fromLocation: LocationModal.fromJson(json["fromLocation"] ?? {}),
      toLocation: LocationModal.fromJson(json["toLocation"] ?? {}),
      materialName: json["materialName"],
      weight: json["weight"] != null
          ? (json["weight"] as num).toDouble()
          : null,
      weightUnit: json["weightUnit"],
      specialRequirements: SpecialRequirements.fromJson(
        json["specialRequirements"] ?? {},
      ),
      customerId: json["customerId"] ?? 0,
    );
  }
}