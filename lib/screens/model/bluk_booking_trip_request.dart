class BlukBookingTripRequest {
  final String bookingMode;
  final List<Map<String, dynamic>> rows;
  final String? pickupDate;
  final String? pickupTime;

  BlukBookingTripRequest({
    required this.bookingMode,
    required this.rows,
    this.pickupDate,
    this.pickupTime,
  });

  Map<String, dynamic> toJson() => {
    'bookingMode': bookingMode,
    'rows': rows,
    if (pickupDate != null) 'pickupDate': pickupDate,
    if (pickupTime != null) 'pickupTime': pickupTime,
  };
}