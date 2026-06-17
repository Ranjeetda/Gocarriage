// Model class (recommended)
class RecentLocation {
  final String location;
  final String? postalCode;
  final double? lat;
  final double? lng;

  RecentLocation({
    required this.location,
    this.postalCode,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {
    'location': location,
    'postalCode': postalCode,
    'lat': lat,
    'lng': lng,
  };

  factory RecentLocation.fromJson(Map<String, dynamic> json) => RecentLocation(
    location: json['location'] ?? '',
    postalCode: json['postalCode'],
    lat: json['lat']?.toDouble(),
    lng: json['lng']?.toDouble(),
  );
}