class FreightCalculator {
  static double calculate({
    required double distance,
    required double mileage,
    required double dieselPrice,
    required double driverCost,
    required double tollCost,
    required double maintenancePerKm,
  }) {
    double fuelCost = (distance / mileage) * dieselPrice;
    double maintenanceCost = distance * maintenancePerKm;

    return fuelCost +
        maintenanceCost +
        driverCost +
        tollCost;
  }
}