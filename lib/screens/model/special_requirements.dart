class SpecialRequirements {
  final bool container;
  final bool extraLength;
  final bool covered;
  final bool hydraulic;
  final bool extraLarge;

  SpecialRequirements({
    this.container = false,
    this.extraLength = false,
    this.covered = false,
    this.hydraulic = false,
    this.extraLarge = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "container": container,
      "extraLength": extraLength,
      "covered": covered,
      "hydraulic": hydraulic,
      "extraLarge": extraLarge,
    };
  }

  factory SpecialRequirements.fromJson(Map<String, dynamic> json) {
    return SpecialRequirements(
      container: json["container"] ?? false,
      extraLength: json["extraLength"] ?? false,
      covered: json["covered"] ?? false,
      hydraulic: json["hydraulic"] ?? false,
      extraLarge: json["extraLarge"] ?? false,
    );
  }
}