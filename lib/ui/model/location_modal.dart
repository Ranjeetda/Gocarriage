class LocationModal {
  final String address;
  final double lat;
  final double lng;

  LocationModal({
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "lat": lat,
      "lng": lng,
    };
  }

  factory LocationModal.fromJson(Map<String, dynamic> json) {
    return LocationModal(
      address: json["address"],
      lat: (json["lat"] as num).toDouble(),
      lng: (json["lng"] as num).toDouble(),
    );
  }
}
