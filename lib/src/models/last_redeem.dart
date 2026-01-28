class LastRedeem {
  final String name;
  final String nik;

  final String serialNumber;
  final String programType;
  final String cardCategory;
  final String cardType;

  final String redeemDate;
  final String redeemType;
  final int quotaUsed;
  final int remainingQuota;
  final String station;
  final String operatorName;
  final String status;

  LastRedeem({
    required this.name,
    required this.nik,
    required this.serialNumber,
    required this.programType,
    required this.cardCategory,
    required this.cardType,
    required this.redeemDate,
    required this.redeemType,
    required this.quotaUsed,
    required this.remainingQuota,
    required this.station,
    required this.operatorName,
    required this.status,
  });

  factory LastRedeem.fromJson(Map<String, dynamic> json) {
    return LastRedeem(
      name: json['card']['member']['name'],
      nik: json['card']['member']['identityNumber'],

      serialNumber: json['card']['serialNumber'],
      programType: json['card']['programType'],
      cardCategory: json['card']['cardProduct']['category']['categoryName'],
      cardType: json['card']['cardProduct']['type']['typeName'],

      redeemDate: json['shiftDate'],
      redeemType: json['redeemType'],
      quotaUsed: json['quotaUsed'],
      remainingQuota: json['remainingQuota'],
      station: json['station']['stationName'],
      operatorName: json['operator']['fullName'],
      status: json['status'],
    );
  }
}
