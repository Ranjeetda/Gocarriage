import 'dart:io';

class PollutionCertificateModel {
  String? issuedState;
  File? file;
  DateTime? validFrom;
  DateTime? validTo;

  PollutionCertificateModel({
    this.issuedState,
    this.file,
    this.validFrom,
    this.validTo,
  });

  Map<String, dynamic> toJson() {
    return {
      "issuedState": issuedState,
      "filePath": file?.path,
      "validFrom": validFrom?.toIso8601String(),
      "validTo": validTo?.toIso8601String(),
    };
  }
}