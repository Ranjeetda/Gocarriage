class BlukBookingTripRequest {
  final String bookingMode;
  final List<Map<String, dynamic>> rows;

  BlukBookingTripRequest({
    required this.bookingMode,
    required this.rows,
  });

  Map<String, dynamic> toJson() => {
    'bookingMode': bookingMode,
    'rows': rows,
  };
}