class Place {
  final String placeId;
  final String placeName;
  final double latitude;
  final double longitude;


  Place({
    required this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['id'],
      placeName: json['title'],
      latitude: (json['location_latitude'] as num).toDouble(),
      longitude: (json['location_longitude'] as num).toDouble(),
    );
  }

  /// ✅ Add copyWith method to allow updating coordinates
  Place copyWith({
    String? placeId,
    String? placeName,
    double? latitude,
    double? longitude,
  }) {
    return Place(
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'Place(placeId: $placeId, placeName: $placeName ,  latitude: $latitude, longitude: $longitude)';
  }
}
