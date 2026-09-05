/// Model to hold data for each shipment card
class ShipmentData {
  final int id;
  String? pickupAddress;
  String? dropAddress;
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;
  String? mPincode1;
  String? mPincode2;
  int quantity;
  String weightUnit;
  bool isService;
  String mfromLable;
  String mtoLable;

  // Optional fields (you can later bind TextEditingControllers)
  String? material;
  String? weight;

  ShipmentData({
    required this.id,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.mPincode1,
    this.mPincode2,
    this.quantity = 1,
    this.weightUnit = 'KG',
    this.isService = false,
    this.mfromLable = '',
    this.mtoLable = '',
    this.material,
    this.weight,
  });
}